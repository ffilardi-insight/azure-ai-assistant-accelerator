import os
import logging
import requests
import json

from backend.config import environment


def init_search_index() -> None:
    """
    Initializes the Azure Cognitive Search index.

    This function creates an Azure Cognitive Search index if it doesn't already exist.
    It loads the index definition from a JSON file, sets the necessary configuration values,
    and makes a request to the Azure Cognitive Search API to create the index.
    """
    try:
        # Azure Cognitive Search endpoint (index)
        endpoint = f'{environment.AZURE_SEARCH_ENDPOINT}indexes?api-version={environment.AZURE_SEARCH_API_VERSION}'
        
        # Get the current directory
        app_directory = os.path.dirname(os.path.abspath(__file__))
        search_config_directory = os.path.join(app_directory, "../config/search")

        # Load datasource definition
        with open(f'{search_config_directory}/index.json', 'r') as file:
            search_index = json.load(file)

        # Check if index already exists, if no, create it from the local definition file
        if (check_search_index(environment.AZURE_SEARCH_INDEX_NAME) == True):
            logging.info("Azure AI Cognitive Search index already exists.")
            return
        else:
            # Set the index name
            search_index['name'] = environment.AZURE_SEARCH_INDEX_NAME

            # Set the Azure Cognitive Search endpoint and API key
            search_index['vectorSearch']['vectorizers'][0]['azureOpenAIParameters']['resourceUri'] = environment.AZURE_OPENAI_ENDPOINT
            search_index['vectorSearch']['vectorizers'][0]['azureOpenAIParameters']['apiKey'] = environment.AZURE_OPENAI_ENDPOINT

            # Set the request headers
            headers = {
                'Content-Type': 'application/json',
                'api-key': environment.AZURE_SEARCH_ADMIN_KEY
            }

            # Call Azure AI Cognitive Search API to create the index
            response = requests.post(endpoint, headers=headers, json=search_index)

            if response.status_code == 201:
                logging.info("Azure AI Cognitive Search index created successfully.")
            else:
                logging.error(f"Failed to create Azure AI Cognitive Search index. Status code: {response.status_code} - Response: {response.json()}")
        
    except Exception as e:
        raise Exception(f"Error in CognitiveSearch.init_search_index: {e}")
    

def check_search_index(index_name: str) -> bool:
    """
    Checks if an index with the given name exists in the Azure Search service.

    Args:
        index_name (str): The name of the index to check.

    Returns:
        bool: True if the index exists, False otherwise.
    """
    try:
        url = f"{environment.AZURE_SEARCH_ENDPOINT}indexes/{index_name}?api-version={environment.AZURE_SEARCH_API_VERSION}"
        headers = {
            "Content-Type": "application/json",
            "api-key": environment.AZURE_SEARCH_ADMIN_KEY
        }

        response = requests.get(url, headers=headers)

        if response.status_code == 200:
            return True
        elif response.status_code == 404:
            return False
        else:
            logging.error(f"Error checking index {index_name}: {response.status_code} - {response.text}")
            response.raise_for_status()

    except Exception as e:
        raise Exception(f"Error in CognitiveSearch.check_index_exists: {e}")