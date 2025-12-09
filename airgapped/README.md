
# Installation on airgapped and dark site environments
Note: We recommend setting the contexts for all your Kubernetes clusters where NDK will be installed. Below is an example on adding the context to the kubeconfig file

```
export KUBECONFIG=~/.kube/config:~/Downloads/my-nkp-cluster.conf
kubectl config view --flatten > /tmp/config
mv /tmp/config ~/.kube/config
```

You will need a private registry where the NDK images have to be pushed to. Ensure you have [Docker Engine](https://docs.docker.com/engine/install/), [helm](https://helm.sh/docs/intro/install/), [jq](https://jqlang.org/download/) and [yq](https://github.com/mikefarah/yq?tab=readme-ov-file#install) installed in your jumphost.

Clone this repo and follow the steps below. 
```
git clone https://github.com/nkunnath/nkp-ndk-quickstart.git && cd nkp-ndk-quickstart/airgapped/
```

1. Download the NDK airgapped bundle from Nutanix portal.
```
./0-get-ndk.sh
```
<br>

2. Load the NDK images from the bundle into Docker.
```
./1-load-ndk-images.sh
```
<br>
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

```
kubectl create secret generic my-mirror-ca-cert \
  --namespace=<WORKSPACE_NAMESPACE>
  --from-file=ca.crt=registry-ca.crt
```

> - To add image registry credentials and/or CA certificate, specify the following configuration in the Cluster object of the NKP cluster(s):

```
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  name: <NAME>
spec:
  topology:
    variables:
      - name: clusterConfig
        value:
          imageRegistries:
            - url: https://my-registry.io
              credentials:
                secretRef:
                  name: my-mirror-ca-cert
```

> ---
> If installing on OpenShift:
> ---
> Follow this guide: https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/registry/index#images-configuration-cas_configuring-registry-operator

<br>
4. Install NDK in the K8s clusters.
```
./3-helm-install-ndk.sh 
```