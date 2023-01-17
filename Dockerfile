# @diff upstream::
# @repo https://github.com/sar/neovim-container.git

# --------------
# BASE IMAGE
# --------------
FROM debian:11.5

# --------------
# ARGS
# --------------
ARG HOST_GID
ARG DEFAULT_USER
ARG SUDO_PASSWORD
ARG HTTPS_PROXY

# >= 16,18
ARG RELEASE_NODE=18
ARG RELEASE_BIN_NPM=9.3.0

# @diff code-server::
# @repo https://github.com/sar/vs-code-container-with-ssl.git
ARG RELEASE_CODE_SERVER=4.9.1

# @diff upstream::
# @repo https://github.com/sar/neovim-container.git

ARG RELEASE_BIN_DOTNET_DBG=2.2.0-961
ARG RELEASE_BIN_LAMBDA_DOTNET=6.9.0
ARG RELEASE_BIN_AWS_AMPLIFY_CLI=10.6.1
ARG RELEASE_BIN_TERRAFORMER=0.8.22
ARG RELEASE_BIN_GITHUB=2.4.0
ARG RELEASE_BIN_DIVE=0.9.2
ARG RELEASE_BIN_GITUI=v0.20.1
ARG RELEASE_BIN_VERCO=v6.7.0

# --------------
# USER
# --------------
RUN useradd ${DEFAULT_USER} && \
    usermod -aG sudo ${DEFAULT_USER} && \
    echo ${DEFAULT_USER}:${SUDO_PASSWORD} | chpasswd && \
    mkdir /home/${DEFAULT_USER} && \
    chown -R ${DEFAULT_USER}:${DEFAULT_USER} /home/${DEFAULT_USER}

# --------------
# Package: APT Transport HTTPs
# --------------
COPY pkgs /tmp/pkgs
RUN dpkg -i /tmp/pkgs/*.deb

# --------------
# Repos: Replace Sources, APT over HTTPs
# --------------
COPY pkgs/sources.list /etc/apt/sources.list

# --------------
# Update: System Packages, Dependencies
# --------------
RUN apt-get update && \
    apt-get upgrade -y && \
    apt install -y \
        ansible \
        bash \
        build-essential \
        curl \
        dirmngr \
        fontconfig \
        g++ \
        gcc \
        gnupg \
        gnupg-agent \
        golang \
        htop \
        jq \
        proxychains4 \
        chromium \
        libxcursor-dev \
        libxdamage-dev \
        libxi-dev \
        libxtst-dev \
        libnss3-dev \
        libxcb-dri3-dev \
        libffi-dev \
        libx11-dev \
        libxkbfile-dev \
        libsecret-1-dev \
        libvips-dev \
        libvips42 \
        man \
        pkg-config \
        proxychains \
        ranger \
        ripgrep \
        sed \
        software-properties-common \
        sshpass \
        sudo \
        systemd \
        tar \
        tree \
        trash-cli \
        unzip \
        vim \
        wget

# --------------
# SEC: Fail2ban
# --------------
USER root
RUN apt install -y fail2ban && \
    wget https://raw.githubusercontent.com/sar/vs-code-container-with-ssl/main/config/jail.local -O /etc/fail2ban/jail.local && \
    systemctl enable fail2ban

# --------------
# SEC: ClamAV
# --------------
RUN apt install -y clamav clamav-daemon && \
    freshclam

# --------------
# Python3
# --------------
RUN apt install -y \
      python3 \
      python3-dev \
      python3-pip \
      python3-venv

# --------------
# NodeJS
# --------------
RUN wget https://raw.githubusercontent.com/nodesource/distributions/master/deb/setup_${RELEASE_NODE}.x \
        -O /tmp/nodejs_${RELEASE_NODE}_setup.sh && \
    chmod +x /tmp/nodejs_${RELEASE_NODE}_setup.sh && \
    /tmp/nodejs_${RELEASE_NODE}_setup.sh && \
    apt install -y nodejs && \
    node -v && npm -v \
    npm config set python python3

# @diff code-server::
# @repo https://github.com/sar/vs-code-container-with-ssl.git

# --------------
# CodeServer: Setup
# --------------
RUN npm install --unsafe-perm -g code-server@${RELEASE_CODE_SERVER}

# @diff upstream::
# @repo https://github.com/sar/neovim-container.git

# --------------
# Podman: Runtime
# --------------

# docker-compose
USER root
RUN wget https://download.docker.com/linux/debian/gpg -O docker.gpg && \
    apt-key add docker.gpg && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" && \
    apt-get update && \
    apt install -y \
        docker-compose && \
    apt remove -y golang-docker-credential-helpers

# Podman
RUN apt install -y podman

# Podman Config
RUN id $DEFAULT_USER && \
    systemctl enable podman.socket

# --------------
# SDK: Dotnet Core
# --------------
RUN wget https://packages.microsoft.com/config/debian/$(lsb_release -rs)/packages-microsoft-prod.deb \
        -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt install -y \
        dotnet-sdk-7.0 \
        dotnet-runtime-7.0 \
        dotnet-sdk-6.0 \
        dotnet-runtime-6.0 \
        dotnet-sdk-5.0 \
        dotnet-runtime-5.0 \
        dotnet-sdk-3.1 \
        dotnet-runtime-3.1 \
        dotnet-sdk-2.1 \
        dotnet-runtime-2.1

# dotnet-tools
USER $DEFAULT_USER
RUN dotnet tool install -g dotnet-ef && \
    dotnet new --install Amazon.Lambda.Templates::${RELEASE_BIN_LAMBDA_DOTNET} && \
    dotnet tool install -g Amazon.Lambda.Tools && \
    dotnet tool install -g JetBrains.ReSharper.GlobalTools && \
    ls -la $HOME/.dotnet/**

USER root
RUN cp /home/$DEFAULT_USER/.dotnet/tools/* /usr/local/sbin/

# netcoredbg
USER $DEFAULT_USER
RUN wget https://github.com/Samsung/netcoredbg/releases/download/${RELEASE_BIN_DOTNET_DBG}/netcoredbg-linux-amd64.tar.gz && \
    tar -xzvf netcoredbg* && \
    mv /tmp/netcoredbg/* /usr/local/sbin/

# --------------
# SDK: AWS CLI, aws-shell
# --------------
USER root
RUN wget "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -O "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    pip3 install aws-shell --user

RUN wget "https://github.com/aws-amplify/amplify-cli/releases/download/${RELEASE_BIN_AWS_AMPLIFY_CLI}/amplify-pkg-linux.tgz" && \
    tar -xzvf amplify-pkg-linux.tgz && \
    mv amplify-pkg-linux /usr/local/sbin/amplify

# --------------
# SDK: Azure CLI
# --------------
RUN curl -sL https://aka.ms/InstallAzureCLIDeb -o azure_cli.sh && \
    chmod +x azure_cli.sh && \
    ./azure_cli.sh

# --------------
# NPM: Packages
# --------------
USER root
RUN npm install -g npm@${RELEASE_BIN_NPM}
RUN npm install -g yarn

RUN yarn global add \
    webpack-cli \
    create-react-app \
    gatsby \
    gulp \
    @storybook/cli \
    typescript-language-server

# --------------
# PKG: Terraform
# --------------
USER root
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt-get update && \
    apt install -y terraform

# build::source::github.com/sar/autosaved
USER root
WORKDIR /tmp
RUN git clone https://github.com/sar/autosaved.git && \
    cd autosaved && \
    make && \
    mv ./bin/autosaved_linux_amd64 /usr/local/sbin/autosaved && \
    rm -rf /tmp/autosaved

# --------------
# PKG: Binaries
# TODO: build from source
# --------------
WORKDIR /tmp

# terraformer
RUN wget https://github.com/GoogleCloudPlatform/terraformer/releases/download/${RELEASE_TERRAFORMER}/terraformer-all-linux-amd64 && \
    mv terraformer-all-linux-amd64 /usr/local/sbin/terraformer

# github act local
USER root
RUN wget https://raw.githubusercontent.com/nektos/act/master/install.sh -O act_install.sh && \
    sha256sum act_install.sh && \
    chmod +x ./act_install.sh && \
    ./act_install.sh

# gh cli
RUN wget https://github.com/cli/cli/releases/download/v${RELEASE_BIN_GITHUB}/gh_${RELEASE_BIN_GITHUB}_linux_amd64.deb && \
    dpkg -i gh*_amd64.deb && \
    which gh

# dive
RUN wget https://github.com/wagoodman/dive/releases/download/v${RELEASE_BIN_DIVE}/dive_${RELEASE_BIN_DIVE}_linux_amd64.deb && \
    sha256sum ./dive*.deb && \
    dpkg -i ./dive*.deb && \
    which dive

# dapr
RUN wget https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O dapr_install.sh && \
    sha256sum dapr_install.sh && \
    chmod +x ./dapr_install.sh && \
    ./dapr_install.sh && \
    which dapr

# gitui
USER root
RUN wget https://github.com/extrawurst/gitui/releases/download/${RELEASE_BIN_GITUI}/gitui-linux-musl.tar.gz && \
    tar -xzvf gitui-linux-musl.tar.gz && \
    mv gitui /usr/local/sbin/

# verco
RUN wget https://github.com/vamolessa/verco/releases/download/${RELEASE_BIN_VERCO}/verco-linux-x86_64 -O verco && \
    mv verco /usr/local/sbin/

# stackoverflow
RUN wget https://github.com/samtay/so/releases/download/v0.4.5/so-v0.4.5-x86_64-unknown-linux-gnu.tar.gz && \
    tar -xzvf so-v0.4.5-x86_64-unknown-linux-gnu.tar.gz && \
    ls -la so* && \
    mv so /usr/local/sbin

# --------------
# Database Tools
# --------------

# postgresql
USER root
RUN apt install -y \
      postgresql-client \
      pspg

# mongodb
RUN yarn global add mngr

# build::source::sc-im
RUN apt-get install -y \
    bison \
    libncurses5-dev \
    libncursesw5-dev \
    libxml2-dev \
    libzip-dev \
    pkg-config

WORKDIR /tmp
RUN git clone https://github.com/jmcnamara/libxlsxwriter.git && \
    cd libxlsxwriter && \
    make && \
    make install && \
    ldconfig

WORKDIR /tmp
RUN git clone https://github.com/andmarti1424/sc-im.git && \
    cd sc-im/src && \
    make && \
    make install && \
    which sc-im

USER $DEFAULT_USER
RUN mkdir -p ~/.config/sc-im
COPY config/scimrc /home/$DEFAULT_USER/.config/sc-im/scimrc

# --------------
# Shell: ZSH
# --------------
USER root
RUN apt install -y zsh && \
    chsh -s /bin/zsh

USER $DEFAULT_USER
WORKDIR /tmp
RUN wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O install_zsh.sh && \
    chmod +x ./install_zsh.sh && \
    ZSH=~/.zsh && \
    ./install_zsh.sh --unattended && \
    cd ~/.oh-my-zsh/themes/ && \
    git clone https://github.com/romkatv/powerlevel10k.git && \
    cd ~/.oh-my-zsh/custom/plugins && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git && \
    git clone https://github.com/zsh-users/zsh-completions.git && \
    git clone https://github.com/zsh-users/zsh-history-substring-search.git && \
    git clone https://github.com/zsh-users/zsh-autosuggestions.git
    #git clone https://github.com/romkatv/gitstatus.git

WORKDIR /tmp
COPY config/.zshrc /home/$DEFAULT_USER/.zshrc

# --------------
# MAINT: Hosts
# --------------
USER root
RUN wget https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-social/hosts \
        -O /etc/hosts

# --------------
# MAINT: Cleanup
# --------------
RUN apt clean all

# --------------
# MAINT: alias rm 
# --------------
RUN mv /bin/rm /bin/rmrm && \
    cp /bin/trash /bin/rm

# --------------
# MAINT: PERMISSIONS
# --------------
USER root
RUN chown -R ${DEFAULT_USER} /home/${DEFAULT_USER}/.config && \
    chown -R $DEFAULT_USER /usr/local/sbin && \
    chmod +x /usr/local/sbin/*

USER $DEFAULT_USER
RUN mkdir -p ~/.config/gh && \
    mkdir -p ~/.local/share/NuGet && \
    chown -R ${DEFAULT_USER} ~/.local/share/NuGet && \
    mkdir -p /tmp/NuGetScratch && \
    chown -R $DEFAULT_USER:$DEFAULT_USER /tmp/NuGetScratch

# @diff code-server::
# @repo https://github.com/sar/vs-code-container-with-ssl.git

# --------------
# CONFIG PATHS
# --------------
RUN mkdir /config /config/data /config/extensions
COPY init.sh /config/init.sh

# @diff upstream::
# @repo https://github.com/sar/neovim-container.git

# --------------
# EXPOSE RUNTIME PORTS
# --------------
EXPOSE 5000 5001 5002 5003 5004 5005 5006 5007 5008 5009 5010
EXPOSE 8000 8001 8002 8003 8004 8005 8006 8007 8008 8009 8010

# --------------
# ENTRYPOINT: Code Server
# --------------
USER $DEFAULT_USER
ENTRYPOINT [ "/config/init.sh" ];

