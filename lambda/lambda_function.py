import json
import boto3
import os

from langchain_community.chat_models import BedrockChat
from langchain.memory import ConversationBufferMemory
from langchain_core.prompts import PromptTemplate
from langchain.chains import ConversationalRetrievalChain
from langchain_community.embeddings import BedrockEmbeddings
from langchain_community.chat_message_histories import CassandraChatMessageHistory
from cassandra.cluster import Cluster
from opensearchpy import RequestsHttpConnection
from langchain_community.vectorstores import OpenSearchVectorSearch


def lambda_handler(event, context):
    session_id_missing = "session_id" not in event
    prompt_missing = "prompt" not in event
    bedrock_model_id_missing = "bedrock_model_id" not in event
    model_kwargs_missing = "model_kwargs" not in event
    metadata_missing = "metadata" not in event
    memory_window_missing = "memory_window" not in event
    if (session_id_missing or
            prompt_missing or
            bedrock_model_id_missing or
            model_kwargs_missing or
            metadata_missing or
            memory_window_missing):
        return {
            'statusCode': 400,
            'body': "Invalid input. Missing required fields."
        }
    
    prompt = event["prompt"]
    bedrock_model_id = event["bedrock_model_id"]
    model_kwargs = event["model_kwargs"]
    metadata = event["metadata"]
    memory_window = event["memory_window"]
    session_id = event["session_id"]

    if "temperature" in model_kwargs and (model_kwargs["temperature"] < 0 or model_kwargs["temperature"] > 1):
        return {
            'statusCode': 400,
            'body': "Invalid input. temperature value must be between 0 and 1."
        }
    if "top_p" in model_kwargs and (model_kwargs["top_p"] < 0 or model_kwargs["top_p"] > 1):
        return {
            'statusCode': 400,
            'body': "Invalid input. top_p value must be between 0 and 1."
        }

    # Check if top_k is between 0 and 1
    if "top_k" in model_kwargs and (model_kwargs["top_k"] < 0 or model_kwargs["top_k"] > 500):
        return {
            'statusCode': 400,
            'body': "Invalid input. top_k value must be between 0 and 500."
        }

    os_host = os.environ['aoss_host']
    if not os_host:
        return {
            'statusCode': 400,
            'body': "Invalid input. os_host is empty."
        }

    cassandra_hosts = os.environ['cassandra_hosts']
    if not cassandra_hosts:
        return {
            'statusCode': 400,
            'body': "Invalid input. cassandra_hosts is empty."
        }

    os_username = os.environ['os_username']
    if not os_username:
        return {
            'statusCode': 400,
            'body': "Invalid input. os_username is empty."
        }

    os_password = os.environ['os_password']
    if not os_password:
        return {
            'statusCode': 400,
            'body': "Invalid input. os_password is empty."
        }

    region = os.environ.get('AWS_REGION', 'us-east-1')  # Default to us-east-1 if AWS_REGION is not set

    # TODO implement
    conversation = init_conversationchain(session_id,
                                          region,
                                          bedrock_model_id,
                                          model_kwargs,
                                          metadata,
                                          memory_window,
                                          os_host,
                                          os_username,
                                          os_password,
                                          cassandra_hosts)
    response = conversation({"question": prompt})
    
    generated_text = response["answer"]
    doc_url = json.loads('[]')

    if len(response['source_documents']) != 0:
        for doc in response['source_documents']:
            doc_url.append(doc.metadata['source'])
    print(generated_text)
    print(doc_url)

    return {
        'statusCode': 200,
        'body': {"question": prompt.strip(), "answer": generated_text.strip(), "documents": doc_url}
    }


def init_conversationchain(session_id,
                           region,
                           bedrock_model_id,
                           model_kwargs,
                           metadata,
                           memory_window,
                           os_host,
                           os_username,
                           os_password,
                           cassandra_hosts) -> ConversationalRetrievalChain:
    bedrock_embedding_model_id = "amazon.titan-embed-text-v2:0"
    
    bedrock_client = boto3.client(service_name='bedrock-runtime', region_name=region)
    bedrock_embeddings = BedrockEmbeddings(model_id=bedrock_embedding_model_id, client=bedrock_client)

    new_db = OpenSearchVectorSearch(
        index_name="fsxnragvector-index",
        embedding_function=bedrock_embeddings,
        opensearch_url=f'{os_host}',
        use_ssl=True,
        verify_certs=True,
        connection_class=RequestsHttpConnection,
        http_auth=(os_username, os_password)
    )

    prompt_template = """Human: This is a friendly conversation between a human and an AI. 
    The AI is talkative and provides specific details from its context but limits it to 240 tokens.
    If the AI does not know the answer to a question, it truthfully says it 
    does not know.

    Assistant: OK, got it, I'll be a talkative truthful AI assistant.

    Human: Here are a few documents in <documents> tags:
    <documents>
    {context}
    </documents>
    Based on the above documents, provide a detailed answer for, {question} 
    Answer "don't know" if not present in the document. 

    Assistant:
    """

    prompt = PromptTemplate(
        template=prompt_template, input_variables=["question", "context"]
    )

    condense_qa_template = """{chat_history}
    Human:
    Given the previous conversation and a follow up question below, rephrase the follow up question
    to be a standalone question.

    Follow Up Question: {question}
    Standalone Question:

    Assistant:"""
    standalone_question_prompt = PromptTemplate.from_template(condense_qa_template)

    everyone_acl = 'S-1-1-0'
    if metadata == "NA":
        retriever = new_db.as_retriever(search_kwargs={"filter": [{"term": {"metadata.acl.allowed": everyone_acl}}]})
    else:
        # retriever = new_db.as_retriever(search_kwargs={"filter": [{"term": {"metadata.year": metadata}}]})
        retriever = new_db.as_retriever(
            search_kwargs={"filter": [{"terms": {"metadata.acl.allowed": [everyone_acl, metadata]}}]})

    llm = BedrockChat(
        model_id=bedrock_model_id,
        model_kwargs=model_kwargs,
        streaming=True
    )

    protocol_version = 5
    cluster = Cluster(
        [cp.strip() for cp in cassandra_hosts.split(",") if cp.strip()],
        protocol_version=protocol_version,
        connect_timeout=40
    )
    session = cluster.connect()

    keyspace = "sessionkeyspace"
    session.execute(f"""
        CREATE KEYSPACE IF NOT EXISTS {keyspace}
        WITH replication = {{ 'class': 'SimpleStrategy', 'replication_factor': '1' }}
    """)

    msg_history = CassandraChatMessageHistory(session_id=session_id,
                                              session=session,
                                              keyspace=keyspace)

    memory = ConversationBufferMemory(
        memory_key="chat_history",
        chat_memory=msg_history,
        return_messages=True,
        output_key="answer")

    conversation = ConversationalRetrievalChain.from_llm(
        llm=llm,
        retriever=retriever,
        condense_question_prompt=standalone_question_prompt,
        return_source_documents=True, 
        verbose=True,
        memory=memory,
        combine_docs_chain_kwargs={"prompt": prompt},
    )

    return conversation
