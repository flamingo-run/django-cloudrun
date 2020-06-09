FROM python:3.8.1-slim

ENV APP_HOME /app
WORKDIR $APP_HOME

# Install dependencies.
RUN pip install -U pip poetry
RUN poetry config virtualenvs.create false
COPY pyproject.toml .
COPY poetry.lock .
RUN poetry install --no-dev

# Copy local code to the container image.
COPY . .
