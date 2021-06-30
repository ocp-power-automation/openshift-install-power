# Container Images

You can build and run the install script from a container. Please refer to the following instructions for building and running the container image. Change the `docker` commands with `podman` in case Podman is installed on your machine.

## Build using Dockerfile

The Dockerfile can be used to build an image with the install script, dependencies and the required artifacts. To build from the Dockerfile please complete the following steps.

1. Clone this repository.
```
git clone https://github.com/ocp-power-automation/openshift-install-power.git
cd openshift-install-power
```

2. Run the build command.
```
docker build -t openshift-install-powervs -f images/Dockerfile . --no-cache
```

## Use the Image

1. To use the image to create cluster, run the following command.
```
docker run -it -e IBMCLOUD_API_KEY="<key>" -v $(pwd):/data openshift-install-powervs create
```

2. To destroy the cluster, run the following command.
```
docker run -it -e IBMCLOUD_API_KEY="<key>" -v $(pwd):/data openshift-install-powervs destroy
```

