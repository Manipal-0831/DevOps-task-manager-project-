from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import boto3, os, uuid

from prometheus_fastapi_instrumentator import Instrumentator


AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID", "test")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY", "test")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
S3_BUCKET = os.getenv("S3_BUCKET", "uploads")
LOCALSTACK_URL = os.getenv("LOCALSTACK_URL", "http://localstack:4566")  # points to Service in k8s / container name in compose

session = boto3.session.Session(
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
    region_name=AWS_REGION,
)
s3 = session.client("s3", endpoint_url=f"{LOCALSTACK_URL}")

app = FastAPI(title="FastAPI + S3 (LocalStack)")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/files")
def list_files():
    resp = s3.list_objects_v2(Bucket=S3_BUCKET)
    files = []
    for obj in resp.get("Contents", []):
        files.append({"key": obj["Key"], "size": obj["Size"]})
    return {"bucket": S3_BUCKET, "files": files}

@app.post("/upload")
async def upload(file: UploadFile = File(...)):
    key = f"{uuid.uuid4()}_{file.filename}"
    data = await file.read()
    s3.put_object(Bucket=S3_BUCKET, Key=key, Body=data, ContentType=file.content_type)
    return {"uploaded": key}
#  ADD THIS AT THE END
Instrumentator().instrument(app).expose(app)
