# Sistema de Atendimento - Chatwoot + n8n + Evolution API

Sistema integrado de atendimento ao cliente com automação de workflows e integração com WhatsApp.

## 🚀 Quick Start

```bash
# 1. Configure o ambiente
cp .env.example .env
nano .env

# 2. Inicialize e faça deploy
make init
make deploy

# 3. Rode migrações (primeira vez)
make migrate
```

## 📋 URLs dos Serviços

| Serviço | Variável no `.env` | Exemplo |
|---------|-------------------|---------|
| Chatwoot | `CHATWOOT_HOST` | `https://chatwoot.seudominio.com.br` |
| n8n | `N8N_HOST` | `https://n8n.seudominio.com.br` |
| Evolution API | `EVOLUTION_HOST` | `https://evolution.seudominio.com.br` |
| MinIO | `MINIO_HOST` | `https://minio.seudominio.com.br` |
| Monitoramento | `MINIO_HOST` + `/monitoramento` | `https://minio.seudominio.com.br/monitoramento` |

## 📖 Comandos Úteis

```bash
make help              # Ver todos os comandos
make status            # Status dos serviços
make logs-chatwoot     # Logs do Chatwoot
make logs-n8n          # Logs do n8n
make restart           # Reiniciar tudo
```

## 📁 Estrutura

```
stacks/           # Stacks Docker Swarm (infra.yml, app.yml)
config/           # Configurações (traefik, postgres, chatwoot)
data/             # Volumes (gitignored)
docs/             # Documentação completa
Makefile          # Comandos simplificados
```

📚 **Documentação completa**: [docs/README.md](docs/README.md)
