
ANTHROPIC_API_KEY <- Sys.getenv("ANTHROPIC_API_KEY")


chat_claude <- ellmer::chat_claude(system_prompt = 'Ti si stručnjak za izradu shiny aplikacija uz pomoć r programskog jezika',
  model = 'claude-3-5-haiku-20241022',
  max_tokens = 2000,
  api_key = ANTHROPIC_API_KEY
)


prompt <- 'can you write app that takes csv file and let user choose target variabke to predict 
using tidymodels. Include EDA and results of modelling using common metrics.'


app <- chat_claude$chat(prompt)
