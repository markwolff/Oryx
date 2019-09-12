# Start declaration of Build-Arg to determine where the image is getting built (DevOps agents or local)
ARG AGENTBUILD
FROM buildpack-deps:stretch AS main
# End declaration of Build-Arg to determine where the image is getting built (DevOps agents or local)

# Configure locale (required for Python)
# NOTE: Do NOT move it from here as it could have global implications
ENV LANG C.UTF-8

# Oryx's path is at the end of the PATH environment variable value and so earlier presence
# of python in the path folders (in this case /usr/bin) will cause Oryx's platform sdk to be not
# picked up.
RUN rm -rf /usr/bin/python*
RUN rm -rf /usr/bin/pydoc*

# Install basic build tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        make \
        unzip \
        # The tools in this package are used when installing packages for Python
        build-essential \
        # Required for Microsoft SQL Server
        unixodbc-dev \
        # Required for PostgreSQL
        libpq-dev \
        # Required for mysqlclient
        default-libmysqlclient-dev \
        # Required for ts
        moreutils \
        rsync \
        zip \
        tk-dev \
        uuid-dev \
    && rm -rf /var/lib/apt/lists/*

# A temporary folder to hold all scripts temporarily used to build this image. 
# This folder is deleted in the final stage of building this image.
RUN mkdir -p /tmp/scripts

RUN mkdir -p /opt/oryx/defaultversions

# Copy PHP versions
COPY images/build/php/prereqs/installPrereqs.sh /tmp/scripts/installPhpPrereqs.sh
RUN chmod +x /tmp/scripts/installPhpPrereqs.sh
RUN /tmp/scripts/installPhpPrereqs.sh

# Install .NET Core
FROM main AS dotnet-install
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu57 \
        liblttng-ust0 \
        libssl1.0.2 \
        libstdc++6 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

COPY build/__dotNetCoreSdkVersions.sh /tmp/scripts
COPY build/__dotNetCoreRunTimeVersions.sh /tmp/scripts
COPY images/build/installDotNetCore.sh /tmp/scripts
RUN chmod +x /tmp/scripts/installDotNetCore.sh

# Check https://www.microsoft.com/net/platform/support-policy for support policy of .NET Core versions
ENV DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
RUN . /tmp/scripts/__dotNetCoreSdkVersions.sh && \
    DOTNET_SDK_VER=$DOT_NET_CORE_21_SDK_VERSION \
    INSTALL_PACKAGES=false \
    /tmp/scripts/installDotNetCore.sh

RUN set -ex \
 && sdksDir=/opt/dotnet \
 && cd $sdksDir \
 && ln -s 2.1 2

RUN set -ex \
 && dotnetDir=/opt/dotnet \
 && sdksDir=$dotnetDir \
 && runtimesDir=$dotnetDir/runtimes \
 && mkdir -p $runtimesDir \
 && cd $runtimesDir \
 && . /tmp/scripts/__dotNetCoreSdkVersions.sh \
 && . /tmp/scripts/__dotNetCoreRunTimeVersions.sh \
 && mkdir $NET_CORE_APP_21 \
 && ln -s $NET_CORE_APP_21 2.1 \
 && ln -s 2.1 2 \
 && ln -s $sdksDir/$DOT_NET_CORE_21_SDK_VERSION $NET_CORE_APP_21/sdk \
 # LTS sdk <-- LTS runtime's sdk
 && ln -s 2.1 lts \
 && ltsSdk=$(readlink lts/sdk) \
 && ln -s $ltsSdk/dotnet /usr/local/bin/dotnet

# This stage is used only when building locally
FROM dotnet-install AS buildscriptbuilder
COPY src/BuildScriptGenerator /usr/oryx/src/BuildScriptGenerator
COPY src/BuildScriptGeneratorCli /usr/oryx/src/BuildScriptGeneratorCli
COPY src/Common /usr/oryx/src/Common
COPY build/FinalPublicKey.snk usr/oryx/build/
COPY src/CommonFiles /usr/oryx/src/CommonFiles
# This statement copies signed oryx binaries from during agent build.
# For local/dev contents of blank/empty directory named binaries are getting copied
COPY binaries /opt/buildscriptgen/
WORKDIR /usr/oryx/src
ARG GIT_COMMIT=unspecified
ARG AGENTBUILD=${AGENTBUILD}
ARG BUILD_NUMBER=unspecified
ENV GIT_COMMIT=${GIT_COMMIT}
ENV BUILD_NUMBER=${BUILD_NUMBER}
RUN if [ -z "$AGENTBUILD" ]; then \
        dotnet publish -r linux-x64 -o /opt/buildscriptgen/ -c Release BuildScriptGeneratorCli/BuildScriptGeneratorCli.csproj; \
    fi
RUN chmod a+x /opt/buildscriptgen/GenerateBuildScript

FROM main AS final
WORKDIR /

ENV PATH=$PATH:/opt/oryx/defaultversions
COPY images/build/benv.sh /opt/oryx/defaultversions/benv
RUN chmod +x /opt/oryx/defaultversions/benv

# Copy .NET Core related content
ENV NUGET_XMLDOC_MODE=skip \
	DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
	NUGET_PACKAGES=/var/nuget

# Grant read-write permissions to the nuget folder so that dotnet restore
# can write into it.
RUN nugetDir="/var/nuget" \
 && mkdir -p "$nugetDir" \
 && chmod a+rw "$nugetDir"

# Build script generator content. Docker doesn't support variables in --from
# so we are building an extra stage to copy binaries from correct build stage
COPY --from=buildscriptbuilder /opt/buildscriptgen/ /opt/buildscriptgen/
RUN ln -s /opt/buildscriptgen/GenerateBuildScript /opt/oryx/defaultversions/oryx

RUN rm -rf /tmp/scripts

ENV ORYX_ENABLE_DYNAMIC_TOOL_INSTALLATION=true
RUN mkdir -p /usr/local/share/pip-cache/lib
RUN chmod -R 777 /usr/local/share/pip-cache

# Bake Application Insights key from pipeline variable into final image
ARG AI_KEY
ENV ORYX_AI_INSTRUMENTATION_KEY=${AI_KEY}

ARG GIT_COMMIT=unspecified
ARG BUILD_NUMBER=unspecified
LABEL com.microsoft.oryx.git-commit=${GIT_COMMIT}
LABEL com.microsoft.oryx.build-number=${BUILD_NUMBER}

ENTRYPOINT [ "benv" ]
