# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains two implementations of an AI-powered fitness plan generator:
1. **Python/Streamlit** version ([app.py](app.py)) - Modern, recommended implementation
2. **R/Shiny** version ([app.R](app.R)) - Legacy implementation

Both apps generate personalized fitness plans using AI (Anthropic Claude, OpenAI GPT, or Google Gemini). Users input their personal information, fitness goals, and health considerations, and the app generates a comprehensive workout plan with nutrition advice and recovery strategies.

## Tech Stack

### Python/Streamlit (Recommended)
- **Streamlit**: Modern Python web framework for data apps
- **anthropic**: Official Anthropic Python SDK for Claude
- **openai**: Official OpenAI Python SDK
- **google-generativeai**: Official Google Gemini SDK
- **weasyprint**: HTML to PDF conversion
- **python-dotenv**: Environment variable management

### R/Shiny (Legacy)
- **R/Shiny**: Web framework for the application UI and server logic
- **bslib**: Modern UI components and theming
- **ellmer**: LLM integration library for connecting to AI providers
- **pagedown**: HTML to PDF conversion for downloadable plans

## Running the Application

### Python/Streamlit

#### Setup
```bash
# Install dependencies
pip install -r requirements.txt

# Copy environment template
cp .env.example .env

# Edit .env and add your API keys
```

#### Development Mode (Mock Data)
```bash
export APP_MODE=development
streamlit run app.py
```

#### Production Mode (Live API)
```bash
export APP_MODE=production
streamlit run app.py
```

Alternatively, set `APP_MODE` in your `.env` file.

### R/Shiny

#### Development Mode (Mock Data)
```r
Sys.setenv(APP_MODE = "development")
shiny::runApp("app.R")
```

#### Production Mode (Live API)
```r
Sys.setenv(APP_MODE = "production")
shiny::runApp("app.R")
```

## API Keys

### Python/Streamlit
API keys can be configured in two ways:
1. Environment variables in `.env` file (create from `.env.example`)
2. User input fields in the UI (allows runtime provider switching)

### R/Shiny
API keys are managed through:
1. Environment variables in `.Renviron` (gitignored)
2. User input fields in the UI

Required environment variables:
- `ANTHROPIC_API_KEY` (optional - for Claude)
- `OPENAI_API_KEY` (optional - for GPT)
- `GOOGLE_API_KEY` (optional - for Gemini)

## Key Architecture

### Application Structure

#### Python/Streamlit Files
- **app.py**: Main Streamlit application
- **requirements.txt**: Python package dependencies
- **.env**: Environment variables (gitignored, create from `.env.example`)
- **.env.example**: Template for environment variables
- **mock_plan.md**: Sample fitness plan for development/testing

#### R/Shiny Files (Legacy)
- **app.R**: Main Shiny application containing UI and server logic
- **quick_chat.R**: Standalone utility for testing ellmer integration with Claude
- **write manifest.R**: Utility for generating deployment manifests for Posit Connect
- **manifest.json**: Deployment manifest for Posit Connect (320KB, contains full dependency tree)
- **renv.lock**: R package dependency lock file
- **.Renviron**: Local environment variables (gitignored, contains API keys)

### Core Workflow

1. User fills out profile information in the sidebar (personal info, fitness goals, health considerations)
2. User selects AI provider and enters API key
3. User clicks "Generate Fitness Plan"
4. App constructs a detailed prompt from user inputs
5. AI generates markdown-formatted fitness plan with:
   - Initial fitness assessment with expected ranges
   - Weekly workout schedule (7 days)
   - Detailed exercises (minimum 6 per day) with sets/reps/rest/RPM
   - Nutrition recommendations
   - Recovery tips
6. Plan is rendered as HTML and displayed
7. User can download plan as PDF

### AI Provider Integration

#### Python/Streamlit
The app uses official Python SDKs for each provider:

```python
# Anthropic Claude
from anthropic import Anthropic
client = Anthropic(api_key=api_key)
response = client.messages.create(
    model="claude-sonnet-4-20250514",
    max_tokens=8000,
    system=system_prompt,
    messages=[{"role": "user", "content": user_prompt}]
)

# OpenAI GPT
from openai import OpenAI
client = OpenAI(api_key=api_key)
response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt}
    ]
)

# Google Gemini
import google.generativeai as genai
genai.configure(api_key=api_key)
model = genai.GenerativeModel(
    model_name='gemini-2.0-flash-exp',
    system_instruction=system_prompt
)
response = model.generate_content(user_prompt)
```

#### R/Shiny
The app supports three AI providers via `ellmer`:

```r
# Anthropic Claude
chat_anthropic(model = 'claude-sonnet-4-20250514', api_key = api_key_value, system = system_prompt)

# OpenAI GPT
chat_openai(model = 'gpt-4o', api_key = api_key_value, system = system_prompt)

# Google Gemini
chat_gemini(model = 'gemini-2.5-flash', api_key = api_key_value, system = system_prompt)
```

All providers receive the same system prompt (fitness trainer persona) and user prompt (detailed requirements).

### PDF Generation

#### Python/Streamlit
PDF export uses `weasyprint` which converts HTML to PDF:
1. Converts markdown plan to HTML using `markdown` library
2. Adds CSS styling for proper formatting
3. Uses WeasyPrint to render HTML as PDF in-memory
4. Returns PDF as downloadable BytesIO object

#### R/Shiny
PDF export uses `pagedown::chrome_print()` which requires Chrome/Chromium:
1. Converts markdown plan to HTML with embedded CSS
2. Writes to temporary HTML file
3. Uses Chrome headless mode to render PDF
4. Cleans up temporary files

## Deployment

### Python/Streamlit

#### Streamlit Cloud
```bash
# Streamlit Cloud automatically detects requirements.txt
# Add secrets in Streamlit Cloud dashboard:
# - ANTHROPIC_API_KEY
# - OPENAI_API_KEY
# - GOOGLE_API_KEY
# - APP_MODE
```

#### Docker
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8501
CMD ["streamlit", "run", "app.py"]
```

### R/Shiny - Posit Connect Deployment

The R/Shiny app is designed for deployment to Posit Connect:

1. Run `write manifest.R` to generate `manifest.json` and update `renv.lock`
2. Deploy using `rsconnect` package or Posit Connect UI
3. Set environment variables in Posit Connect dashboard

The `manifest.json` file contains all package dependencies and platform information needed for reproducible deployment.

## Development Notes

### Python/Streamlit
- Session state manages `fitness_plan`, `is_generating`, and `session_requests`
- Session request limit (`MAX_REQUESTS_PER_SESSION = 3`) tracked but not enforced
- Loading spinner shown during plan generation via `st.spinner()`
- PDF generation gracefully handles WeasyPrint errors with user notification
- Custom CSS provides professional styling matching modern design standards

### R/Shiny
- Loading state is managed via `reactiveVal(is_generating)` to show spinner during plan generation
- Plans are stored in `reactiveVal(fitness_plan)` and persist until regenerated
- PDF download will fail gracefully with user notification if Chrome/Chromium is unavailable

### Shared Notes
- The system prompt emphasizes detailed, evidence-based fitness advice tailored to individual needs
- The user prompt explicitly requires detailed steps without framework-only responses (no "...would follow..." phrases)
- Both apps support development mode (mock data from `mock_plan.md`) and production mode (live API calls)
