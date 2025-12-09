# NDK quickstart

---
## What is NDK ##
NDK is a data services product that provides K8s native business continuity and disaster recovery to K8s apps. It can snapshot an entire application/namespace with its associated objects like services, configmaps and the associated persistent storage (PVC's, PV's) and restore it onto a secondary K8s cluster.<br>
Validated distributions include Nutanix Kubernetes Platform (NKP), OpenShift and EKS-A.

---
## Installation ##
`Note only for NKP: Starting from NKP 2.17, NDK is available to be installed as a catalog application.` <br>
For NKP versions < 2.17 and other supported distributions, please follow the steps below.


### Prerequisites ###

Note: We recommend setting the contexts for all your Kubernetes clusters where NDK will be installed. Below is an example on adding the context to the kubeconfig file

```
export KUBECONFIG=~/.kube/config:~/Downloads/my-nkp-cluster.conf
kubectl config view --flatten > /tmp/config
mv /tmp/config ~/.kube/config
```


-  Install [helm](https://helm.sh/docs/intro/install/) and kubectl on your jumphost.
- Install [Nutanix CSI driver](https://artifacthub.io/packages/helm/nutanix-helm-releases/nutanix-csi-storage) (installed out of the box in NKP clusters) or the Nutanix CSI Operator on OpenShift.
- Install [cert-manager](https://cert-manager.io/docs/installation/) (installed out of the box in NKP clusters) or the cert-manager Operator on OpenShift. 
- Install a load balancer that is required for cross cluster communication of NDK service. NKP clusters include MetalLB load balancer out of the box, of which one IP address from the load balancer will be assigned to the NDK service. If using OpenShift, we recommend installing the MetalLB Operator from the OperatorHub.

---

1. Create a secret to store the Prism Central credentials (must be a user with admin privileges on PC) on both the K8s clusters. Make sure to update the key here. 
> Note: this command is not required in NKP as the secret `nutanix-csi-credentials` will be created during installation. 

```
kubectl create secret generic nutanix-csi-credentials \
   --namespace ntnx-system \
   --from-literal=key=<PC_IP/FQDN:9440:username:password>
```
<br>
2. Install the Helm chart for NDK from the Nutanix DockerHub registry on both the K8s clusters. <br> This skips TLS verification between the two NDK instances. Pleae follow the documentation if you wish to bring your certificates and configure TLS encryption. Ensure you provide a unique name for each NDK instance in the flag `tls.server.clusterName`. The username and token are available from the [Nutanix portal](https://portal.nutanix.com/page/downloads?product=ndk).

```
export DOCKERHUB_USERNAME=nutanixndk
export DOCKERHUB_ACCESS_TOKEN=""
export NDK_NAME=""
```
```
helm repo add nutanix-helm-releases https://nutanix.github.io/helm-releases/ && helm repo update nutanix-helm-releases

helm install ndk nutanix-helm-releases/ndk \
  --namespace ntnx-system \
  --version 2.0.0 \
  --set config.secret.name=nutanix-csi-credentials \
  --set imageCredentials.credentials.username=${DOCKERHUB_USERNAME} \
  --set imageCredentials.credentials.password=${DOCKERHUB_ACCESS_TOKEN} \
  --set tls.server.clusterName=${NDK_NAME}
```
---
For NDK on airgapped installation, follow this [procedure](airgapped/README.md).

---

