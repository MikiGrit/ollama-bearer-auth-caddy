# Stage 1: Base Image with ollama
FROM docker.io/ollama/ollama:0.6.3 as base

# Ensure the uv installed binary is on the `PATH`
ENV PATH="/root/.local/bin/:$PATH"

# Install dependencies
RUN apt-get update && \
    apt-get install -y wget jq curl && \
    apt-get clean

# Install Python and its libraries
ADD https://astral.sh/uv/install.sh /uv-installer.sh
RUN sh /uv-installer.sh && rm /uv-installer.sh
RUN uv tool install --with fastapi uvicorn

# Stage 2: Build Caddy with Plugin
FROM docker.io/library/caddy:2.8.4-builder AS caddy-builder

RUN xcaddy build

# Stage 3: Final Image
FROM base

# Copy Caddy binary from the 'caddy-builder' stage
COPY --from=caddy-builder /usr/bin/caddy /usr/bin/caddy

# Copy configuration files
COPY Caddy/Caddyfile /etc/caddy/Caddyfile
COPY Caddy/valid_keys.conf /etc/caddy/valid_keys.conf

ENV OLLAMA_HOST=0.0.0.0 

# Expose the port
EXPOSE 8081

# Copy the startup script
COPY start_services.sh /start_services.sh
RUN chmod +x /start_services.sh

# Copy Uvicorn FastAPI application files for key validation
COPY app /app

# Entrypoint
ENTRYPOINT ["/start_services.sh"] 
