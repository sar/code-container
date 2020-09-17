FROM linuxserver/code-server:amd64-latest

# Update: System Packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt install -y wget apt-transport-https build-essential libssl-dev libffi-dev python3 python3-pip python3-dev ffmpeg youtube-dl systemd unzip ansible chromium-browser vim htop iputils-ping ranger tree

# SDK: Dotnet Core
RUN wget https://packages.microsoft.com/config/ubuntu/20.10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt install -y dotnet-sdk-5.0 dotnet-runtime-5.0 && \
    apt install -y dotnet-sdk-3.1 dotnet-runtime-3.1 && \
    apt install -y dotnet-sdk-2.1 dotnet-runtime-2.1

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
RUN npm install -g webpack-cli create-react-app gatsby gulp netlify-cli @aws-amplify/cli

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
    curl https://raw.githubusercontent.com/quantoneinc/vs-code-container-with-ssl/main/config/.zshrc >> ~/.zshrc

# SEC: Fail2ban
RUN apt install -y fail2ban && \
    wget https://raw.githubusercontent.com/quantoneinc/vs-code-container-with-ssl/main/config/jail.local -O /etc/fail2ban/jail.local && \
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