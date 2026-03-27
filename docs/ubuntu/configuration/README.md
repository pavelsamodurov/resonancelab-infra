Install k3s and helm

```shell
ssh root@192.168.1.24 'bash -s' < install_k3s_helm.sh

ssh root@192.168.1.24 'bash -s' < setup-k3s-external.sh 192.168.1.24 6443

ssh root@192.168.1.244 'bash -s' < create-ghcr-secret.sh github_login ghp_xxxxxxxxxxxxxxxxxxxxxxxx
```