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

#Get cluster context
CONTEXTS=$(kubectl config get-contexts  --no-headers=true |awk '{print $2}')
echo
echo "Select cluster on which to UNINSTALL NDK or CTRL-C to quit"
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
echo "About to UNINSTALL Nutanix Data Services for Kubernetes on cluster : $CLUSTER_NAME - cluster UID : $CLUSTER_UUID"
echo "Press enter to confirm or CTRL-C to cancel"
read

#Checking ntnx-system ns presence
kubectl get ns ntnx-system 
if [ $? -ne 0 ]; then
    echo "Namespace ntnx-system not present on cluster. Exiting."
    exit 1
fi

helm uninstall -n ntnx-system  ndk
if [ $? -ne 0 ]; then
    echo "helm uninstall error. Exiting."
    exit 1
fi

kubectl delete secret ndk-credentials -n ntnx-system 
