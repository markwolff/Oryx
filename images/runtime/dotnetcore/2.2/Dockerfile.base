ARG DOT_NET_CORE_RUNTIME_BASE_TAG
ARG NET_CORE_APP_22
ARG NET_CORE_APP_22_SHA
ARG DOT_NET_CORE_22_SDK_VERSION

# dotnet tools are currently available as part of SDK so we need to create them in an sdk image
# and copy them to our final runtime image
FROM mcr.microsoft.com/dotnet/core/sdk:${DOT_NET_CORE_22_SDK_VERSION} AS tools-install
RUN dotnet tool install --tool-path /dotnetcore-tools dotnet-sos

FROM mcr.microsoft.com/oryx/base:dotnetcore-runtime-stretch${DOT_NET_CORE_RUNTIME_BASE_TAG}

# Configure web servers to bind to port 80 when present
ENV ASPNETCORE_URLS=http://+:80 \
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true

COPY --from=tools-install /dotnetcore-tools /opt/dotnetcore-tools
ENV PATH="/opt/dotnetcore-tools:${PATH}"

# Install ASP.NET Core
ENV ASPNETCORE_VERSION ${NET_CORE_APP_22}

RUN curl -SL --output aspnetcore.tar.gz https://dotnetcli.blob.core.windows.net/dotnet/aspnetcore/Runtime/$ASPNETCORE_VERSION/aspnetcore-runtime-$ASPNETCORE_VERSION-linux-x64.tar.gz \
    && aspnetcore_sha512='${NET_CORE_APP_22_SHA}' \
    && echo "$aspnetcore_sha512  aspnetcore.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -zxf aspnetcore.tar.gz -C /usr/share/dotnet \
    && rm aspnetcore.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

RUN dotnet-sos install
