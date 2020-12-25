# Builds an image containing openshift-install-powervs bash script
# and all dependencies installed

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

ARG RELEASE_VER=4.6
ARG INSTALL_DIR=/root/ocp-install

ENV PATH $PATH:$INSTALL_DIR

WORKDIR $INSTALL_DIR

RUN microdnf update && \
    microdnf install -y yum findutils && \
    mkdir -p $INSTALL_DIR

COPY openshift-install-powervs $INSTALL_DIR

RUN chmod +x openshift-install-powervs && \
    openshift-install-powervs setup
