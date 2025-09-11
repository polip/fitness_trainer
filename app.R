library(shiny)
library(bslib)
library(tidyverse)
library(ellmer)  # For LLM integration
library(pagedown) # For HTML to PDF conversion
library(tibble) # For tibble()

# Set a default API key directly in the code
DEFAULT_API_KEY <- Sys.getenv("ANTHROPIC_API_KEY")


# Set up the UI
ui <- page_sidebar(
  title = "AI Fitness Plan Generator",
  sidebar = sidebar(
    width = 300,
    
    # Personal Information
    accordion(
      accordion_panel(
        "Personal Information",
        selectInput("gender", "Gender",choices = c('Male','Female') ),
        sliderInput("age", "Age", value = 47, min = 14, max = 85),
        sliderInput("weight", "Weight (kg)", value = 99, min = 30, max = 180),
        sliderInput("height", "Height (cm)", value = 189, min = 100, max = 225)
        
      ),  
      
      # Fitness Goals
      accordion_panel(
        "Fitness Goals",
        selectInput("training_type", "Type of Training", 
                    choices = c("Strength", "Hypertrophy", "Weight Loss", "Endurance", "High intensity interval training", 
                                "Functional", "General Fitness")),
        selectInput("experience", "Experience Level", 
                    choices = c("Beginner", "Intermediate", "Advanced")),
        selectInput("frequency", "Training Frequency", 
                    choices = c("2-3 days/week", "3-4 days/week", "4-5 days/week", "5+ days/week")),
        textAreaInput("goals", "Specific Goals (optional)", 
                      placeholder = "e.g., Run a 5K, Build bigger arms, Improve posture...")
        
      ),
      # Health Considerations
      
      accordion_panel(
        "Health Considerations",
        textAreaInput("limitations", "Injuries or Limitations (if any)", 
                      placeholder = "e.g., Bad knees, Lower back pain..."),
        selectInput("equipment", "Available Equipment", 
                    choices = c("Full Gym", "Home Gym Basics", "Minimal/Bodyweight Only"))
        
      )
    ),
    
    
    # Generate Button
    actionButton("generate", "Generate Fitness Plan", class = "btn-primary btn-lg", 
                 width = "100%", icon = icon("dumbbell")),
    # Download Button
    downloadButton("downloadPDF", "Download plan as PDF", class = "btn-secondary btn-lg", 
                   width = "100%", icon = icon("download")),
    # API Key Input
    textInput("api_key", "Anthropic API Key", placeholder = "Enter your API key here"),
  ),
  
  # Main Panel
  card(
    card_header("Your Personalized Fitness Plan"),
    card_body(
      textOutput("loading_text"),
      uiOutput("fitness_plan_ui")
    )
  )
)

# Server logic
server <- function(input, output, session) {

  # Track usage per session
  session_requests <- reactiveVal(0)
  MAX_REQUESTS_PER_SESSION <- 3
  
  # Reactive values to store the fitness plan and loading state
  fitness_plan <- reactiveVal("")
  is_generating <- reactiveVal(FALSE)
  
  # Show dynamic content based on state
  output$loading_text <- renderText({
    if(is_generating()) {
      "🔄 Generating your personalized fitness plan..."
    } else if(input$generate == 0) {
      "Enter your information and click 'Generate Fitness Plan' to get started."
    } else {
      "" # Hide when plan is ready
    }
  })
  
  # Generate fitness plan when button is clicked
  observeEvent(input$generate, {
    # Set loading state
    is_generating(TRUE)
    fitness_plan("") # Clear previous plan
    
    # ---- Development/Testing Control ----
    # Set `APP_MODE=production` as an environment variable to use the live API
    APP_MODE <- Sys.getenv("APP_MODE", "development")

    current_count <- session_requests()
    if (current_count >= MAX_REQUESTS_PER_SESSION) {
      is_generating(FALSE)
      showNotification("You've reached the maximum number of requests for this session. Please refresh to continue.",
                      type = "error", duration = 10)
      return()
    }

    # Increment counter before API call
    session_requests(current_count + 1)

    # Construct the user profile from inputs
    user_profile <- tibble(
      age = input$age,
      gender = input$gender,
      weight = input$weight,
      height = input$height,
      training_type = input$training_type,
      experience = input$experience,
      frequency = input$frequency,
      goals = if (input$goals == "") "General fitness improvement" else input$goals,
      limitations = if (input$limitations == "") "None" else input$limitations,
      equipment = input$equipment
    )

    # System prompt for Claude AI
    system_prompt <- "You are a professional fitness trainer and nutrition specialist with expertise in creating personalized workout plans. You provide detailed, evidence-based fitness advice tailored to individual needs and goals. Your recommendations are practical, safe, and effective for people of all fitness levels."

    # Create user prompt for Claude
    user_prompt <- glue::glue(
      "Create a detailed 1-week fitness plan for {user_profile$age} years old {user_profile$gender}, \n      weighing {user_profile$weight}kg and {user_profile$height}cm tall. Each daily workout should contain at least 6 exercises.\n\n      Training type: {user_profile$training_type}\n      Experience level: {user_profile$experience}\n      Training frequency: {user_profile$frequency}\n      Specific goals: {user_profile$goals}\n      Limitations/injuries: {user_profile$limitations}\n      Available equipment: {user_profile$equipment}\n\n      The plan should include:\n      1. Initial assesment of fitness. Also provide expected ranges for inital asessment workouts depending on age, sex, weight.\n      2. A weekly workout schedule\n      3. Detailed exercises for each workout day from weekly plan. \n      4. Sets, reps, rest periods, RPM\n      5. Instructions for each exercise\n      6. Detailed nutrition recommendations\n      7. Recovery tips\n\n      Format the response in markdown with clear headings and sections.Don't use emojis, just plain text or links. Write all steps detaily, don't use ...would follow... or similar phrases. Don't write framework, but complete detailed guide"
    )

    # Use API key from input
    api_key_value <- DEFAULT_API_KEY

    plan_result <- tryCatch({
      if (APP_MODE == "development") {
        # --- MOCK RESPONSE (for development) ---
        message("APP_MODE is 'development'. Using mock data.")
        Sys.sleep(1)
        readr::read_file("mock_plan.md")
      } else {
        # --- LIVE API CALL (for production) ---
        message("APP_MODE is 'production'. Making live API call.")
        claude <- ellmer::chat_anthropic(
          model = 'claude-sonnet-4-20250514',
          api_key = api_key_value,
          system = system_prompt
        )
        llm_response <- claude$chat(user_prompt)
        if (is.null(llm_response) || llm_response == "") {
          stop('LLM response not created!')
        } else {
          llm_response
        }
      }
    }, error = function(e) {
      message("Error during plan generation: ", e$message)
      paste("Error generating fitness plan:", e$message,
            "\n\nPlease try again or contact the app administrator if the error persists.")
    })

    # Store the generated plan and stop loading
    fitness_plan(plan_result)
    is_generating(FALSE)

    # Update the UI with the markdown content
    output$fitness_plan_ui <- renderUI({
      if (!is_generating() && fitness_plan() != "") {
        HTML(markdown::markdownToHTML(text = fitness_plan(), fragment.only = TRUE))
      } else if (is_generating()) {
        div(
          style = "text-align: center; padding: 50px;",
          div(
            class = "spinner-border text-primary",
            role = "status",
            style = "width: 3rem; height: 3rem;",
            span(class = "visually-hidden", "Loading...")
          ),
          br(), br(),
          h4("Creating your personalized fitness plan...", style = "color: #666;"),
          p("Analyzing your profile and generating customized recommendations.", style = "color: #888;")
        )
      }
    })
  })
  
  # PDF Download handler
  output$downloadPDF <- downloadHandler(
    filename = function() {
      paste0("fitness-plan-", format(lubridate::now(), "%Y-%m-%d_%H-%M-%S"), ".pdf")
    },
    content = function(file) {
      # Don't try to create a PDF if no plan has been generated
      if (fitness_plan() == "") {
        showNotification("Please generate a fitness plan first", type = "error")
        return()
      }
      
      # Create temporary HTML file
      tempHtml <- tempfile(fileext = ".html")
      
      # Create HTML content with the fitness plan
      html_content <- paste0(
        "<!DOCTYPE html>
<html>
<head>
<meta charset='utf-8'>
<title>Your Fitness Plan</title>
<style>
body { 
  font-family: Arial, sans-serif; 
  line-height: 1.6; 
  margin: 40px;
  max-width: 800px;
}
h1, h2, h3 { 
  color: #333; 
  margin-top: 30px;
}
h1 { 
  text-align: center; 
  border-bottom: 2px solid #333;
  padding-bottom: 10px;
}
@media print {
  body { margin: 20px; }
}
</style>
</head>
<body>
<h1>Your Fitness Plan</h1>",
        markdown::markdownToHTML(text = fitness_plan(), fragment.only = TRUE),
        "</body></html>"
      )
      
      # Write the HTML content to the temporary file
      writeLines(html_content, tempHtml)
      
      # Convert HTML to PDF using pagedown
      tryCatch({
        pagedown::chrome_print(
          input = tempHtml, 
          output = file,
          timeout = 60
        )
      }, error = function(e) {
        # Log detailed error information
        message("PDF generation error: ", e$message)
        showNotification("Failed to generate PDF. This might be due to Chrome/Chromium not being available on the server.", type = "error", duration = 10)
      }, finally = {
        # Clean up
        unlink(tempHtml)
      })
    },
    contentType = "application/pdf"
  )
}

# Run the application
shinyApp(ui = ui, server = server)
