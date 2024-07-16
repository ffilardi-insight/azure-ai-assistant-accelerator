from openai import AzureOpenAI
from backend.config import environment
from backend.config import prompts
from backend.config.models import GptModelResponse

class GptModel():
    """
    A class that provides AI services using GPT models.
    """

    def __init__(self, user_id: str = None):

        self.user_id = user_id
        
        self.client = AzureOpenAI(
            api_key = environment.AZURE_OPENAI_API_KEY,
            azure_endpoint = environment.AZURE_OPENAI_ENDPOINT,
            api_version = environment.AZURE_OPENAI_API_VERSION
        )
        self.model_chat = environment.AZURE_OPENAI_API_MODEL_CHAT
        self.model_embedding = environment.AZURE_OPENAI_API_MODEL_EMBEDDING

    def call_gpt_model(self, messages: list) -> GptModelResponse:
        """
        Calls the GPT model to generate a response based on the given messages.

        Args:
            messages (list): A list of messages exchanged between the user and the model.

        Returns:
            GptModelResponse: The response from the GPT model, containing the generated content and other information.
        """
        request = self.client.chat.completions.create(
            model=self.model_chat,
            temperature=0.7,
            max_tokens=1000,
            stream=False,
            user=self.user_id,
            messages=messages
        )

        response = GptModelResponse(
            id = request.id,
            model = request.model,
            content = request.choices[0].message.content,
            tool_calls = [],
            completion_tokens = request.usage.completion_tokens,
            prompt_tokens = request.usage.prompt_tokens,
            total_tokens = request.usage.total_tokens
        )

        return response


    def call_gpt_model_tools(self, messages: list) -> GptModelResponse:
        """
        Calls the GPT model with Tools to generate a list of functions and arguments to be called based on the given messages.

        Args:
            messages (list): A list of messages to be used as input for the GPT model.

        Returns:
            GptModelResponse: The response from the GPT model, containing the generated content and other information.
        """        
        request = self.client.chat.completions.create(
            model=self.model_chat,
            temperature=0.7,
            max_tokens=1000,
            stream=False,
            user=self.user_id,
            messages=messages,
            tool_choice="auto",
            tools=prompts.get_tools_functions()
        )

        response = GptModelResponse(
            id = request.id,
            model = request.model,
            content = request.choices[0].message.content,
            tool_calls = request.choices[0].message.tool_calls if request.choices[0].message.tool_calls else [],
            completion_tokens = request.usage.completion_tokens,
            prompt_tokens = request.usage.prompt_tokens,
            total_tokens = request.usage.total_tokens
        )

        return response


    def generate_embeddings(self, text: str) -> list:
        """
        Generate embeddings for the given text.

        Args:
            text (str): The input text to generate embeddings for.

        Returns:
            str: The generated embeddings for the input text.
        """
        response = self.client.embeddings.create(
            model=self.model_embedding,
            input=text
        )
        return response.data[0].embedding
