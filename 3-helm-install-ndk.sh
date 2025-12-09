#!/usr/bin/env bash

#------------------------------------------------------------------------------

# Copyright 2024 Nutanix, Inc
#
# Licensed under the MIT License;
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”),
# to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#------------------------------------------------------------------------------

# Maintainer:   Eric De Witte (eric.dewitte@nutanix.com)
# Contributors: 

#------------------------------------------------------------------------------


#check if ndkimagerepo file present 
if [[ ! -e "./ndkimagerepo" ]]; then
    echo "ndkimagerepo file not present. please 2-push-ndk.sh first. exiting."
    exit 1
fi

#Get cluster context
CONTEXTS=$(kubectl config get-contexts --output=name)
echo
echo "Select the cluster on which to install NDK or CTRL-C to quit"
select CONTEXT in $CONTEXTS; do 
    echo "you selected cluster context : ${CONTEXT}"
    echo 
    CLUSTERCTX="${CONTEXT}"
    break
done

kubectl config use-context $CLUSTERCTX

export CLUSTER_NAME=$(kubectl get cm kubeadm-config -n kube-system -o yaml |yq e '.data.ClusterConfiguration' |yq e '.clusterName')
export CLUSTER_UUID=$(kubectl get ns kube-system -o json |jq -r '.metadata.uid') 
echo
echo "about to install Nutanix Data Services for Kubernetes on cluster : $CLUSTER_NAME - cluster UID : $CLUSTER_UUID"
echo "press enter to confirm or CTRL-C to cancel"
read

echo "Checking NDK "
k8sdir=$(ls -d ndk-*)
# Check if directory is empty
if [[ ! -d "$k8sdir" ]]; then
    echo "No k8s agent directory. Exiting."
    exit 1
fi

echo "Getting NDK chart version"
ChartName=$(yq e '.name' $k8sdir/chart/Chart.yaml)
if [ $? -ne 0 ]; then
    echo "Error getting chart name. Exiting."
    exit 1
fi

ChartVersion=$(yq e '.version' $k8sdir/chart/Chart.yaml)
if [ $? -ne 0 ]; then
    echo "Error getting chart version. Exiting."
    exit 1
fi

ReleaseName="$ChartName-$ChartVersion"
echo
echo "Helm chart : $ReleaseName"
echo

#Checking ntnx-system ns presence
kubectl get ns ntnx-system 
if [ $? -ne 0 ]; then
    echo "Namespace ntnx-system not present on cluster. Exiting."
    exit 1
fi

#Getting Nutanix PC creds for agent
CSICREDS=$(kubectl get secret nutanix-csi-credentials -n ntnx-system -o yaml |yq e '.data.key' |base64 -d)
CSIPC=$(echo $CSICREDS |awk -F ':' '{print $1}' )
CSIUSER=$(echo $CSICREDS |awk -F ':' '{print $3}' )
CSIPASSWD=$(echo $CSICREDS |awk -F ':' '{print $4}' )
NDKSECRET=nutanix-csi-credentials
if  [ $CSIUSER != "admin" ]; then
    echo "nutanix-csi-credentials user is not 'admin'."
    echo

    echo "Provide a user with admin privileges for NDK secret creation or press CTRL-C to cancel"
    read -rp "admin username: " adminusername < /dev/tty
    echo

    echo "Provide password for NDK secret creation or press CTRL-C to cancel"
    read -rsp "admin password: " adminpasswd < /dev/tty

    if [ -n "$adminpasswd" ];
    then
        kubectl create secret generic ndk-credentials -n ntnx-system --from-literal key="$CSIPC:9440:$adminusername:$adminpasswd"
        NDKSECRET=ndk-credentials
    else
        echo "admin password is empty. exiting"
        exit 1
    fi
fi


#Getting Nutanix PC creds for agent
NDKIMGREPO=$(cat "./ndkimagerepo")

#ndk manager
MGRREPO=$(echo "$NDKIMGREPO"  |grep /manager |awk -F ':' '{print $1}' )
MGRTAG=$(echo "$NDKIMGREPO"  |grep /manager |awk -F ':' '{print $2}')

#infra-manager
INFRAMGRREPO=$(echo "$NDKIMGREPO"  |grep /infra-manager |awk -F ':' '{print $1}' )
INFRAMGRTAG=$(echo "$NDKIMGREPO"  |grep /infra-manager |awk -F ':' '{print $2}')

#kubectl
KUBECTLREPO=$(echo "$NDKIMGREPO"  |grep /kubectl |awk -F ':' '{print $1}' )
KUBECTLTAG=$(echo "$NDKIMGREPO"  |grep /kubectl |awk -F ':' '{print $2}')

#job-scheduler
JOBREPO=$(echo "$NDKIMGREPO"  |grep /job |awk -F ':' '{print $1}' )
JOBTAG=$(echo "$NDKIMGREPO"  |grep /job |awk -F ':' '{print $2}')

#kube-rbac-proxy
KUBERBACREPO=$(echo "$NDKIMGREPO"  |grep /kube-rbac-proxy |awk -F ':' '{print $1}' )
KUBERBACTAG=$(echo "$NDKIMGREPO"  |grep /kube-rbac-proxy |awk -F ':' '{print $2}')

echo "Installing NDK..."

helm install ndk -n ntnx-system  $k8sdir/chart \
--set manager.repository=$MGRREPO \
--set manager.tag=$MGRTAG \
--set infraManager.repository=$INFRAMGRREPO \
--set infraManager.tag=$INFRAMGRTAG \
--set kubeRbacProxy.repository=$KUBERBACREPO \
--set kubeRbacProxy.tag=$KUBERBACTAG \
--set kubectl.repository=$KUBECTLREPO \
--set kubectl.tag=$KUBECTLTAG \
--set jobScheduler.repository=$JOBREPO \
--set jobScheduler.tag=$JOBTAG \
--set tls.server.clusterName=$CLUSTER_NAME \
--set config.secret.name=$NDKSECRET \
--set imageCredentials.credentials.registry="$registry:$registryrepo" \
--set imageCredentials.credentials.username="$registryuser" \
--set imageCredentials.credentials.password="$registrypasswd"

echo
echo "Waiting for NDK controller-manager pod to become Ready..."

MAX_RETRIES=120     # 120 seconds timeout
RETRY=0

while true; do
    # get pod name
    pod=$(kubectl get pods -n ntnx-system -o jsonpath="{.items[?(@.metadata.labels['app']=='ndk-controller-manager')].metadata.name}")

    if [[ -z "$pod" ]]; then
        echo "Pod not created yet... retry $RETRY/$MAX_RETRIES"
    else
        # check Ready condition
        ready=$(kubectl get pod "$pod" -n ntnx-system -o jsonpath="{.status.conditions[?(@.type=='Ready')].status}")
        echo "Pod: $pod Ready: $ready (retry $RETRY/$MAX_RETRIES)"

        if [[ "$ready" == "True" ]]; then
            echo "NDK is installed successfully and the controller-manager pod is Ready."
            break
        fi
    fi

    ((RETRY++))
    if [[ $RETRY -ge $MAX_RETRIES ]]; then
        echo "NDK installation failed: controller-manager pod did not become Ready in time."
        exit 1
    fi

    sleep 1
done


