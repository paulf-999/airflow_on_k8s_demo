FROM apache/airflow:2.1.1
COPY config/requirements.txt .
RUN pip install -r requirements.txt