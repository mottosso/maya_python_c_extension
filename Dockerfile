# If you haven't got Linux or the right distribution of Linux,
# here's a Dockerfile to replicate the required environment
FROM mottosso/maya:2020

# Get hold of g++ and friends
RUN yum group install "Development Tools"

# Appease the mayapy
ENV XDG_RUNTIME_DIR=/var/tmp/runtime-root

WORKDIR /host
