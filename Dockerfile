FROM python:3.13-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN mkdir /data && chown 10001:10001 /data

COPY app.py .

USER 10001:10001

EXPOSE 8000


CMD ["python", "-u", "app.py"]
