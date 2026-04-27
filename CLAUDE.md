# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Collaboration Protocol

1. When asked a question or given a task — analyse, propose 2–3 solution variants with pros/cons, recommend one, ask about any open options upfront.
2. Wait for explicit approval before implementing.
3. Commit only when explicitly asked by the user.
4. Add code comments only when explicitly asked.

## Overview

Infrastructure repository for ResonanceLab — a Kubernetes-based platform. The cluster runs on K3s (Ubuntu). Services are deployed via GitHub Actions to `dev` and `prod` environments.

## Architecture

```
resonancelab-infra/
├── .github/workflows/       # GitHub Actions (deploy, lint, bootstrap, teardown)
├── charts/ai-gateway/       # Helm chart for the AI Gateway (Spring Boot) service
├── infrastructure/          # Raw Kubernetes manifests for stateful/support services
│   ├── cert-manager/        # ClusterIssuer configs for Let's Encrypt
│   ├── environments/        # Environment-specific manifests (dev/prod)
│   ├── ollama/              # Local LLM inference engine (qwen2.5:3b)
│   ├── pgadmin/             # PostgreSQL admin UI
│   └── postgres/            # PostgreSQL with pgvector extension
├── environments/            # Per-environment Helm values for ai-gateway
│   ├── dev/                 # dev.resonancelab.cc, letsencrypt-staging, DEBUG logging
│   └── prod/                # resonancelab.cc, letsencrypt-prod, higher resource limits
└── docs/ubuntu/             # K3s cluster bootstrap scripts
```

## Two Deployment Strategies

**Helm** — used for the AI Gateway application service:
- Chart lives in `charts/ai-gateway/`
- Environment overrides in `environments/{dev,prod}/values.yaml`
- Deployed via `deploy-reusable.yaml` workflow (callable or manual)
- Secrets injected at deploy time: `DEEPSEEK_API_KEY`, `GROQ_API_KEY`, `DEEPINFRA_API_KEY`, DB credentials
- App config files injected via `--set-file`

**kubectl apply** — used for stateful/support infrastructure:
- Component directories: `infrastructure/{postgres,pgadmin,ollama}/`
- Environment selection via namespace (`dev` / `prod`)
- Deployed via `deploy-infrastructure.yaml` workflow
- Uses `yq` + `envsubst` for value substitution at deploy time

## GitHub Actions Workflows

| Workflow | Trigger | Purpose |
|---|---|---|
| `bootstrap-ingress.yaml` | manual | One-time: installs ingress-nginx, cert-manager, ClusterIssuers |
| `deploy-infrastructure.yaml` | manual | Deploys postgres / pgadmin / ollama to dev or prod |
| `deploy-reusable.yaml` | manual / callable | Deploys ai-gateway Helm chart |
| `helm-lint.yaml` | PR on `charts/**` or `environments/**` | Lints chart and dry-runs for both envs |
| `teardown-infrastructure.yaml` | manual | Removes components and cleans up secrets/configmaps |

## Environment Differences

| | dev | prod |
|---|---|---|
| Ingress | `dev.resonancelab.cc/dev/ai-gateway` | `resonancelab.cc/ai-gateway` |
| TLS issuer | `letsencrypt-staging` | `letsencrypt-prod` |
| AI-Gateway CPU | 50m req / 200m limit | 200m req / 1000m limit |
| AI-Gateway memory | 128Mi req / 256Mi limit | 384Mi req / 1024Mi limit |
| Webhook subscriptions | disabled | enabled |

## Key Patterns

**Ingress:** nginx with `rewrite-target` annotations, proxy timeouts set to 3600s (SSE streaming), proxy buffering disabled, cert-manager annotation for automatic TLS.

**Persistent storage:** PostgreSQL StatefulSet — 5Gi PVC. Ollama — 10Gi PVC for model cache.

**Internal DNS:** `postgres:5432`, `ollama:11434`

**Secrets:** All sensitive values (API keys, DB passwords, Cloudflare token) live in GitHub Actions secrets and are injected into Kubernetes Secrets at deploy time. Never committed to the repo.

**cert-manager:** DNS-01 challenge via Cloudflare API token. Two ClusterIssuers: `letsencrypt-staging` (testing) and `letsencrypt-prod`.

## Cluster Setup

See `docs/ubuntu/configuration/` for K3s installation and GHCR credentials setup scripts.
