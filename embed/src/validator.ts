import { lstat } from 'node:fs/promises';
import { dirname } from 'node:path';
import { getFoundationModel } from './aws/bedrock';
import { listCollections } from './aws/opensearchserverless';

export async function validate() {
    // use external region if provided
    if (process.env.ENV_REGION) {
        process.env.REGION = process.env.ENV_REGION;
    }

    // use external collection name if provided
    if (process.env.ENV_OPEN_SEARCH_SERVERLESS_COLLECTION_NAME) {
        process.env.OPEN_SEARCH_SERVERLESS_COLLECTION_NAME = process.env.ENV_OPEN_SEARCH_SERVERLESS_COLLECTION_NAME;
    }

    // use external host name if provided
    if (process.env.ENV_OPEN_SEARCH_HOSTNAME) {
        process.env.OPEN_SEARCH_HOSTNAME = process.env.ENV_OPEN_SEARCH_HOSTNAME;
    }

    // use external host name if provided
    if (process.env.ENV_OPENSEARCH_USERNAME) {
        process.env.OPENSEARCH_USERNAME = process.env.ENV_OPENSEARCH_USERNAME;
    }

    // use external host name if provided
    if (process.env.ENV_OPENSEARCH_PASSWORD) {
        process.env.OPENSEARCH_PASSWORD = process.env.ENV_OPENSEARCH_PASSWORD;
    }

    const { REGION, BEDROCK_EMBEDDING_MODEL_ID, DATA_DIRECTORY, OPEN_SEARCH_SERVERLESS_COLLECTION_NAME, OPEN_SEARCH_HOSTNAME, OPENSEARCH_USERNAME, OPENSEARCH_PASSWORD, INTERNAL_DB } =
        process.env;

    // Verify data directory exists
    try {
        const stats = await lstat(DATA_DIRECTORY);
        if (!stats.isDirectory()) {
            throw new Error(`${DATA_DIRECTORY} is not a directory`);
        }
    } catch (err) {
        console.error(`Failed to get data directory status ${DATA_DIRECTORY}`, err);
        process.exit(-1);
    }

    // Verify internal db directory exists
    try {
        const directory = dirname(INTERNAL_DB);
        const stats = await lstat(directory);
        if (!stats.isDirectory()) {
            throw new Error(`${directory} is not a directory`);
        }
    } catch (err) {
        console.error(`Failed to get internal db status ${INTERNAL_DB}`, err);
        process.exit(-1);
    }

    // Verify embedding model exists
    try {
        await getFoundationModel(REGION, BEDROCK_EMBEDDING_MODEL_ID);
    } catch (err) {
        console.error(`Embedding model ${BEDROCK_EMBEDDING_MODEL_ID} not found in region ${REGION}`, err);
        process.exit(-1);
    }

    const os_hostname = `${OPEN_SEARCH_HOSTNAME}`
    const os_username = `${OPENSEARCH_USERNAME}`
    const os_password = `${OPENSEARCH_PASSWORD}`
    // validate existing collection status and type
    const collections = await listCollections(os_hostname, os_username, os_password);
    const collection = collections.find((value) => value === OPEN_SEARCH_SERVERLESS_COLLECTION_NAME);
    if (collection) {
        console.log(`Collection ${OPEN_SEARCH_SERVERLESS_COLLECTION_NAME} in region ${REGION} found successfully.`);
    } else {
        console.error(`Unable to find collection ${OPEN_SEARCH_SERVERLESS_COLLECTION_NAME} in region ${REGION}`);
        process.exit(-1);
    }
}
