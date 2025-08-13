library(ellmer)
DEFAULT_API_KEY = Sys.getenv("ANTHROPIC_API_KEY")


quick_chat <- ellmer::chat_anthropic(
        model = 'claude-3-5-haiku-latest',
        api_key = DEFAULT_API_KEY
      )
      
quick_chat$chat('Whats up?')
