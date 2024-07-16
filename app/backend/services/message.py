class MessageBuilder:
    """
    A class that builds a message by adding prompts, system prompts, tool calls, and tool results.
    """

    def __init__(self):
        self.prompts = []


    def add_system_prompt(self, content: str):
        """
        Add the system prompt as the first message in the list of prompts.

        Args:
            content (str): The content of the system prompt message.
        """
        if self.prompts:
            self.prompts[0] = {
                'role': 'system',
                'content': content
            }
        else:
            self.prompts.append({
                'role': 'system',
                'content': content
            })


    def add_prompt(self, role: str, content: str):
        """
        Add a prompt to the list of prompts.

        Args:
            role (str): The role of the participant in the conversation.
            content (str): The content of the participant's message.
        """
        self.prompts.append({
            'role': role,
            'content': content
        })


    def add_tool_calls(self, tool_calls: list):
        """
        Add a tool call to the list of prompts.

        Args:
            tool_calls (list): The tool calls list to add.
        """
        self.prompts.append({
            'role': 'assistant',
            'tool_calls': tool_calls
        })


    def add_tool_response(self, tool_id: str, function_name: str, content: str):
        """
        Add a tool response to the list of prompts.

        Args:
            tool_id (str): The ID of the tool being called.
            function_name (str): The name of the function being called.
            content (str): The content of the tool response.
        """
        self.prompts.append({
            'role': 'tool',
            'tool_call_id': tool_id,
            'name': function_name,
            'content': content
        })


    def get_prompts(self):
        """
        Get the list of prompts.

        Returns:
            list: The list of prompts.
        """
        return self.prompts
