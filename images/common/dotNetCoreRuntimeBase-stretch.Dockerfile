FROM oryxmcr.azurecr.io/public/oryx/base:runtime-stretch

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        \
# .NET Core dependencies
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu57 \
        liblttng-ust0 \
        libssl1.0.2 \
        libstdc++6 \
        zlib1g \
        lldb \
        curl \
        file \
    && rm -rf /var/lib/apt/lists/*