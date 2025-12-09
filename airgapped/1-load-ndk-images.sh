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

echo "Checking NDK download"
ndkdir=$(ls -d ndk-*)
# Check if directory is empty
if [[ ! -d "$ndkdir" ]]; then
    echo "No NDK directory. Exiting."
    exit 1
fi

echo "Loading NDK in docker images"
ndktar=$(ls "$ndkdir"/ndk-*.tar | grep -v recipes)
if [[ ! -e "$ndktar" ]]; then
    echo "No main NDK tar found. Exiting."
    exit 1
fi


docker image load -i $ndktar
if [ $? -ne 0 ]; then
    echo "docker image ($ndktar) load. Exiting."
    exit 1
fi

#docker images -f reference=ndk
docker images |grep ndk 
echo