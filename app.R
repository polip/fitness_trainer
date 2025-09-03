library(shiny)
library(bslib)
library(tidyverse)
library(ellmer)  # For LLM integration
library(pagedown) # For HTML to PDF conversion
library(tinytex)

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
        sliderInput("age", "Age", value = 40, min = 14, max = 85),
        sliderInput("weight", "Weight (kg)", value = 99, min = 30, max = 180),
        sliderInput("height", "Height (cm)", value = 185, min = 100, max = 225)
        
      ),  
      
      # Fitness Goals
      accordion_panel(
        "Fitness Goals",
        selectInput("training_type", "Type of Training", 
                    choices = c("Strength", "Hypertrophy", "Weight Loss", "Endurance", 
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
  
  # Reactive value to store the fitness plan
  fitness_plan <- reactiveVal("")
  
  # Show loading message when generating
  output$loading_text <- renderText({
    if(input$generate > 0) {
      "Generating your personalized fitness plan... This may take a few moments."
    } else {
      "Enter your information and click 'Generate Fitness Plan' to get started."
    }
  })
  
  # Generate fitness plan when button is clicked
  observeEvent(input$generate, {
    # Construct the user profile from inputs
    user_profile <- tibble(
      age = input$age,
      gender=input$gender,
      weight = input$weight,
      height = input$height,
      training_type = input$training_type,
      experience = input$experience,
      frequency = input$frequency,
      goals = if(input$goals == "") "General fitness improvement" else input$goals,
      limitations = if(input$limitations == "") "None" else input$limitations,
      equipment = input$equipment
    )
    
    # System prompt for Claude AI
    system_prompt <- "You are a professional fitness trainer and nutrition specialist with expertise in creating personalized workout plans. You provide detailed, evidence-based fitness advice tailored to individual needs and goals. Your recommendations are practical, safe, and effective for people of all fitness levels."
    
    # Create user prompt for Claude
    user_prompt <- glue::glue(
      "Create a detailed 4-week fitness plan for {user_profile$age} years old {user_profile$gender}, 
      weighing {user_profile$weight}kg and {user_profile$height}cm tall. Each daily workout should contain at least 6 exercises.
      
      
      Training type: {user_profile$training_type}
      Experience level: {user_profile$experience}
      Training frequency: {user_profile$frequency}
      Specific goals: {user_profile$goals}
      Limitations/injuries: {user_profile$limitations}
      Available equipment: {user_profile$equipment}
      
      The plan should include:
      1. Initial assesment of fitness with expected ranges for inital asessment workouts depending on age, sex, weight etc.
      2. A daily workout schedule
      3. Detailed exercises for each workout day from weekly plan. 
      4. Sets, reps, rest periods, RPM
      5. Instructions for each exercise
      6. Progression scheme over the 4 weeks
      7. Detailed nutrition recommendations
      8. Recovery tips
      9. Motivation tips
     
            
      Format the response in markdown with clear headings and sections.Don't use emojis, just plain text or links. Write all steps detaily, don't use ...would follow... or similar phrases. Don't write framework, but complete detailed guide"
    )
    
    # LLM call to generate fitness plan (using ellmer package with Claude)
    # Wrapping in tryCatch to handle potential errors
    plan_result <- tryCatch({
      # Call the Claude AI with the prompt using the pre-configured API key
      # Note: For Claude, we need to use the Anthropic API which has a different format
      # Using ellmer package with Claude model
      claude <- ellmer::chat_anthropic(
        model = 'claude-3-5-haiku-latest',
        api_key = DEFAULT_API_KEY,  # Using the pre-configured API key
        system = system_prompt  # Adding system prompt for Claude
      )
      
      llm_response <- claude$chat(user_prompt)   
      
      # For testing/demo purposes, we'll also include a mock response
      # as a fallback in case the API call doesn't work
      if (is.null(llm_response) || llm_response == "") {stop('LLM response not created!')} else {
        llm_response
      }
    }, error = function(e) {
      paste("Error generating fitness plan:", e$message, 
            "\n\nPlease try again or contact the app administrator if the error persists.")
    })
    
    # Store the generated plan
    fitness_plan(plan_result) ### reactive value
    
    # Update the UI with the markdown content
    output$fitness_plan_ui <- renderUI({
      if(input$generate > 0) {
        HTML(markdown::markdownToHTML(text = fitness_plan(), fragment.only = TRUE))
      }
    })
  })
  
  # PDF Download handler
  output$downloadPDF <- downloadHandler(
    filename = function() {
      paste("fitness-plan-", lubridate::now(), ".pdf", sep = "")
    },
    content = function(file) {
      # Don't try to create a PDF if no plan has been generated
      if (fitness_plan() == "") {
        showNotification("Please generate a fitness plan first", type = "error")
        return()
      }
      
      # Create temporary Rmd file
      tempRmd <- tempfile(fileext = ".Rmd")
      
      # Create an R Markdown document with the fitness plan content
      rmd_content <- paste0(
      "---
      title: \"Your Fitness Plan\"
      output: 
        pdf_document:
          latex_engine: xelatex
      ---

      ",
        fitness_plan()
      )
      
      # Write the Rmd content to the temporary file
      writeLines(rmd_content, tempRmd)
      
      # Load required packages
      if (!requireNamespace("tinytex", quietly = TRUE)) {
        showNotification("Required package 'tinytex' is missing", type = "error")
        return()
      }
      
      # Convert Rmd to PDF using rmarkdown with detailed error logging
      tryCatch({
        # Use tinytex to handle LaTeX compilation
        withr::with_envvar(c(TINYTEX_VERBOSE = "true"), {
          rmarkdown::render(tempRmd, output_file = file, quiet = FALSE)
        })
      }, error = function(e) {
        # Log detailed error information
        message("PDF generation error: ", e$message)
        showNotification(paste("Error creating PDF:", e$message), type = "error")
        
        # Try to get more LaTeX error details
        log_files <- list.files(dirname(tempRmd), pattern = "\\.log$", full.names = TRUE)
        if (length(log_files) > 0) {
          log_content <- readLines(log_files[1], warn = FALSE)
          error_lines <- grep("! ", log_content, value = TRUE)
          if (length(error_lines) > 0) {
            message("LaTeX errors found: ", paste(error_lines, collapse = "; "))
          }
        }
      }, finally = {
        # Clean up
        unlink(tempRmd)
      })
    },
    contentType = "application/pdf"
  )
}

# Run the application
shinyApp(ui = ui, server = server)
