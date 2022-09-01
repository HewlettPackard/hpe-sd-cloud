#!/bin/bash

# save incoming YAML to file
cat <&0 > all.yaml

# modify the YAML with kubectl's built-in kustomize
kubectl kustomize . && rm all.yaml