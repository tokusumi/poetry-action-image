# Creating a python base with shared environment variables
FROM python:3.7-buster as python-base
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    GITHUB_ACTION_PATH="/opt/github_action" \
    VENV_PATH="/opt/github_action/.venv"

ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"


# builder-base is used to build dependencies
FROM python-base as builder-base
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        curl \
        build-essential

# Install Poetry - respects $POETRY_VERSION & $POETRY_HOME
ENV POETRY_VERSION=1.0.0
RUN curl -sSL https://raw.githubusercontent.com/sdispater/poetry/master/get-poetry.py | python

# We copy our Python requirements here to cache them
# and install only runtime deps using poetry
RUN poetry new $GITHUB_ACTION_PATH
WORKDIR $GITHUB_ACTION_PATH
RUN poetry install


# Copying poetry and venv into image
FROM python-base as actions
COPY --from=builder-base $POETRY_HOME $POETRY_HOME
COPY --from=builder-base $GITHUB_ACTION_PATH $GITHUB_ACTION_PATH

# venv already has runtime deps installed we get a quicker install
WORKDIR $GITHUB_ACTION_PATH
