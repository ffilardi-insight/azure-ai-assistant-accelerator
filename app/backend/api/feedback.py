from azure.cosmos import exceptions
from backend.config.models import FeedbackRequest, FeedbackResponse
from backend.services.database import ChatHistoryDatabase


def run(request: FeedbackRequest) -> FeedbackResponse:
    """
    Executes the main logic of the 'feedback' API endpoint.
    """
    try:
        feedback_api = FeedbackApi()
        return feedback_api.main(request)

    except exceptions.CosmosHttpResponseError as e:
        raise Exception(f"Database error in feedback.run: {e.reason} ({e.status_code})")

    except Exception as e:
        raise Exception(f"Error in feedback.run: {e}")
    

class FeedbackApi():
    """
    A class that provides the main logic for the 'feedback' API endpoint.
    """

    def __init__(self):
        self.chat_history_db = ChatHistoryDatabase()


    def main(self, request: FeedbackRequest) -> FeedbackResponse:
        """
        Runs the feedback processing logic.

        Args:
            request (FeedbackRequest): The feedback request object.

        Returns:
            FeedbackResponse: The response object containing the result of the feedback processing.
        """
        response = self.chat_history_db.update_feedback(request)
        return response
