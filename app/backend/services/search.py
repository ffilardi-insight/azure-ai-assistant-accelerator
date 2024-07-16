from azure.search.documents import SearchClient
from azure.search.documents.models import VectorizedQuery
from azure.core.credentials import AzureKeyCredential
from backend.services.gpt import GptModel
from backend.config.models import SearchRequest
from backend.config import environment


class CognitiveSearch():
    """
    Provides search functionality using Azure AI Cognitive Search.
    """

    def __init__(self):
        
        self.client = SearchClient(
            endpoint = environment.AZURE_SEARCH_ENDPOINT,
            api_version = environment.AZURE_SEARCH_API_VERSION,
            index_name = environment.AZURE_SEARCH_INDEX_NAME,
            credential = AzureKeyCredential(environment.AZURE_SEARCH_API_KEY)
        )
        self.gpt_model = GptModel()


    def search_index(self, request: SearchRequest):
        """
        Performs a hybrid + semantic search in the Azure AI Cognitive Search index database.

        Args:
            request (SearchRequest): The search request object containing the search query and optional filters.

        Returns:
            azure.search.documents.SearchResults: The search results from the Azure Cognitive Search service.
        """
        embedding = self.gpt_model.generate_embeddings(request.search_query)

        vector_queries = [VectorizedQuery(
            vector = embedding,
            k_nearest_neighbors = 10,
            fields = "content_vector"
        )]

        results = self.client.search(
            session_id = request.session_id,
            include_total_count = True,
            top = request.max_results,
            filter = "",
            order_by = None,
            select = ["id", "title", "content", "url"],
            search_fields = ["title", "content", "keyphrases"],
            search_text = request.search_query,
            query_type = "semantic",
            search_mode = "any",
            scoring_statistics = "global",
            scoring_profile = "scoring-profile",
            semantic_configuration_name = "semantic-config",
            vector_filter_mode = "preFilter",
            vector_queries = vector_queries
        )

        return results
