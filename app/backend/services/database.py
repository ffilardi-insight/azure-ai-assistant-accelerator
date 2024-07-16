import uuid

from azure.cosmos import CosmosClient
from backend.config.models import ChatHistoryItem, FeedbackRequest, FeedbackResponse
from backend.config import environment


class ChatHistoryDatabase():
    """
    A class that represents a database for storing and retrieving chat history.
    """
    
    def __init__(self):
        self.client = CosmosClient(
            environment.AZURE_COSMOS_ENDPOINT,
            environment.AZURE_COSMOS_KEY
        )
        self.client_db = self.client.get_database_client(environment.AZURE_COSMOS_DATABASE)
        self.client_db_container = self.client_db.get_container_client(environment.AZURE_COSMOS_CONTAINER)


    def load_chat_history(self, session_id: str, max_results: int = 5) -> list:
        """
        Load chat history for a given session ID.

        Args:
            session_id (str): The ID of the session for which to load the chat history.
            max_results (int, optional): The maximum number of chat history records to retrieve. Defaults to 5.

        Returns:
            list: A list of chat history prompts from the database.

        """
        chat_history = list(self.client_db_container.query_items(
            query="SELECT * FROM c WHERE c.session_id=@session_id_param ORDER BY c._ts DESC OFFSET 0 LIMIT @max_results_param",
            parameters=[
                {
                    "name": "@session_id_param",
                    "value": session_id
                },
                {
                    "name": "@max_results_param",
                    "value": max_results
                }
            ],
            enable_cross_partition_query=False
        ))

        if len(chat_history) > 1: chat_history.reverse()
        
        return chat_history


    def write_chat_history(self, session_id: str, user_prompt: str, assistant_response: str, total_tokens: int, id: str = str(uuid.uuid4())) -> str:
        """
        Writes the chat history to the database.

        Args:
            session_id (str): The ID of the chat session.
            user_prompt (str): The user's prompt.
            assistant_response (str): The assistant's response.

        Returns:
            str: The ID of the chat history item.
        """
        chat_history_item = ChatHistoryItem(
            id=id,
            session_id=session_id,
            user_prompt=user_prompt,
            assistant_response=assistant_response,
            total_tokens=total_tokens
        )

        self.client_db_container.upsert_item(chat_history_item)

        return chat_history_item['id']


    def update_feedback(self, request: FeedbackRequest):
        """
        Update the feedback rating for a given feedback item.

        Args:
            request (FeedbackRequest): The feedback request object containing the feedback ID, session ID, and feedback rating.

        Returns:
            FeedbackResponse: The response indicating the success of the feedback update.
        """
        item = self.client_db_container.read_item(item=request.id, partition_key=request.session_id)
        item['feedback_rating'] = request.feedback_rating

        self.client_db_container.upsert_item(item)

        response = FeedbackResponse(
            status = "Feedback updated successfully"
        )

        return response
