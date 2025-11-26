# utils/claude_client.py
import anthropic
import config

client = anthropic.Anthropic(api_key=config.ANTHROPIC_API_KEY)

def call_claude(prompt):
    """
    Calls Claude API and returns the text response.
    """
    try:
        message = client.messages.create(
            model="claude-sonnet-4-5",
            max_tokens=2048,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )
        return message.content[0].text
    except Exception as e:
        print(f"❌ Claude API error: {e}")
        raise