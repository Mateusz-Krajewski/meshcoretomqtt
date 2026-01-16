# Basic container
# Example usage: 
#   docker run -d --name mctomqtt \
#     -v ./config/.env.local:/opt/.env.local \
#     --device=/dev/ttyACM0 \
#     meshcoretomqtt:latest

# --- Etap 1: Builder ---
FROM node:20-slim AS node-builder
RUN npm install -g @michaelhart/meshcore-decoder

# --- Etap 2: Finalny obraz ---
FROM python:3.11-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive

WORKDIR /opt

# 1. Kopiujemy Node.js i moduły
COPY --from=node-builder /usr/local/bin/node /usr/local/bin/node
COPY --from=node-builder /usr/local/lib/node_modules /usr/local/lib/node_modules

# 2. Tworzymy wrapper script, który uruchamia CLI z właściwego katalogu roboczego
RUN echo '#!/bin/sh\ncd /usr/local/lib/node_modules/@michaelhart/meshcore-decoder && exec node dist/cli.js "$@"' > /usr/local/bin/meshcore-decoder && \
    chmod +x /usr/local/bin/meshcore-decoder

# 3. Instalujemy zależności systemowe i Pythona
RUN apt-get update && apt-get install -y --no-install-recommends \
    libstdc++6 \
    && pip install --no-cache-dir pyserial paho-mqtt \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/*

# 4. Kopiujemy pliki aplikacji
COPY ./mctomqtt.py ./auth_token.py ./.env /opt/

# Weryfikacja: Sprawdzamy czy dekoder działa przed zakończeniem budowania
RUN /usr/local/bin/meshcore-decoder --version

CMD ["python3", "mctomqtt.py"]