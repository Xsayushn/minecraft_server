# Build Stage: Download High-Performance Server and Tools
FROM eclipse-temurin:21-jre-jammy

# Install required dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    jq \
    ca-certificates \
    nodejs \
    npm \
    rclone \
    bash \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install playit.gg CLI
RUN curl -SsL https://playit-cloud.github.io/ppa/key.gpg | gpg --dearmor | tee /etc/apt/trusted.gpg.d/playit.gpg >/dev/null \
    && echo "deb [signed-by=/etc/apt/trusted.gpg.d/playit.gpg] https://playit-cloud.github.io/ppa/data ./" | tee /etc/apt/sources.list.d/playit-cloud.list \
    && apt-get update \
    && apt-get install -y playit \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /server

# Download Purpur 1.20.4 (Optimized high-performance PaperMC fork)
RUN echo "Downloading Purpur Server..." && \
    curl -sSL -H "User-Agent: Mozilla/5.0" -o /server/server.jar "https://api.purpurmc.org/v2/purpur/1.20.4/latest/download" && \
    ls -lh /server/server.jar

# Copy configurations & scripts
COPY server.properties /server/server.properties
COPY keepalive.js /server/keepalive.js
COPY entrypoint.sh /server/entrypoint.sh

RUN chmod +x /server/entrypoint.sh

# Expose Render Web Service Port (HTTP) and standard Minecraft port
EXPOSE 10000 25565

ENTRYPOINT ["/bin/bash", "/server/entrypoint.sh"]
