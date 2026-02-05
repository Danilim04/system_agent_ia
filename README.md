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

| Serviço | URL |
|---------|-----|
| Chatwoot | `https://chatwoot.oivox.com.br` |
| n8n | `https://worflow.oivox.com.br` |
| Evolution API | `https://evolutionapi.oivox.com.br` |
| MinIO | `https://db.oivox.com.br` |
| Monitoramento | `https://db.oivox.com.br/monitoramento` |

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
