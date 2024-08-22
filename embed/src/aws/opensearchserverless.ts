import {getClient} from "../opensearch";

export async function getCollection(endpoint: string, name: string, username: string, password: string) {
    const client = getClient(endpoint, username, password);

    try {
        const response = await client.search({
            index: name,
            body: {
                query: {
                    match_all: {}
                }
            }
        });

        const hits = response.body.hits;
        if (!hits || hits.total.value === 0) {
            console.log(`Collection ${name} exists on endpoint ${endpoint} but is empty.`);
            return [];  // Return an empty array if no documents are found
        } else {
            return hits.hits;
        }
    } catch (error) {
        if (error instanceof Error) {
            throw new Error(`Failed to get collection from endpoint ${endpoint}: ${error.message}`);
        } else {
            throw new Error(`Failed to get collection from endpoint ${endpoint}: ${String(error)}`);
        }
    }
}


export async function listCollections(endpoint: string, username: string, password: string): Promise<string[]> {
    const client = getClient(endpoint, username, password);

    try {
        const response = await client.cat.indices({ format: 'json' });

        // Extract index names from the response
        const collections = response.body.map((index: { index: string }) => index.index);

        return collections;
    } catch (error) {
        if (error instanceof Error) {
            throw new Error(`Failed to list collections from endpoint ${endpoint}: ${error.message}`);
        } else {
            throw new Error(`Failed to list collections from endpoint ${endpoint}: ${String(error)}`);
        }
    }
}

