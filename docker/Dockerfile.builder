FROM debian:bookworm-slim AS opendevin-builder

ARG APP_USER
ARG APP_USER_HOME
ARG APP_DIR
ARG LANG
ARG TZ
ARG GOSU_VERSION
ARG PYENV_ROOT
ARG NVM_DIR
ARG CARGO_HOME
ARG RUSTUP_HOME
ARG POETRY_HOME

# Base App Environment
ENV APP_USER ${APP_USER:-appuser}
ENV APP_USER_HOME ${APP_USER_HOME:-/home/${APP_USER}}
ENV APP_DIR ${APP_DIR:-/app}
ENV LANG ${LANG:-en_US.UTF-8}
ENV TZ ${TZ:-America/Los_Angeles}
ENV DEBIAN_FRONTEND noninteractive

# Versions
ENV GOSU_VERSION ${GOSU_VERSION:-1.16}

# Compiler Toolchain directories
ENV PYENV_ROOT ${PYENV_ROOT:-/opt/toolchain/pyenv}
ENV NVM_DIR ${NVM_DIR:-/opt/toolchain/nvm}
ENV CARGO_HOME ${CARGO_HOME:-/opt/toolchain/rust/cargo}
ENV RUSTUP_HOME ${RUSTUP_HOME:-/opt/toolchain/rust/multirust}
ENV POETRY_HOME ${POETRY_HOME:-/opt/toolchain/poetry}

# Setup locales
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

# Setup timezone
RUN set -eux; \
    apt-get update; \
    apt-get install -qqy --no-install-recommends \
        tzdata; \
    rm -rf /var/lib/apt/lists/*; \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime; \
    echo $TZ > /etc/timezone; \
    dpkg-reconfigure -f noninteractive tzdata

# Setup gosu
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
RUN set -eux; \
    apt-get update -qqy && \
    apt-get install -qqy --no-install-recommends \
        apt-transport-https \
        apt-utils \
        autoconf \
        automake \
        bison \
        build-essential \
        bzip2 \
        ccache \
        clang \
        clang-format \
        clang-tidy \
        clang-tools \
        cmake \
        curl \
        flex \
        gcc \
        gettext \
        g++ \
        git \
        gfortran \
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
        lsb-release \
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
        xz-utils \
        zlib1g-dev && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# Setup user
RUN set -eux; \
    adduser --disabled-password --gecos '' --shell /bin/bash --home ${APP_USER_HOME} ${APP_USER} ;\
    usermod -aG sudo ${APP_USER}; \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers; \
    mkdir -p ${APP_DIR}; \
    chown -R ${APP_USER}:${APP_USER} ${APP_DIR}; \
    chmod -R 1775 ${APP_DIR}

# Setup Node.js
RUN set -eux; \
    groupadd node; \
    mkdir -p $NVM_DIR; \
    git clone https://github.com/nvm-sh/nvm.git $NVM_DIR; \
    cd "$NVM_DIR"; \
    git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`; \
    chown -R root:node $NVM_DIR; \
    chmod -R 1775 $NVM_DIR; \
    usermod -aG node ${APP_USER}; \
    echo "### >>> nvm >>>" | tee -a ${APP_USER_HOME}/.bashrc; \
    echo "export NVM_DIR=$NVM_DIR" | tee -a ${APP_USER_HOME}/.bashrc; \
    echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"" | tee -a ${APP_USER_HOME}/.bashrc; \
    echo "[ -s \"\$NVM_DIR/bash_completion\" ] && . \"\$NVM_DIR/bash_completion\"" | tee -a ${APP_USER_HOME}/.bashrc; \
    echo "### <<< nvm <<<" | tee -a ${APP_USER_HOME}/.bashrc

# Setup pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH
RUN set -eux; \
    mkdir -p $PYENV_ROOT; \
    groupadd python; \
    git clone --depth=1 https://github.com/pyenv/pyenv.git $PYENV_ROOT; \
    chmod +x $PYENV_ROOT/src/configure; \
    cd $PYENV_ROOT; \
    ./src/configure; \
    make -C ./src; \
    chown -R root:python $PYENV_ROOT; \
    chmod -R 1775 $PYENV_ROOT; \
    usermod -aG python ${APP_USER}; \
    echo "### >>> pyenv >>>" | tee -a ${APP_USER_HOME}/.bashrc; \
    echo "export PYENV_ROOT=$PYENV_ROOT" | tee -a ${APP_USER_HOME}/.bashrc; \
    echo "export PATH=\$PYENV_ROOT/shims:\$PYENV_ROOT/bin:\$PATH" | tee -a ${APP_USER_HOME}/.bashrc; \
    echo "eval \"\$(pyenv init -)\"" | tee -a ${APP_USER_HOME}/.bashrc; \
    echo "### <<< pyenv <<<" | tee -a ${APP_USER_HOME}/.bashrc

# Install Python Base and Poetry
ENV PATH $POETRY_HOME/bin:$PATH
RUN set -eux; \
    mkdir -p ${POETRY_HOME}; \
    chown -R root:python ${POETRY_HOME}; \
    chmod -R 1775 ${POETRY_HOME}; \
    pyenv install 3.11.7; \
    pyenv global 3.11.7; \
    curl -sSL https://install.python-poetry.org | python -; \
    chown -R root:python ${POETRY_HOME}; \
    chmod -R 1775 ${POETRY_HOME}; \
    chown -R root:python ${PYENV_ROOT}; \
    chmod -R 1775 ${PYENV_ROOT}; \
    echo "# >>> poetry >>>" | tee -a $APP_USER_HOME/.bashrc; \
    echo "export POETRY_HOME=$POETRY_HOME" | tee -a $APP_USER_HOME/.bashrc; \
    echo "export PATH=\$POETRY_HOME/bin:\$PATH" | tee -a $APP_USER_HOME/.bashrc; \
    echo "# <<< poetry <<<" | tee -a $APP_USER_HOME/.bashrc

# Setup rust
ENV PATH $CARGO_DIR/bin:$PATH
RUN set -eux; \ 
    mkdir -p $CARGO_HOME \
             $RUSTUP_HOME ;\
    groupadd rust; \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; \
    chown -R root:rust $CARGO_HOME \
                       $RUSTUP_HOME; \
    chmod -R 1775 $CARGO_HOME \
                  $RUSTUP_HOME; \
    usermod -aG rust ${APP_USER}; \
    echo "### >>> rust >>>" | tee -a ${APP_USER_HOME}/.bashrc; \
    echo "export CARGO_HOME=$CARGO_HOME" | tee -a ${APP_USER_HOME}/.bashrc; \
    echo "export RUSTUP_HOME=$RUSTUP_HOME" | tee -a ${APP_USER_HOME}/.bashrc; \
    echo "export PATH=\$CARGO_HOME/bin:\$PATH" | tee -a ${APP_USER_HOME}/.bashrc; \
    echo "### <<< rust <<<" | tee -a ${APP_USER_HOME}/.bashrc

# Setup Docker CE
RUN set -eux; \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list; \
    apt-get update -qqy ;\
    DEBIAN_FRONTEND=noninteractive apt-get install -qqy --no-install-recommends \
        docker-ce; \
    apt-get clean -y; \
    rm -rf /var/lib/apt/lists/*; \
    usermod -aG docker ${APP_USER}; \
    # issue: https://github.com/docker/cli/issues/4807#issuecomment-1903950217 \
    sed -i 's/ulimit -Hn/# ulimit -Hn/g' /etc/init.d/docker; \
    rm -rf /var/cache/apt

