# NDK quickstart

---
### What is NDK
NDK is a data services product that provides K8s native business continuity and disaster recovery to K8s apps. It can snapshot an entire application/namespace with its associated objects like services, configmaps and the associated persistent storage (PVC's, PV's) and restore it onto a secondary K8s cluster.
Validated distributions include Nutanix Kubernetes Platform (NKP), OpenShift and EKS-A.

---
### Installation
NKP: Starting from NKP 2.17, NDK is available to be installed as a catalog application.
For NKP versions < 2.17 and other supported distributions, please follow the steps below.

Install helm and kubectl on your jumphost - https://helm.sh/docs/intro/install/

This command is not required in NKP as the secret `nutanix-csi-credentials` will be created during installation. Make sure to update the key with Prism Central credentials.

- kubectl create secret generic nutanix-csi-credentials -n ntnx-system –from-literal=key=<PC:9440:username:password>

1. Create a secret to access NDK images hosted in the Nutanix DockerHub registry. The username and token are available from the [Nutanix portal](https://portal.nutanix.com/page/downloads?product=ndk).
$ kubectl create secret -n ntnx-system docker-registry ndk-image-pull-secret --docker-username=nutanixndk --docker-password=<DOCKERHUB_ACCESS_TOKEN>

2. Install the Helm chart for NDK

```
 $ helm repo add nutanix-helm-releases https://nutanix.github.io/helm-releases/

$ helm install ndk -n ntnx-system nutanix-helm-releases/ndk --version 1.3.0-10496 \
  --set tls.server.clusterName=<ndk_name> \
  --set config.secret.name=nutanix-csi-credentials
```


### Installation on airgapped and dark site environments
This guide is meant to run on a linux jump host that runs docke-ce, jq, yq, helm.

