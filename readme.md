# Containerized Code Server with SSL & Dev Tooling

Launch your own [Code Server](https://github.com/cdr/code-server) container with preloaded dev tools (sdks, npm packages, CLIs etc) for an efficient and securely accessible Web IDE in your homelab!

![vs-code-server](https://raw.githubusercontent.com/cdr/code-server/main/docs/assets/screenshot.png)

## Getting Started

Clone this repo on the server with `docker` or `podman` configured. It's recommended to attach mount points for storing your codebase isolated from the container runtime for redundancy and failover management.

Next, set the required environment variables and data paths using the provided [.env.template](.env.template) replicated to `.env` (note: default exclude declared in .gitignore).

Persistent storage for extensions and vscode settings can also be enabled by mapping `HOST_*` variables for convenience against container restarts.

Here's an example of what you'll need to define in `.env`:
```
VIRTUAL_HOST=10.0.0.1
VIRTUAL_PORT=8555

HOST_CONFIG_PATH=./config
HOST_LOG_PATH=./logs

HOST_CODE_PATH=/mnt/codebase
CODE_PATH=/code

TZ=America/New_York
PASSWORD=<PASSWORD>
SUDO_PASSWORD=<SUDO_PASSWORD>
```

Nginx is used to reroute traffic from `[::]:80` to upstream HTTPS port `[::]:8443` with self-signed SSL certificates. Checkout and run the [generate_certs.sh](scripts/generate_certs.sh) script to emit the required certificates with signing key using `openssl`.

Place both the [nginx.conf](config/nginx.conf) and certs under the paths defined in `code-server.yaml`.

```nginx.conf
listen [::]:443 ssl default_server;
        ssl_certificate /etc/nginx/certs/ssl.crt;
        ssl_certificate_key /etc/nginx/certs/ssl.key;
        ssl_protocols TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;
        ssl_ciphers ECDH+AESGCM:ECDH+AES256:ECDH+AES128:DHE+AES128:!ADH:!AECDH:!MD5;
```

Finally, deploy the container stack on the docker host using the command `docker-compose -f code-server.yaml up`. It may take 15-20 minutes depending on your hardware and network bandwidth for the initial build. The dockerfile pre-configures a number of devtools and updates the base image packages.

To comply with Docker CIS, resource limits are defined on each of the containers but can be customized to your hardware in the compose [code-server.yaml](code-server.yaml) file.

## Pre-Installed Dev Tools

Here's a quick overview of what the `dockerfile` does to extend the [linuxserver/code-server](https://github.com/linuxserver/docker-code-server) base image. This allows containers to be rapidly deployed and scaled up for usage on dev teams with tooling ready to go.

The output image includes SDKs for cloud native app development workloads such as React, Node, C#, AWS and Azure Cloud CLIs. 

```
* Cloud CLIs
    * AWS CLI Tools
        * aws-shell
        * amplify cli
    * Azure CLI
* NPM packages
    * yarn (upstream)
    * gatsby-cli
    * gulp
    * create-react-app
    * @storybook/cli
* .NET Core SDK and Runtime
    * 5.0.0
    * 3.1.0
    * 2.1.0
* Python global env
    * python3 python3-pip python3-dev
* Ubuntu apt packages
    * Networking
        * wget
        * apt-transport-https
        * libssl-dev libffi-dev
    * Tools
        * ranger
        * tree
        * unzip
        * ansible
        * vim
        * htop
        * iputils-ping
    * OS/Misc
        * systemd
        * build-essential
        * ffmpeg
        * youtube-dl
        * chromium-browser
    * Default shell --> zsh/oh-my-zsh
        * zsh-syntax-highlighting
        * zsh-autosuggestions
        * zsh-completions
        * history-search-multi-word
```

Refer to the [Dockerfile](dockerfile) for image layers.

### Remote Debugging

By default the `dockerfile` and `code-server.yaml` are set to expose port ranges `5000-5010` and `8000-8010` commonly used for web app development. Customize this for your workload such as React, Gatsby, Angular, Django, etc. to allow for remote debugging HTTP instances that are running inside the container.

To allow external access on node frameworks that depend `http-server` (instantiated with `npm` or `yarn`) you may need to also update your `package.json` and bind the runtime to the host ip instead of localhost. 

Here are a few common examples:

```json
{
    "scripts": {
        "ng:start": "ng serve --host 0.0.0.0",
        "npm:start": "http-server --host 0.0.0.0",
        "gatsby:start": "gatsby develop --host 0.0.0.0"
    }
}
```

Alternatively, if you'd prefer not to expose ports, check out the [vscode-browser-preview](https://github.com/auchenberg/vscode-browser-preview/) extension which enables `chromium` based inspection and debugging within the container itself.

## Security Considerations

As the base image extends `ubuntu:18.04`, additional steps have been taken to add security measures with `hosts` file, `fail2ban` and `clamav` packages preloaded. These are precautionary against attacks but insufficient against (un)known breaches.

**Log Analytics**

It's strongly recommended to configure a remote syslog daemon for log analytics with `auditd` enabled, here's our guide on using solutions such as [Graylog2](https://ix.quant.one/GraylogAnsible).

**Ports**

There's a wide range of tcp ports exposed and mapped directly to the host for remote debugging apps running inside the container. By default, only the `code-server` is allocated on ports `8443` and `localhost:8080`.

```bash
$ netstat -tnlp

Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:8443            0.0.0.0:*               LISTEN      299/node            
tcp        0      0 127.0.0.1:8080          0.0.0.0:*               LISTEN      -     
```

For dev workloads outside of a homelab or private cloud behind firewalls, using an nginx reverse proxy with HTTPS and auth redirects is vital to preventing sensitive code exposure.

### Workarounds

**File Watcher Limit**

Containers inherit the default file watcher limit from the docker host. To set an increased value persistently, run the following command on the server and reboot.

```bash
$ echo "fs.inotify.max_user_watches = 524288" >> /etc/sysctl.conf
$ sudo sysctl -p
```

**Docker in Docker**

To run containers using rootless mode inside the `code-server` container itself, set `gid` as an environment variable (in `.env`) matching the docker host before building the image. This will add the default `$USER` to the `docker` group with the correct permissions to the `docker.sock`.

```env
DOCKER_HOST_GID=999
```

```bash
$ ls -l /var/run/docker.sock
srw-rw----. 1 root docker 0 Dec 22 17:52 /var/run/docker.sock

$ id $USER
...999(docker)

# Manually rebuild
$ docker build --build-arg DOCKER_HOST_GID=999 --build-arg DEFAULT_USER=abc -t <image_tag> .

# Use docker-compose to build and deploy automatically
$ docker-compose -f code-server.yaml up
```

Inside the container, you should no longer receive permission errors upon calling docker comands without sudo.

```bash
$ docker run hello-world
docker: Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Post http://%2Fvar%2Frun%2Fdocker.sock/v1.24/containers/create: dial unix /var/run/docker.sock: connect: permission denied.
See 'docker run --help'.

# Built with GID=<docker_host_gid>
$ docker run hello-world
```

## Contributing

Contributions including forks and reporting issues are welcome. Be sure to include the output of `$ uname -a` of your container host or `docker-compose` configuration and a detailed description to allow for replication.

## License

This project is made available under the MIT License. For more information, refer to [license.md](license.md).
