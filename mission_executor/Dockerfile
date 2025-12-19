FROM python:3.13-slim


WORKDIR /app

RUN apt-get update && apt-get install -y bash coreutils  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /shared

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY agent_main.py /app/agent_main.py

RUN chmod +x  /app/agent_main.py

ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

CMD ["python3", "/app/agent_main.py"]
