from pydantic import BaseModel
from typing import Dict, Optional


class ChatRequest(BaseModel):
    """
    Represents a request to ask a question to the assistant.

    Attributes:
        session_id (str): The ID of the session.
        user_id (str): The ID of the user.
        user_name (Optional[str]): The name of the user (optional).
        user_prompt (str): The prompt provided by the user.
    """
    session_id: str
    user_id: str
    user_name: Optional[str] = None
    user_prompt: str


class ChatResponse(BaseModel):
    """
    Represents a response from the assistant to a question.

    Attributes:
        assistant_response (str): The response from the assistant.
        response_id (str): The ID of the response.
        followup_questions (Optional[Dict[str, str]]): Any follow-up questions from the assistant (optional).
        total_tokens (int): The total number of tokens used in the response.
        model (str): The model used to generate the response.
    """
    assistant_response: str
    response_id: str
    followup_questions: Optional[Dict[str, str]] = {}
    total_tokens: int
    model: str


class FeedbackRequest(BaseModel):
    """
    Represents a feedback request to update a chat history item in the database.

    Attributes:
        id (str): The unique ID of the chat history item.
        session_id (str): The ID of the session.
        feedback_rating (bool): The rating of the feedback (True for positive, False for negative).
    """
    id: str
    session_id: str
    feedback_rating: bool


class FeedbackResponse(BaseModel):
    """
    Represents a response to a feedback request.

    Attributes:
        status (str): The status of the feedback response.
    """
    status: str


class SearchRequest(BaseModel):
    """
    Represents a request to search the index.

    Attributes:
        search_query (str): The search query.
        session_id (Optional[str]): The ID of the session (optional).
        max_results (Optional[int]): The maximum number of results to be returned (optional).
    """
    search_query: str
    session_id: Optional[str] = None
    max_results: Optional[int] = 5


class ChatHistoryItem(Dict[str, str]):
    """
    Represents a single chat history item.

    Attributes:
        id (str): The unique identifier for the chat history item.
        session_id (str): The session ID associated with the chat history item.
        user_prompt (str): The user's prompt in the chat history item.
        assistant_response (str): The assistant's response in the chat history item.
        total_tokens (int): The total number of tokens used in the chat history item.
    """
    id: str
    session_id: str
    user_prompt: str
    assistant_response: str
    total_tokens: int


class GptModelResponse(Dict[str, str]):
    """
    Represents a response from the GPT model.

    Attributes:
        id (str): The ID of the response.
        model (str): The model used to generate the response.
        content (str): The content of the response.
        tool_calls (list): The list of functions called by the model.
        completion_tokens (int): The number of completion tokens used.
        prompt_tokens (int): The number of prompt tokens used.
        total_tokens (int): The total number of tokens used.
    """
    id: str
    model: str
    content: str
    tool_calls: list
    completion_tokens: int
    prompt_tokens: int
    total_tokens: int