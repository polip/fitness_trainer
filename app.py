import streamlit as st
import os
from datetime import datetime
from dotenv import load_dotenv
import markdown
from io import BytesIO
from weasyprint import HTML

# Load environment variables
load_dotenv()

# Page configuration
st.set_page_config(
    page_title="AI Fitness Plan Generator",
    page_icon="💪",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS for better styling
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        font-weight: bold;
        color: #333;
        text-align: center;
        margin-bottom: 2rem;
    }
    .stButton>button {
        width: 100%;
        background-color: #0066cc;
        color: white;
        font-weight: bold;
        padding: 0.75rem;
        border-radius: 8px;
    }
    .stButton>button:hover {
        background-color: #0052a3;
    }
    .fitness-plan {
        background-color: #f8f9fa;
        padding: 2rem;
        border-radius: 10px;
        margin-top: 1rem;
    }
</style>
""", unsafe_allow_html=True)

# Initialize session state
if 'fitness_plan' not in st.session_state:
    st.session_state.fitness_plan = ""
if 'is_generating' not in st.session_state:
    st.session_state.is_generating = False
if 'session_requests' not in st.session_state:
    st.session_state.session_requests = 0

MAX_REQUESTS_PER_SESSION = 3

# Sidebar - User Inputs
with st.sidebar:
    st.header("🏋️ Fitness Profile")

    # Personal Information
    with st.expander("Personal Information", expanded=True):
        gender = st.selectbox("Gender", options=["Male", "Female"])
        age = st.slider("Age", min_value=14, max_value=85, value=47)
        weight = st.slider("Weight (kg)", min_value=30, max_value=180, value=99)
        height = st.slider("Height (cm)", min_value=100, max_value=225, value=189)

    # Fitness Goals
    with st.expander("Fitness Goals", expanded=True):
        training_type = st.selectbox(
            "Type of Training",
            options=["Strength", "Hypertrophy", "Weight Loss", "Endurance",
                    "High intensity interval training", "Functional", "General Fitness"]
        )
        experience = st.selectbox(
            "Experience Level",
            options=["Beginner", "Intermediate", "Advanced"]
        )
        frequency = st.selectbox(
            "Training Frequency",
            options=["2-3 days/week", "3-4 days/week", "4-5 days/week", "5+ days/week"]
        )
        goals = st.text_area(
            "Specific Goals (optional)",
            placeholder="e.g., Run a 5K, Build bigger arms, Improve posture..."
        )

    # Health Considerations
    with st.expander("Health Considerations", expanded=True):
        limitations = st.text_area(
            "Injuries or Limitations (if any)",
            placeholder="e.g., Bad knees, Lower back pain..."
        )
        equipment = st.selectbox(
            "Available Equipment",
            options=["Full Gym", "Home Gym Basics", "Minimal/Bodyweight Only"]
        )

    st.divider()

    # AI Provider Selection
    st.subheader("🤖 AI Provider")
    ai_provider = st.selectbox(
        "Select AI Provider",
        options=["Anthropic (Claude)", "OpenAI (GPT)", "Google (Gemini)"],
        index=0
    )

    # API Key Input
    if ai_provider == "Anthropic (Claude)":
        api_key_default = os.getenv("ANTHROPIC_API_KEY", "")
        api_key = st.text_input(
            "Anthropic API Key",
            value=api_key_default,
            type="password",
            placeholder="sk-ant-..."
        )
    elif ai_provider == "OpenAI (GPT)":
        api_key_default = os.getenv("OPENAI_API_KEY", "")
        api_key = st.text_input(
            "OpenAI API Key",
            value=api_key_default,
            type="password",
            placeholder="sk-..."
        )
    else:  # Google Gemini
        api_key_default = os.getenv("GOOGLE_API_KEY", "")
        api_key = st.text_input(
            "Google API Key",
            value=api_key_default,
            type="password",
            placeholder="Enter your Google API key..."
        )

    st.divider()

    # Generate Button
    generate_button = st.button("🚀 Generate Fitness Plan", type="primary", use_container_width=True)


# Helper function to call AI providers
def generate_fitness_plan(user_profile, system_prompt, user_prompt, provider, api_key):
    """Generate fitness plan using selected AI provider"""

    # Check for development mode
    app_mode = os.getenv("APP_MODE", "development")

    if app_mode == "development":
        # Return mock data
        import time
        time.sleep(1)
        try:
            with open("mock_plan.md", "r") as f:
                return f.read()
        except FileNotFoundError:
            return "Error: mock_plan.md not found. Please create it or switch to production mode."

    # Production mode - call actual API
    try:
        if provider == "Anthropic (Claude)":
            from anthropic import Anthropic
            client = Anthropic(api_key=api_key)
            response = client.messages.create(
                model="claude-sonnet-4.5",
                max_tokens=8000,
                system=system_prompt,
                messages=[{"role": "user", "content": user_prompt}]
            )
            return response.content[0].text

        elif provider == "OpenAI (GPT)":
            from openai import OpenAI
            client = OpenAI(api_key=api_key)
            response = client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ]
            )
            return response.choices[0].message.content

        elif provider == "Google (Gemini)":
            import google.generativeai as genai
            genai.configure(api_key=api_key)
            model = genai.GenerativeModel(
                model_name='gemini-2.0-flash-exp',
                system_instruction=system_prompt
            )
            response = model.generate_content(user_prompt)
            return response.text

    except Exception as e:
        return f"Error generating fitness plan: {str(e)}\n\nPlease check your API key and try again."


# Helper function to convert markdown to PDF
def create_pdf(markdown_text):
    """Convert markdown text to PDF"""
    # Convert markdown to HTML
    html_content = markdown.markdown(markdown_text, extensions=['tables', 'fenced_code'])

    # Add CSS styling
    styled_html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Your Fitness Plan</title>
        <style>
            body {{
                font-family: Arial, sans-serif;
                line-height: 1.6;
                margin: 40px;
                max-width: 800px;
            }}
            h1, h2, h3 {{
                color: #333;
                margin-top: 30px;
            }}
            h1 {{
                text-align: center;
                border-bottom: 2px solid #333;
                padding-bottom: 10px;
            }}
            table {{
                border-collapse: collapse;
                width: 100%;
                margin: 20px 0;
            }}
            th, td {{
                border: 1px solid #ddd;
                padding: 12px;
                text-align: left;
            }}
            th {{
                background-color: #f2f2f2;
            }}
        </style>
    </head>
    <body>
        <h1>Your Fitness Plan</h1>
        {html_content}
    </body>
    </html>
    """

    # Convert HTML to PDF
    pdf_file = BytesIO()
    HTML(string=styled_html).write_pdf(pdf_file)
    pdf_file.seek(0)
    return pdf_file


# Main content area
st.markdown('<div class="main-header">AI Fitness Plan Generator</div>', unsafe_allow_html=True)

# Generate fitness plan when button is clicked
if generate_button:
    if not api_key:
        st.error("⚠️ Please enter an API key for the selected AI provider.")
    else:
        st.session_state.is_generating = True
        st.session_state.fitness_plan = ""

        # Create user profile
        user_profile = {
            "age": age,
            "gender": gender,
            "weight": weight,
            "height": height,
            "training_type": training_type,
            "experience": experience,
            "frequency": frequency,
            "goals": goals if goals else "General fitness improvement",
            "limitations": limitations if limitations else "None",
            "equipment": equipment
        }

        # System prompt
        system_prompt = """You are a professional fitness trainer and nutrition specialist with expertise in creating personalized workout plans. You provide detailed, evidence-based fitness advice tailored to individual needs and goals. Your recommendations are practical, safe, and effective for people of all fitness levels."""

        # User prompt
        user_prompt = f"""Create a detailed 1-week fitness plan for {user_profile['age']} years old {user_profile['gender']},
weighing {user_profile['weight']}kg and {user_profile['height']}cm tall. Each daily workout should contain at least 6 exercises.

Training type: {user_profile['training_type']}
Experience level: {user_profile['experience']}
Training frequency: {user_profile['frequency']}
Specific goals: {user_profile['goals']}
Limitations/injuries: {user_profile['limitations']}
Available equipment: {user_profile['equipment']}

The plan should include:
1. Initial assessment of fitness. Also provide expected ranges for initial assessment workouts depending on age, sex, weight.
2. A weekly workout schedule
3. Detailed exercises for each workout day from weekly plan.
4. Sets, reps, rest periods, RPM
5. Instructions for each exercise
6. Detailed nutrition recommendations
7. Recovery tips

Format the response in markdown with clear headings and sections. Don't use emojis, just plain text or links. Write all steps detaily, don't use ...would follow... or similar phrases. Don't write framework, but complete detailed guide"""

        # Show loading spinner
        with st.spinner("🔄 Generating your personalized fitness plan..."):
            plan_result = generate_fitness_plan(
                user_profile,
                system_prompt,
                user_prompt,
                ai_provider,
                api_key
            )

        st.session_state.fitness_plan = plan_result
        st.session_state.is_generating = False
        st.session_state.session_requests += 1
        st.rerun()

# Display fitness plan
if st.session_state.fitness_plan:
    st.markdown('<div class="fitness-plan">', unsafe_allow_html=True)
    st.markdown(st.session_state.fitness_plan)
    st.markdown('</div>', unsafe_allow_html=True)

    # Download PDF button
    try:
        pdf_file = create_pdf(st.session_state.fitness_plan)
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        st.download_button(
            label="📥 Download Plan as PDF",
            data=pdf_file,
            file_name=f"fitness-plan-{timestamp}.pdf",
            mime="application/pdf",
            use_container_width=True
        )
    except Exception as e:
        st.warning(f"⚠️ PDF generation failed: {str(e)}. You can still copy the plan text above.")

elif not st.session_state.is_generating:
    st.info("👈 Enter your information in the sidebar and click 'Generate Fitness Plan' to get started.")
