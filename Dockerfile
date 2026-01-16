# Basic container
# Example usage: 
#   docker run -d --name mctomqtt \
#     -v ./config/.env.local:/opt/.env.local \
#     --device=/dev/ttyACM0 \
#     meshcoretomqtt:latest


FROM python:3.11-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive

WORKDIR /opt

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libstdc++6 \
    && pip3 install pyserial paho-mqtt --no-cache-dir \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js via nvm and meshcore-decoder for auth token support
ENV NVM_DIR=/root/.nvm
ENV NODE_VERSION=lts/*

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install $NODE_VERSION \
    && nvm use $NODE_VERSION \
    && npm install -g @michaelhart/meshcore-decoder \
    && ln -s "$NVM_DIR/versions/node/$(ls $NVM_DIR/versions/node | head -1)/bin/"* /usr/local/bin/

# Copy application files
COPY ./mctomqtt.py /opt/
COPY ./auth_token.py /opt/
COPY ./.env /opt/

# Note: .env.local should be mounted as a volume with your configuration
# The .env file contains defaults, .env.local contains your overrides
# Example: -v /path/to/.env.local:/opt/.env.local

CMD ["python3", "/opt/mctomqtt.py"]
