FROM ubuntu:16.04


# ------------------------------------------------------
# --- Environments and base directories

# Environments
# - Language
ENV LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    # - CI
    CI="true" \
    BITRISE_IO="true" \
    # - main dirs
    BITRISE_SOURCE_DIR="/bitrise/src" \
    BITRISE_BRIDGE_WORKDIR="/bitrise/src" \
    BITRISE_DEPLOY_DIR="/bitrise/deploy" \
    BITRISE_CACHE_DIR="/bitrise/cache" \
    BITRISE_PREP_DIR="/bitrise/prep" \
    BITRISE_TMP_DIR="/bitrise/tmp" \
    # Configs - tool versions
    TOOL_VER_BITRISE_CLI="1.47.0" \
    TOOL_VER_RUBY="2.7.0" \
    TOOL_VER_GO="1.15.2" \
    TOOL_VER_DOCKER="5:19.03.0" \
    TOOL_VER_DOCKER_COMPOSE="1.21.2"

# create base dirs
RUN mkdir -p ${BITRISE_SOURCE_DIR} \
    && mkdir -p ${BITRISE_DEPLOY_DIR} \
    && mkdir -p ${BITRISE_CACHE_DIR} \
    && mkdir -p ${BITRISE_TMP_DIR} \
    # prep dir
    && mkdir -p ${BITRISE_PREP_DIR}

# switch to temp/prep workdir, for the duration of the provisioning
WORKDIR ${BITRISE_PREP_DIR}


# ------------------------------------------------------
# --- Base pre-installed tools
RUN apt-get update -qq

# Generate proper EN US UTF-8 locale
# Install the "locales" package - required for locale-gen
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    locales \
    # Do Locale gen
    && locale-gen en_US.UTF-8

# --- Add ppa
RUN apt-key adv --refresh-keys --keyserver keyserver.ubuntu.com \
    # For PPAs
    && DEBIAN_FRONTEND=noninteractive apt-get -y install software-properties-common \
    && add-apt-repository ppa:git-core/ppa \
    && apt-get update -qq

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
    # Requiered for Bitrise CLI
    git \
    mercurial \
    curl \
    wget \
    rsync \
    sudo \
    expect \
    # Python
    python \
    python-dev \
    python-pip \
    # Common, useful
    build-essential \
    zip \
    unzip \
    tree \
    clang \
    imagemagick \
    groff \
    jq \
    awscli

# ------------------------------------------------------
# --- Pre-installed but not through apt-get

# install AWSCLI from pip
RUN ["pip", "install", "awscli"]

# install Ruby from source
#  from source: mainly because of GEM native extensions,
#  this is the most reliable way to use Ruby on Ubuntu if GEM native extensions are required
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
    build-essential \
    zlib1g-dev \
    libssl-dev \
    libreadline6-dev \
    libyaml-dev \
    libsqlite3-dev \
    && mkdir -p /tmp/ruby-inst \
    && cd /tmp/ruby-inst \
    && wget -q https://cache.ruby-lang.org/pub/ruby/$(echo "${TOOL_VER_RUBY}" | cut -d'.' -f 1,2)/ruby-${TOOL_VER_RUBY}.tar.gz \
    && tar -xvzf ruby-${TOOL_VER_RUBY}.tar.gz \
    && cd ruby-${TOOL_VER_RUBY} \
    && ./configure --prefix=/usr/local && make && make install \
    # cleanup
    && cd / \
    && rm -rf /tmp/ruby-inst \
    && gem update --system --no-document
RUN [ -x "$(command -v bundle)" ] || gem install bundler --no-document


# install Go
#  from official binary package
RUN wget -q https://storage.googleapis.com/golang/go${TOOL_VER_GO}.linux-amd64.tar.gz -O go-bins.tar.gz \
    && tar -C /usr/local -xvzf go-bins.tar.gz \
    && rm go-bins.tar.gz
# ENV setup
ENV PATH $PATH:/usr/local/go/bin
# Go Workspace dirs & envs
# From the official Golang Dockerfile
#  https://github.com/docker-library/golang
ENV GOPATH /bitrise/go
ENV PATH $GOPATH/bin:$PATH
# 755 because Ruby complains if 777 (warning: Insecure world writable dir ... in PATH)
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 755 "$GOPATH"


# Install NodeJS
#  from official docs: https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
RUN curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
RUN sudo apt-get install -y nodejs

# Install npm 
# releases: https://github.com/npm/cli/releases
RUN npm install -g npm@6.13.4


# Install Yarn
# as described at: https://yarnpkg.com/en/docs/install#linux-tab
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && sudo apt-get install -y yarn


# Install docker
#  as described at: https://docs.docker.com/engine/installation/linux/ubuntu/
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apt-transport-https \
    ca-certificates
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
RUN sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-cache policy docker-ce \
    # For available docker-ce versions
    #  you can run `sudo apt-get update && sudo apt-cache policy docker-ce`
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    docker-ce=${TOOL_VER_DOCKER}~3-0~ubuntu-xenial



# docker-compose
RUN wget -q https://github.com/docker/compose/releases/download/${TOOL_VER_DOCKER_COMPOSE}/docker-compose-`uname -s`-`uname -m` -O /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose \
    && docker-compose --version


# ------------------------------------------------------
# --- Bitrise CLI

#
# Install Bitrise CLI
RUN wget -q https://github.com/bitrise-io/bitrise/releases/download/${TOOL_VER_BITRISE_CLI}/bitrise-$(uname -s)-$(uname -m) -O /usr/local/bin/bitrise \
    && chmod +x /usr/local/bin/bitrise \
    && bitrise setup \
    && bitrise envman -version \
    && bitrise stepman -version \
    # setup the default StepLib collection to stepman, for a pre-warmed
    #  cache for the StepLib
    && bitrise stepman setup -c https://github.com/bitrise-io/bitrise-steplib.git \
    && bitrise stepman update


# ------------------------------------------------------
# --- SSH config

COPY ./ssh/config /root/.ssh/config

# ------------------------------------------------------
# --- Git config

RUN git config --global user.email "please-set-your-email@bitrise.io" \
    && git config --global user.name "J. Doe (https://devcenter.bitrise.io/builds/setting-your-git-credentials-on-build-machines/)"


# ------------------------------------------------------
# --- Git LFS

RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install git-lfs \
    && git lfs install


# ------------------------------------------------------
# --- Cleanup, Workdir and revision

WORKDIR $BITRISE_SOURCE_DIR

ENV BITRISE_DOCKER_REV_NUMBER_BASE v2021_03_30
CMD bitrise --version
