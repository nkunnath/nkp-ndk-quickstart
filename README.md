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

2. Install the Helm chart for NDK from the Nutanix DockerHub registry on both the K8s clusters. <br> This skips TLS verification between the two NDK instances. Please follow the documentation if you wish to bring your certificates and configure TLS encryption. 
Ensure you set the variables below. The username and token are available from the [Nutanix portal](https://portal.nutanix.com/page/downloads?product=ndk).

```
export DOCKERHUB_USERNAME=nutanixndk
export DOCKERHUB_ACCESS_TOKEN=""
export NDK_NAME=""    # Unique name for each NDK instance 
export NDK_VERSION=2.0.0 
```
```
helm repo add nutanix-helm-releases https://nutanix.github.io/helm-releases/ && helm repo update nutanix-helm-releases

helm install ndk nutanix-helm-releases/ndk \
  --namespace ntnx-system \
  --version ${NDK_VERSION} \
  --set config.secret.name=nutanix-csi-credentials \
  --set imageCredentials.credentials.username=${DOCKERHUB_USERNAME} \
  --set imageCredentials.credentials.password=${DOCKERHUB_ACCESS_TOKEN} \
  --set tls.server.clusterName=${NDK_NAME}
```

Validate NDK hs been deployed successfully:
```
kubectl get deployment/ndk-controller-manager -n ntnx-system
```

### Uninstallation ###
```
helm uninstall ndk --namespace ntnx-system
```

---
For NDK on airgapped installation, follow this [procedure](airgapped/README.md).

---

### NDK StorageCluster ###

A `StorageCluster` custom resource provides NDK with information on interacting with the infrastructure layer. The Prism Element cluster, which provisions the storage and Prism Central UUID's are passed in as parameters.

Note that this is a one-time operation performed by the platform team on each Kubernetes cluster.

Create the `StorageCluster` object on all the Kubernetes clusters participating in DR with NDK.
```
cd NDK-configuration && ./0_create_storage_cluster.sh
```


---
### NDK Remote ###

In order to establish pairing between NDK instances on different Kubernetes clusters, NDK provides a custom resource called `Remote`.

On a "source cluster", a `Remote` object must be created pointing to the NDK service address of the remote cluster. 


> How do I get the NDK service IP on each cluster?

```
kubectl get service -n ntnx-system ndk-intercom-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```
If you wish to setup synchronous replication, then the `Remote` object has to be created on both the Kubernetes clusters.
```
cd NDK-configuration && ./4_create_remote.sh
```


Ensure the NDK instances can communicate with eaach other by verifying the status is available before proceeding further.
```
kubectl get remote
```
