export {};

declare global {
    namespace NodeJS {
        interface ProcessEnv {
            PROFILE: string;
            REGION: string;
            OPEN_SEARCH_SERVERLESS_COLLECTION_NAME: string;
            OPEN_SEARCH_HOSTNAME: string;
            OPENSEARCH_USERNAME: string;
            OPENSEARCH_PASSWORD: string;
            BEDROCK_EMBEDDING_MODEL_ID: string;
            BEDROCK_EMBEDDING_MODEL_OUTPUT_VECTOR_SIZE: string;
            TEXT_SPLITTER_CHUNK_SIZE: string;
            TEXT_SPLITTER_CHUNK_OVERLAP: string;
            DATA_DIRECTORY: string;
            FILES_PROCESSING_CONCURRENCY: string;
            INTERNAL_DB: string;
            SCANNER_INTERVAL: string;
            DOCUMENTS_INDEXING_CONCURRENCY: string;
            EMBEDDING_CONCURRENCY: string;
        }
    }
}
