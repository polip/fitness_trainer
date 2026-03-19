# AI Fitness Plan Generator

A personalized fitness plan generator powered by AI (Anthropic Claude, OpenAI GPT, or Google Gemini). Available in both Python/Streamlit and R/Shiny versions.

## Features

- <Ë Personalized workout plans based on your profile
- > Multiple AI provider support (Claude, GPT, Gemini)
- =Ê Detailed exercise plans with sets, reps, and rest periods
- >W Nutrition recommendations
- =¤ Recovery strategies
- =å Download plans as PDF

## Quick Start with Docker

### Using Docker Compose (Recommended)

```bash
# Development mode (uses mock data, no API key needed)
docker-compose up

# Production mode (requires API keys)
export APP_MODE=production
export ANTHROPIC_API_KEY=your-key-here
# or OPENAI_API_KEY or GOOGLE_API_KEY
docker-compose up
```

Access the app at: http://localhost:8501

### Using Docker

```bash
# Build the image
docker build -t fitness-trainer .

# Run in development mode
docker run -p 8501:8501 -e APP_MODE=development fitness-trainer

# Run in production mode
docker run -p 8501:8501 \
  -e APP_MODE=production \
  -e ANTHROPIC_API_KEY=your-key-here \
  fitness-trainer
```

## Local Development

### Python/Streamlit (Recommended)

```bash
# Install dependencies
pip install -r requirements.txt

# Setup environment
cp .env.example .env
# Edit .env with your API keys

# Run the app
streamlit run app.py
```

### R/Shiny (Legacy)

```r
# Install dependencies
install.packages(c("shiny", "bslib", "tidyverse", "ellmer", "pagedown"))

# Run the app
shiny::runApp("app.R")
```

## Configuration

### Environment Variables

- `APP_MODE`: Set to `development` (mock data) or `production` (live API)
- `ANTHROPIC_API_KEY`: Your Anthropic API key (optional)
- `OPENAI_API_KEY`: Your OpenAI API key (optional)
- `GOOGLE_API_KEY`: Your Google API key (optional)

API keys can also be entered directly in the app UI.

## Docker Commands

```bash
# Build
docker build -t fitness-trainer .

# Run
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down

# Rebuild
docker-compose up --build
```

## Technology Stack

### Python/Streamlit
- Streamlit - Web framework
- Anthropic, OpenAI, Google SDKs - AI integration
- WeasyPrint - PDF generation
- Python-dotenv - Environment management

### R/Shiny (Legacy)
- Shiny - Web framework
- ellmer - LLM integration
- pagedown - PDF generation

## License

MIT
