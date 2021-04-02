# Builds an image containing openshift-install-powervs bash script
# and all dependencies installed

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

ARG RELEASE_VER=4.7
ARG INSTALL_DIR=/data

COPY openshift-install-powervs /usr/bin/openshift-install-powervs

WORKDIR $INSTALL_DIR

RUN microdnf update && \
    microdnf install -y yum findutils && \
    mkdir -p $INSTALL_DIR && \
    yum install -y which openssh openssh-clients && \
    chmod +x /usr/bin/openshift-install-powervs && \
    /usr/bin/openshift-install-powervs setup && \
    mv terraform ibmcloud oc /usr/bin

ENTRYPOINT ["/bin/bash", "/usr/bin/openshift-install-powervs"]
