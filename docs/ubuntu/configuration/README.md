Install k3s and helm

```shell
ssh root@192.168.1.24 'bash -s' < install_k3s_helm.sh

ssh root@192.168.1.24 'bash -s' < setup-k3s-external.sh 192.168.1.24 6443
cat ~/.kube/config | base64 -w 0
#OR
sudo cat /etc/rancher/k3s/k3s.yaml | sed 's/127.0.0.1/<YOUR_SERVER_IP>/g' | base64 -w 0

ssh root@192.168.1.244 'bash -s' < setup-ghcr-k3s.sh github_login ghp_xxxxxxxxxxxxxxxxxxxxxxxx
```