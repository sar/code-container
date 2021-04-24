FROM linuxserver/code-server:amd64-latest
ARG DOCKER_HOST_GID
ARG DEFAULT_USER

# Update: System Packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt install -y ansible apt-transport-https build-essential ca-certificates chromium-browser ffmpeg gnupg-agent htop iputils-ping libffi-dev libssl-dev python3 python3-dev python3-pip ranger software-properties-common sshpass systemd tree unzip vim wget youtube-dl

# Docker: Runtime
RUN wget https://download.docker.com/linux/ubuntu/gpg -O docker.gpg && \
    apt-key add docker.gpg && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io

# Docker: Default User Perms
RUN groupmod -g $DOCKER_HOST_GID docker && \
    usermod -aG docker $DEFAULT_USER && \
    id $DEFAULT_USER && \
    systemctl enable docker

# SDK: Dotnet Core
RUN wget https://packages.microsoft.com/config/ubuntu/20.10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt install -y dotnet-sdk-5.0 dotnet-runtime-5.0 && \
    apt install -y dotnet-sdk-3.1 dotnet-runtime-3.1 && \
    apt install -y dotnet-sdk-2.1 dotnet-runtime-2.1 && \
    dotnet tool install -g dotnet-ef && \
    dotnet new --install Amazon.Lambda.Templates::5.0.0 && \
    dotnet tool install -g Amazon.Lambda.Tools && \
    dotnet tool install -g JetBrains.ReSharper.GlobalTools && \
    chown -R $DEFAULT_USER:$DEFAULT_USER /tmp/NuGetScratch

# SDK: AWS CLI, aws-shell
RUN wget "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -O "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install && \
    pip3 install aws-shell --user

# SDK: Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb -o azure_cli.sh && \
    chmod +x azure_cli.sh && \
    ./azure_cli.sh

# NPM: Packages
RUN npm install -g webpack-cli create-react-app gatsby gulp @aws-amplify/cli @storybook/cli

# Shell: ZSH
RUN apt install -y zsh && \
    wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O install_zsh.sh && \
    chmod +x ./install_zsh.sh && \
    ZSH=~/.zsh && \
    ./install_zsh.sh --unattended && \
    chsh -s /bin/zsh && \
    cd ~/.oh-my-zsh/themes/ && \
    git clone https://github.com/romkatv/powerlevel10k.git && \
    cd ~/.oh-my-zsh/custom/plugins && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git && \
    git clone https://github.com/zsh-users/zsh-completions.git && \
    git clone https://github.com/zdharma/history-search-multi-word.git && \
    git clone https://github.com/zsh-users/zsh-autosuggestions.git && \
    curl https://raw.githubusercontent.com/DigitalTransformation/vs-code-container-with-ssl/main/config/.zshrc >> ~/.zshrc

# Homebrew
RUN mkdir /home/linuxbrew /config/.cache/Homebrew /config/.config/git && \
    touch /config/.profile && \
    chown -R $DEFAULT_USER:$DEFAULT_USER /home/linuxbrew /config/.cache/Homebrew /config/.config/git /config/.profile

USER $DEFAULT_USER
RUN yes '' | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    echo 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> /config/.profile && \
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv) && \
    brew tap git-time-metric/gtm && \
    brew install gtm

# SEC: Fail2ban
USER root
RUN apt install -y fail2ban && \
    wget https://raw.githubusercontent.com/DigitalTransformation/vs-code-container-with-ssl/main/config/jail.local -O /etc/fail2ban/jail.local && \
    systemctl enable fail2ban

# SEC: ClamAV
RUN apt install -y clamav clamav-daemon && \
    freshclam

# SEC: Hosts
RUN wget https://someonewhocares.org/hosts/hosts -O /etc/hosts

# APT: Cleanup
RUN apt-get clean

# EXPOSE RUNTIME PORTS
EXPOSE 8443 5000-5010 8000-8010
