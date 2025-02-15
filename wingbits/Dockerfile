FROM debian:bookworm-slim

#Automatic args
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

ENV WINGBITS_PATH="/usr/local/bin"
ENV WINGBITS_VERSION_PATH="/etc/wingbits"

RUN echo "Building for platform: $TARGETPLATFORM ($TARGETOS-$TARGETARCH)"


RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y --no-install-recommends \
        apt-transport-https \
        apt-utils \
        autoconf \
        build-essential \
        ca-certificates \
        curl \
        debhelper \
        gzip \
        iputils-ping \
        jq \
        software-properties-common \
        ssh \
        wget

RUN apt-get install -y --no-install-recommends \
    gcc \
    gettext-base \
    git \
    gnupg \
    libffi-dev \
    libusb-1.0-0-dev  \
    libzstd-dev \
    make \
    ncurses-dev \
    pkg-config \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    tini \
    zlib1g \
    zlib1g-dev \
&& apt-get autoclean && apt-get autoremove --yes && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*
RUN mkdir -p $WINGBITS_VERSION_PATH
# Fetch and store the version information
RUN VERSION_URL="https://gitlab.com/wingbits/config/-/raw/master/download.sh" && \
    curl -s --retry 5 --retry-connrefused --retry-delay 3 "$VERSION_URL" | grep -oP '(?<=WINGBITS_CONFIG_VERSION=")[^"]*' > $WINGBITS_VERSION_PATH/version
# Fetch and store the commit information
RUN COMMIT_ID_URL="https://install.wingbits.com/$TARGETOS-$TARGETARCH.json" && \
    curl -s --retry 5 --retry-connrefused --retry-delay 3 "$COMMIT_ID_URL" | grep -o '"Version": "[^"]*"' | cut -d'"' -f4 > $WINGBITS_VERSION_PATH/json-version
# Fetch and install the Wingbits executable
RUN set -e && COMMIT_ID=$(cat $WINGBITS_VERSION_PATH/json-version) && \
    [ -z "$COMMIT_ID" ] && echo "Failed to fetch the commit ID" && exit 1 || echo "Commit ID: $COMMIT_ID" && \
    EXECUTABLE_URL="https://install.wingbits.com/$COMMIT_ID/$TARGETOS-$TARGETARCH.gz" && \
    curl -s --retry 5 --retry-connrefused --retry-delay 3 "$EXECUTABLE_URL" -o $WINGBITS_PATH/wingbits.gz && \
    [ -s "$WINGBITS_PATH/wingbits.gz" ] && \
    gunzip $WINGBITS_PATH/wingbits.gz && \
    chmod +x $WINGBITS_PATH/wingbits && \
    rm -f $WINGBITS_PATH/wingbits.gz

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --upgrade pip

COPY start.sh /
RUN chmod +x /start.sh

COPY healthcheck.sh /
RUN chmod +x /healthcheck.sh

HEALTHCHECK --interval=5s --timeout=1s --start-period=10s --retries=3 CMD /healthcheck.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/start.sh"]