import json

from azure.cosmos import exceptions
from backend.services.search import CognitiveSearch
from backend.services.database import ChatHistoryDatabase
from backend.services.gpt import GptModel
from backend.services.message import MessageBuilder
from backend.config import prompts
from backend.config.models import ChatRequest, ChatResponse, SearchRequest


def run(request: ChatRequest) -> ChatResponse:
    """
    Executes the main logic of the 'chat' API endpoint.
    """
    try:
        chat_api = ChatApi()
        return chat_api.main(request)

    except exceptions.CosmosHttpResponseError as e:
        raise Exception(f"Database error in chat.run: {e.reason} ({e.status_code})")
    
    except Exception as e:
        raise Exception(f"Error in chat.run: {e}")


class ChatApi():
    """
    A class that provides the main logic for the 'chat' API endpoint.
    """

    def __init__(self):
        self.chat_history_db = ChatHistoryDatabase()
        self.gpt_model = GptModel()
        self.cognitive_search = CognitiveSearch()
        self.messages = MessageBuilder()
        self.total_tokens = 0

    def main(self, request: ChatRequest) -> ChatResponse:
        """
        Executes the main logic of the 'chat' API endpoint.

        Args:
            request (ChatRequest): The request object containing user input an related metadata.

        Returns:
            ChatResponse: The response object containing the assistant's response.
        """
        # Set user ID
        self.gpt_model.user_id = request.user_id

        # Set system prompt
        self.messages.add_system_prompt(prompts.get_system_prompt_text(request.user_name))

        # Load chat history
        self.load_chat_history(request.session_id, 10)

        # Set current user prompt
        self.messages.add_prompt('user', request.user_prompt)

        # Call GPT model to generate tool call(s)
        model_response = self.gpt_model.call_gpt_model_tools(self.messages.get_prompts())
        self.total_tokens += model_response['total_tokens']

        if len(model_response['tool_calls']) > 0:
            
            # Process tool calls
            self.process_tool_calls(request.session_id, model_response['tool_calls'])

            # Call GPT model to generate a response based on the tool results
            model_response = self.gpt_model.call_gpt_model(self.messages.get_prompts())
            self.total_tokens += model_response['total_tokens']

        # Set assistant response
        self.messages.add_prompt('assistant', model_response['content'])

        # Set system prompt for follow-up questions
        self.messages.add_system_prompt(prompts.get_system_prompt_text_followup())

        # Call GPT model to generate follow-up questions
        model_response_followup = self.gpt_model.call_gpt_model(self.messages.get_prompts())
        self.total_tokens += model_response_followup['total_tokens']

        try:
            # Parse the follow-up questions into a JSON object
            followup_questions = json.loads(model_response_followup['content'])
            
        except json.JSONDecodeError:
            followup_questions = {}

        # Write user prompt and assistant response to the chat history database
        self.chat_history_db.write_chat_history(
            id = model_response['id'],
            session_id = request.session_id,
            user_prompt = request.user_prompt,
            assistant_response = model_response['content'],
            total_tokens = self.total_tokens
        )

        # Set the response object
        response = ChatResponse(
            assistant_response = model_response['content'],
            response_id = model_response['id'],
            followup_questions = followup_questions,
            total_tokens=self.total_tokens,
            model=model_response['model']
        )

        return response


    def load_chat_history(self, session_id: str, max_results: int) -> None:
        """
        Load chat history for a given session ID.

        Args:
            session_id (str): The ID of the session.
            max_results (int): The maximum number of chat history records to load.

        Returns:
            None
        """
        # Load chat history
        chat_history_records = self.chat_history_db.load_chat_history(session_id, max_results)

        # Set chat history prompts
        if chat_history_records:
            for record in chat_history_records:
                self.messages.add_prompt('user', record['user_prompt'])
                self.messages.add_prompt('assistant', record['assistant_response'])


    def process_tool_calls(self, session_id: str, tool_calls: list) -> None:
        """
        Process the tool calls and add the results to the messages.

        Args:
            session_id (str): The session ID.
            tool_calls (list): A list of tool calls.

        Returns:
            None
        """
        # Add tool calls to the messages
        self.messages.add_tool_calls(tool_calls)

        for tool in tool_calls:

            if tool.function.name == 'sample_search':

                # Load function arguments
                arguments_json = json.loads(tool.function.arguments)

                # Fetch records from index database
                records = list(
                    self.cognitive_search.search_index(SearchRequest(
                        search_query = arguments_json['search_query'] if 'search_query' in arguments_json else "",
                        session_id = session_id,
                        max_results = 5
                    ))
                )

                # Add tool results to the messages
                self.messages.add_tool_response(tool.id, tool.function.name, json.dumps(records))     
    