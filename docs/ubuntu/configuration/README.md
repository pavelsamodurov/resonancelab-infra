Install k3s and helm

```shell
ssh root@HOST 'bash -s' < install_k3s_helm.sh

k3s kubectl config set-cluster default \
  --server=https://0.0.0.0:6443
```