FROM debian:buster

# --------------
# Package: APT Transport HTTPs
# --------------
COPY pkgs /tmp/pkgs
RUN dpkg -i /tmp/pkgs/*.deb

# --------------
# Repos: Replace Sources, APT over HTTPs
# --------------
COPY config/sources.list /etc/apt/sources.list

# --------------
# Package: Openssl
# --------------
RUN apt-get update && \
    apt install -y \
      openssl && \
    apt clean all

WORKDIR /tmp

CMD [ "/bin/sh", "-c", "/tmp/generate_certs.sh" ]
