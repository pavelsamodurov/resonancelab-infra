# Kubernetes Project

## Check chart
```shell
helm lint charts/ai-gateway

helm template ai-gateway charts/ai-gateway \
  -f charts/ai-gateway/values.yaml \
  -f environments/dev/ai-gateway.yaml | head -n 60
```
