FROM nerdylive/stableswarm:dev-b3b948a5c80cd81288457211a7191d16a631241f

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    RCLONE_CONFIG_PATH=/root/.config/rclone/rclone.conf \
    RCLONE_CONF_URL="https://www.dropbox.com/scl/fi/n369g4tty5wg7ngh3ha0r/rclone.conf?rlkey=nw39ft02zs6kokmtu3uuc4527&st=67nc2vqg&dl=1"

# Install rclone and additional dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /root/.config/rclone \
    && mkdir -p /workspace

# Install rclone with version pinning for reproducibility
RUN curl -O https://downloads.rclone.org/v1.65.0/rclone-v1.65.0-linux-amd64.zip \
    && unzip rclone-v1.65.0-linux-amd64.zip \
    && cd rclone-v1.65.0-linux-amd64 \
    && cp rclone /usr/bin/ \
    && chmod 755 /usr/bin/rclone \
    && cd .. \
    && rm -rf rclone-v1.65.0-linux-amd64*

# Copy the startup script
COPY start.sh /
RUN chmod +x /start.sh

WORKDIR /workspace
ENTRYPOINT ["/bin/bash", "/start.sh"]
