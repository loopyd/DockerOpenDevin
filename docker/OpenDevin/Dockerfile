FROM debian:bookworm AS localhost:5000/opendevin

ARG APP_USER
ARG APP_USER_HOME
ARG LANG
ARG TZ
ARG PYENV_ROOT
ARG NVM_DIR
ARG NVM_VERSION
ARG GOSU_VERSION
ARG PYTHON_VERSION
ARG CARGO_DIR
ARG RUSTUP_DIR
ARG APP_DIR

ENV APP_USER ${APP_USER:-appuser}
ENV APP_USER_HOME ${APP_USER_HOME:-/home/${APP_USER}}
ENV APP_DIR ${APP_DIR:-/app}
ENV LANG ${LANG:-en_US.UTF-8}
ENV TZ ${TZ:-America/Los_Angeles}
ENV PYENV_ROOT ${PYENV_ROOT:-/usr/local/pyenv}
ENV NVM_DIR ${NVM_DIR:-/usr/local/nvm}
ENV NVM_VERSION ${NVM_VERSION:-0.39.7}
ENV GOSU_VERSION ${GOSU_VERSION:-1.16}
ENV PYTHON_VERSION ${PYTHON_VERSION:-3.11.7}
ENV CARGO_DIR ${CARGO_DIR:-/usr/local/rust/cargo}
ENV RUSTUP_DIR ${RUSTUP_DIR:-/usr/local/rust/multirust}
ENV DEBIAN_FRONTEND noninteractive

# Generate locale
RUN set -eux; \
	if [ -f /etc/dpkg/dpkg.cfg.d/docker ]; then \
		grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker; \
		sed -ri '/\/usr\/share\/locale/d' /etc/dpkg/dpkg.cfg.d/docker; \
		! grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker; \
	fi ;\
	apt-get update ;\
    apt-get install -qqy --no-install-recommends \
        locales ;\
    rm -rf /var/lib/apt/lists/* ;\
    echo "$LANG "$(echo $LANG | awk -F'.' '{print $2}') > /etc/locale.gen; \
	locale-gen; \
    locale -a

# Set timezone
RUN set -eux; \
    apt-get update; \
    apt-get install -qqy --no-install-recommends \
        tzdata; \
    rm -rf /var/lib/apt/lists/*; \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime; \
    echo $TZ > /etc/timezone; \
    dpkg-reconfigure -f noninteractive tzdata

# Install gosu
RUN set -eux; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -qqy --no-install-recommends \
        ca-certificates \
        wget \
        gnupg \
        less; \
	rm -rf /var/lib/apt/lists/*; \
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
	chmod +x /usr/local/bin/gosu; \
	gosu --version; \
	gosu nobody true

# Install build dependencies
RUN apt-get update -qqy && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qqy --no-install-recommends \
        apt-transport-https \
        apt-utils \
        autoconf \
        automake \
        bison \
        build-essential \
        bzip2 \
        ca-certificates \
        ccache \
        clang \
        clang-format \
        clang-tidy \
        clang-tools \
        cmake \
        curl \
        default-jdk \
        flex \
        gcc \
        gettext \
        g++ \
        git \
        gfortran \
        gnupg \
        gzip \
        libaio-dev \
        libblas-dev \
        libboost-all-dev \
        libbz2-dev \
        libc6-dev \
        libcap-dev \
        libcrypto++-dev \
        libclang-cpp-dev \
        libcurl4-openssl-dev \
        libedit-dev \
        libevent-dev \
        libffi-dev \
        libglib2.0-dev \
        libglib2.0-dev-bin \
        libicu-dev \
        libjpeg-turbo*-dev \
        libjudy-dev \
        libkrb5-dev \
        liblapack-dev \
        libldap2-dev \
        libldap-dev \
        liblz4-dev \
        liblzma-dev \
        libmecab-dev \
        libmecab2 \
        libncurses-dev \
        libncurses5-dev \
        libncursesw5-dev \
        libnss-wrapper \
        libpam0g-dev \
        libpcre2-dev \
        libperl-dev \
        libpng-dev \
        libpq-dev \
        libpmem-dev \
        libpython3-dev \
        libreadline-dev \
        libselinux1-dev \
        libsnappy-dev \
        libsqlite3-dev \
        libssl-dev \
        libsystemd-dev \
        libtcmalloc-minimal* \
        libtcl-perl \
        libtool \
        libxml2-dev \
        libxmlsec1-dev \
        libzstd-dev \
        llvm \
        make \
        meson \
        nasm \
        ninja-build \
        openssl \
        pkg-config \
        software-properties-common \
        sudo \
        swig \
        tcl-dev \
        tcllib \
        tar \
        tk-dev \
        uuid-dev \
        valgrind \
        wget \
        xz-utils \
        zlib1g-dev && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# Setup user
RUN adduser --disabled-password --gecos '' --shell /bin/bash --home ${APP_USER_HOME} ${APP_USER} ;\
    usermod -aG sudo ${APP_USER}; \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers; \
    mkdir -p ${APP_DIR}; \
    chown -R ${APP_USER}:${APP_USER} ${APP_DIR}; \
    chmod -R 1755 ${APP_DIR}

# Setup NodeJS
USER root
RUN groupadd node; \
    mkdir -p $NVM_DIR; \
    chown -R root:node $NVM_DIR; \
    chmod -R 1775 $NVM_DIR; \
    usermod -aG node ${APP_USER}
USER ${APP_USER}
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v${NVM_VERSION}/install.sh | bash

# Setup yarn
# USER root
# RUN tarball_tmp=`mktemp -t yarn.tzar.gz.XXXXXXXXXX`; \
#     if curl --fail -L -o "$tarball_tmp" "https://yarnpkg.com/downloads/${YARN_VERSION}/yarn-v${YARN_VERSION}.tar.gz"; then \
#         temp=$(mktemp -d yarn.XXXXXXXXXX); \
#         tar zxf $tarball_tmp -C "$temp"; \
#         mkdir -p $YARN_DIR; \
#         chown -R root:node $YARN_DIR; \
#         chmod -R 1775 $YARN_DIR; \
#         mv "$temp"/*/* $YARN_DIR; \
#         rm -rf "$temp"; \
#         rm $tarball_tmp* ; \
#     else \
#         exit 1; \
#     fi
# USER ${APP_USER}
# ENV PATH $YARN_DIR/bin:/home/${APP_USER}/.config/yarn/global/node_modules/.bin:$PATH

# Setup pyenv
USER root
RUN mkdir -p $PYENV_ROOT; \
    groupadd python; \
    chown -R root:python $PYENV_ROOT; \
    chmod -R 1775 $PYENV_ROOT; \
    usermod -aG python ${APP_USER}
USER ${APP_USER}
WORKDIR ${APP_USER_HOME}
RUN git clone --depth=1 https://github.com/pyenv/pyenv.git /usr/local/pyenv
ENV PATH ${PYENV_ROOT}/shims:${PYENV_ROOT}/bin:$PATH
RUN pyenv install $PYTHON_VERSION; \
    pyenv global $PYTHON_VERSION

# Setup rust
USER root
RUN mkdir -p $CARGO_DIR \
             $RUSTUP_DIR ;\
    groupadd rust; \
    chown -R root:rust $CARGO_DIR \
                       $RUSTUP_DIR; \
    chmod -R 1775 $CARGO_DIR \
                  $RUSTUP_DIR; \
    usermod -aG rust ${APP_USER}
USER ${APP_USER}
ENV CARGO_HOME $CARGO_DIR
ENV RUSTUP_HOME $RUSTUP_DIR
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH $CARGO_DIR/bin:$PATH

# Install docker
USER root
RUN apt-get update -qqy && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qqy --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update -qqy && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qqy --no-install-recommends \
        docker-ce && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*; \
    groupadd docker; \
    usermod -aG docker ${APP_USER}; \
    service docker start; \
    docker --version