# Build Stage: Download PaperMC and Tools
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

# Download latest stable PaperMC jar for 1.20.4 or 1.20.6 (1.20.4 is optimal for low memory)
ARG MC_VERSION=1.20.4
RUN PROJECT="paper" && \
    VERSION=${MC_VERSION} && \
    BUILDS_URL="https://api.papermc.io/v2/projects/${PROJECT}/versions/${VERSION}/builds" && \
    BUILD=$(curl -s $BUILDS_URL | jq '.builds[-1].build') && \
    JAR_NAME="${PROJECT}-${VERSION}-${BUILD}.jar" && \
    DOWNLOAD_URL="https://api.papermc.io/v2/projects/${PROJECT}/versions/${VERSION}/builds/${BUILD}/downloads/${JAR_NAME}" && \
    echo "Downloading PaperMC from $DOWNLOAD_URL" && \
    curl -o /server/server.jar $DOWNLOAD_URL

# Copy configurations & scripts
COPY server.properties /server/server.properties
COPY keepalive.js /server/keepalive.js
COPY entrypoint.sh /server/entrypoint.sh

RUN chmod +x /server/entrypoint.sh

# Expose Render Web Service Port (HTTP) and standard Minecraft port
EXPOSE 10000 25565

ENTRYPOINT ["/bin/bash", "/server/entrypoint.sh"]
