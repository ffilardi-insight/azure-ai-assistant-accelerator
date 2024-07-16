"""
A collection of methods to generate system prompts for the GPT model.
"""

def get_system_prompt_text(user_name: str):
    """
    Returns the system prompt text based on the user's name.

    Args:
        user_name (str): The name of the user.

    Returns:
        str: The system prompt text.
    """
    if not user_name:
        return f'You are a helpful assistant. You help users to find information about general topics. ' \
                'If you are unsure of an answer, ask the user to be more specific. If asking a clarifying question to the user would help, ask the question. ' \
                'Be concise in your answers. Do not use lists, unless you are asked to do so. '
    else:
        return f'You are talking to a person named {user_name}. You are his/her personal assistant and will help him/her to find information about general topics. ' \
                'If you are unsure of an answer, ask the user to be more specific. If asking a clarifying question to the user would help, ask the question. ' \
                'Be concise in your answers. Do not use lists, unless you are asked to do so. '


def get_system_prompt_text_followup():
    """
    Returns the system prompt text for generating next user questions.

    Returns:
        str: The system prompt text.
    """
    return f'You are a helpful assistant. You help users to find information about general topics. Below is a history of the conversation so far. ' \
            'Based on the previous line of questioning and the last response from the assistant, you will predict the next questions from the user and generate 3 very brief follow-up questions using the user voice. ' \
            'Do no repeat questions that have already been asked. ' \
            'Output the response ONLY as a JSON object, for example: { "q1": "What are the best movies directed by Stanley Kubrick?", "q2": "What is the best place to travel in Australia?", "q3": "Can I use pineapple in my pizza?" }. ' \
            'If you are unsure of an answer, DO NOT ask more questions and respond using only an empty JSON object, for example: { }'


def get_tools_functions():
    """
    Retrieves a list of tools functions.

    Returns:
        list: A list of dictionaries representing the tools functions.
    """
    return [
        {
            "function": {
                "description": "Retrieve sources from the Azure AI Search index based on a search query.",
                "name": "sample_search",
                "parameters": {
                    "properties": {
                        "search_query": {
                            "description": "Query string to retrieve information from Azure AI Search index.",
                            "type": "string"
                        }
                    },
                    "required": [
                        "search_query"
                    ],
                    "type": "object"
                }
            },
            "type": "function"
        }
    ]