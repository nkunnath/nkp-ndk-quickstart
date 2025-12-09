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


CONTEXTS=$(kubectl config get-contexts --output=name)
echo
echo "Select the cluster on which to install Remote or CTRL-C to quit"
select CONTEXT in $CONTEXTS; do 
    echo "you selected cluster context : ${CONTEXT}"
    echo 
    CLUSTERCTX="${CONTEXT}"
    break
done

kubectl config use-context $CLUSTERCTX
if [ $? -ne 0 ]; then
    echo "kubectl context error. Exiting."
    exit 1
fi

echo
read -p "Enter NDK remote IP: " NDK_REMOTE_IP < /dev/tty
echo
read -p "Enter NDK remote instance name: " NDK_REMOTE_NAME < /dev/tty
echo



Remote="apiVersion: dataservices.nutanix.com/v1alpha1
kind: Remote
metadata:
  name: remote-${NDK_REMOTE_NAME}
spec:
  clusterName: ${NDK_REMOTE_NAME}
  ndkServiceIp: ${NDK_REMOTE_IP}
  ndkServicePort: 2021
  tlsConfig:
    skipTLSVerify: true"

YAMLFILE=remote-${NDK_REMOTE_NAME}.yaml

echo "$Remote" | yq e > $YAMLFILE
echo "$YAMLFILE created"
echo 
echo "run : kubectl apply -f $YAMLFILE to apply to cluster"
