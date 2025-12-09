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

1. Create a secret to access NDK images hosted in the Nutanix DockerHub registry on both the K8s clusters. The username and token are available from the [Nutanix portal](https://portal.nutanix.com/page/downloads?product=ndk).
```
kubectl create secret docker-registry ndk-image-pull-secret \
   --namespace ntnx-system \
   --docker-username=nutanixndk \
   --docker-password=<DOCKERHUB_ACCESS_TOKEN>
```

2. Create a secret to store the Prism Central credentials (must be a user with admin privileges on PC) on both the K8s clusters. Make sure to update the key here. <br>Note: this command is not required in NKP as the secret `nutanix-csi-credentials` will be created during installation. 

```
kubectl create secret generic nutanix-csi-credentials \
   --namespace ntnx-system \
   --from-literal=key=<PC_IP/FQDN:9440:username:password>
```

3. Install the Helm chart for NDK on both the K8s clusters. <br> This skips TLS verification between the two NDK instances. Pleae follow the documentation if you wish to bring your certificates and configure TLS encryption. Ensure you provide a unique name for each NDK instance in the flag `tls.server.clusterName`.

```
helm repo add nutanix-helm-releases https://nutanix.github.io/helm-releases/ && helm repo update nutanix-helm-releases

helm install ndk nutanix-helm-releases/ndk \
  --namespace ntnx-system \
  --version 2.0.0 \
  --set config.secret.name=nutanix-csi-credentials \
  --set tls.server.clusterName=<ndk_name>
```
---

## Installation on airgapped and dark site environments
You will need a private registry where the NDK images have to be pushed to. Ensure you have [Docker Engine](https://docs.docker.com/engine/install/), [helm](https://helm.sh/docs/intro/install/), jq and yq installed in your jumphost.

Clone this repo and follow the steps below. 
```
git clone https://github.com/nkunnath/nkp-ndk-quickstart.git && cd nkp-ndk-quickstart/
```

1. Download the NDK airgapped bundle from Nutanix portal.
```
./0-get-ndk.sh
```

2. Load the NDK images from the bundle into Docker.
```
./1-load-ndk-images.sh
```

3. Push the images to your private registry.
```
./2-push-ndk.sh 
```
> **Notes:**
> [Optional]: If this registry uses a self signed CA and the K8s cluster does not trust the CA, follow the steps below to add the registry configuration to the cluster. 

> ---
> If installing on NKP:
> ---
> - In the workspace namespace on the NKP management cluster, create a Kubernetes Secret with the ca.crt key > populated with the CA certificate in PEM format:

> kubectl create secret generic my-mirror-ca-cert \
>   --namespace=<WORKSPACE_NAMESPACE>
>   --from-file=ca.crt=registry-ca.crt


> - To add image registry credentials and/or CA certificate, specify the following configuration in the Cluster object of the NKP cluster(s):

> apiVersion: cluster.x-k8s.io/v1beta1
> kind: Cluster
> metadata:
>   name: <NAME>
> spec:
>   topology:
>     variables:
>       - name: clusterConfig
>         value:
>           imageRegistries:
>             - url: https://my-registry.io
>               credentials:
>                 secretRef:
>                   name: my-mirror-ca-cert


> ---
> If installing on OpenShift:
> ---
> Follow this guide: https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/registry/index#images-configuration-cas_configuring-registry-operator


4. Install NDK in the K8s clusters.
```
./3-helm-install-ndk.sh 
```