import os
from dotenv import load_dotenv

try:
    # Load environment variables from .env file for local development and testing
    load_dotenv()

    # Azure OpenAI API settings
    AZURE_OPENAI_ENDPOINT = os.environ.get('AZURE_OPENAI_ENDPOINT')
    AZURE_OPENAI_API_VERSION = os.environ.get('AZURE_OPENAI_API_VERSION')
    AZURE_OPENAI_API_KEY = os.environ.get('AZURE_OPENAI_API_KEY')
    AZURE_OPENAI_API_MODEL_CHAT = os.environ.get('AZURE_OPENAI_API_MODEL_CHAT')
    AZURE_OPENAI_API_MODEL_EMBEDDING = os.environ.get('AZURE_OPENAI_API_MODEL_EMBEDDING')

    # Azure Search settings
    AZURE_SEARCH_ENDPOINT = os.environ.get('AZURE_SEARCH_ENDPOINT')
    AZURE_SEARCH_API_VERSION = os.environ.get('AZURE_SEARCH_API_VERSION')
    AZURE_SEARCH_API_KEY = os.environ.get('AZURE_SEARCH_API_KEY')
    AZURE_SEARCH_INDEX_NAME = os.environ.get('AZURE_SEARCH_INDEX_NAME')
    AZURE_SEARCH_ADMIN_KEY = os.environ.get('AZURE_SEARCH_ADMIN_KEY')
    
    # Azure Storage settings
    AZURE_STORAGE_CONNECTION_STRING = os.environ.get('AZURE_STORAGE_CONNECTION_STRING')  

    # Azure Cosmos DB settings
    AZURE_COSMOS_ENDPOINT = os.environ.get('AZURE_COSMOS_ENDPOINT')
    AZURE_COSMOS_KEY = os.environ.get('AZURE_COSMOS_KEY')
    AZURE_COSMOS_DATABASE = os.environ.get('AZURE_COSMOS_DATABASE')
    AZURE_COSMOS_CONTAINER = os.environ.get('AZURE_COSMOS_CONTAINER')

except Exception as e:
    raise Exception(f"Error loading environment settings: {e}")
