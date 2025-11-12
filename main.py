from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
import whisper
import tempfile
from langchain.text_splitter import TokenTextSplitter
from langchain_community.vectorstores import Chroma
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_google_vertexai import VertexAI
from langchain.prompts import PromptTemplate
from langchain.schema.output_parser import StrOutputParser
from langchain_groq import ChatGroq
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="AI Meeting Summary API")

# Cache Whisper model
model = whisper.load_model("base.en")


llm = ChatGroq(
    model='llama-3.1-8b-instant',
    api_key=os.getenv('GROQ_API_KEY')
)

prompt_template = PromptTemplate(
    input_variables=["transcript"],
    template="""
    You are an AI assistant that summarizes meeting transcripts.

    Based on the transcript below, generate:
    - A concise summary (2–4 paragraphs)
    - A bullet-point list of key takeaways or action items.

    Transcript:
    {transcript}
    """
)

@app.post("/summarize-audio")
async def summarize_audio(file: UploadFile = File(...)):
    # Save temp file
    with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as tmp:
        tmp.write(await file.read())
        tmp_path = tmp.name

    # Transcribe
    result = model.transcribe(tmp_path)
    transcript = result["text"]

    # Split if long
    splitter = TokenTextSplitter(chunk_size=500, chunk_overlap=100)
    chunks = splitter.split_text(transcript)

    # Summarize and extract key notes
    combined_summary = ""
    for chunk in chunks:
        prompt = prompt_template.format(transcript=chunk)
        response = llm.invoke(prompt)
        combined_summary += f"\n{response.content}\n"

    # Clean formatting for Flutter display
    # clean_summary = combined_summary.encode('utf-8').decode('unicode_escape').replace("**", "")

    import re

# Clean formatting for Flutter display
    clean_summary = combined_summary
    clean_summary = clean_summary.encode('utf-8').decode('unicode_escape')  # remove escape artifacts
    clean_summary = clean_summary.replace("**", "")                         # remove bold markers
    clean_summary = re.sub(r'[\n\r]+', ' ', clean_summary)                  # remove newlines
    clean_summary = re.sub(r'\s{2,}', ' ', clean_summary).strip()           # remove double spaces

    response = {
        "summary": clean_summary,
        "transcript": transcript,
    }

    return JSONResponse(response)
