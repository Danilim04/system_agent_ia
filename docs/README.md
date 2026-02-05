# Sistema de Atendimento - Chatwoot + n8n + Evolution API

Sistema integrado de atendimento ao cliente com automação de workflows e integração com WhatsApp.

## 📋 Visão Geral

| Serviço | Descrição | Variável `.env` |
|---------|-----------|----------------|
| **Chatwoot** | Plataforma de atendimento ao cliente | `CHATWOOT_HOST` |
| **n8n** | Automação de workflows | `N8N_HOST` |
| **Evolution API** | Integração com WhatsApp | `EVOLUTION_HOST` |
| **MinIO** | Armazenamento de arquivos (S3) | `MINIO_HOST` |
| **Portainer** | Monitoramento de containers | `MINIO_HOST` + `/monitoramento` |

## 🏗️ Arquitetura

O projeto usa **Docker Swarm** com duas stacks:

```
┌─────────────────────────────────────────────────────────────┐
│                        STACK: infra                         │
├─────────────────────────────────────────────────────────────┤
│  Traefik (Reverse Proxy + SSL)                              │
│  PostgreSQL (Database + pgvector)                           │
│  Redis (Cache + Queue)                                      │
│  Portainer (Monitoramento)                                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        STACK: app                           │
├─────────────────────────────────────────────────────────────┤
│  n8n + n8n-worker (Automação)                               │
│  Chatwoot-web + Chatwoot-worker (Atendimento)               │
│  Evolution API (WhatsApp)                                   │
│  MinIO (Storage S3)                                         │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Estrutura de Pastas

```
.
├── stacks/                 # Definições das stacks Docker Swarm
│   ├── infra.yml          # Stack de infraestrutura
│   └── app.yml            # Stack de aplicações
├── config/                 # Arquivos de configuração
│   ├── traefik/
│   │   └── dynamic/
│   │       └── tls.yml    # Configuração TLS
│   ├── postgres/
│   │   └── init.sql       # Script de inicialização do banco
│   └── chatwoot/
│       └── trigger.rb     # Webhook handler customizado
├── data/                   # Dados persistentes (gitignored)
├── docs/                   # Documentação adicional
├── .env.example           # Template de variáveis de ambiente
├── .env                   # Suas configurações (não versionado)
├── Makefile               # Comandos simplificados
└── README.md              # Este arquivo
```

## 🚀 Quick Start

### 1. Pré-requisitos

- Docker 24.0+
- Docker Compose v2.20+
- Domínios configurados apontando para o servidor

### 2. Configuração

```bash
# Clone o repositório
git clone <seu-repositorio>
cd system_agent_ia

# Copie e edite as configurações
cp .env.example .env
nano .env  # ou vim, code, etc.
```

### 3. Deploy

```bash
# Inicializa Docker Swarm e cria .env
make init

# Deploy completo
make deploy
```

### 4. Migrações do Chatwoot (primeiro deploy)

```bash
make migrate
```

## 📖 Comandos Disponíveis

```bash
# Ver todos os comandos
make help

# Deploy
make deploy            # Deploy completo (infra + app)
make deploy-infra      # Deploy apenas infraestrutura
make deploy-app        # Deploy apenas aplicações

# Parar serviços
make down              # Para tudo
make down-app          # Para apenas apps
make down-infra        # Para apenas infra

# Monitoramento
make status            # Status de todos os serviços
make ps                # Lista containers
make logs-chatwoot     # Logs do Chatwoot
make logs-n8n          # Logs do n8n
make logs-evolution    # Logs da Evolution API

# Manutenção
make migrate           # Roda migrações do Chatwoot
make restart           # Reinicia tudo
make clean             # Remove volumes órfãos
```

## 🔧 Deploy em Novo Servidor

1. **Instale Docker**:
   ```bash
   curl -fsSL https://get.docker.com | sh
   ```

2. **Clone o projeto**:
   ```bash
   git clone <repositorio>
   cd system_agent_ia
   ```

3. **Configure o ambiente**:
   ```bash
   cp .env.example .env
   # Edite .env com suas configurações
   ```

4. **Configure DNS**:
   - Aponte seus domínios para o IP do servidor
   - Aguarde propagação DNS

5. **Deploy**:
   ```bash
   make init
   make deploy
   make migrate  # Primeira vez apenas
   ```

## 🔐 Segurança

- Todos os serviços são acessados via HTTPS (Let's Encrypt automático)
- Redis e PostgreSQL não são expostos externamente
- Portainer requer autenticação (configure no primeiro acesso)
- Evolution API usa API Key para autenticação

## 📊 Monitoramento

Acesse o Portainer em `https://<MINIO_HOST>/monitoramento`:

1. No primeiro acesso, crie um usuário admin
2. Visualize containers, logs, recursos, volumes
3. Gerencie stacks diretamente pela interface

## 🔄 Backup

### Volumes importantes:
- `infra_postgres_data` - Banco de dados
- `infra_redis_data` - Cache e filas
- `app_n8n_data` - Workflows do n8n
- `app_chatwoot_storage` - Arquivos do Chatwoot
- `app_minio_data` - Arquivos S3
- `app_evolution_data` - Dados do WhatsApp

### Backup do PostgreSQL:
```bash
docker exec $(docker ps -q -f name=infra_postgres) \
  pg_dumpall -U admin > backup_$(date +%Y%m%d).sql
```

## 🐛 Troubleshooting

### Serviço não inicia
```bash
make logs-<servico>  # Ver logs
make status          # Ver status
```

### Certificado SSL não gerado
- Verifique se os domínios estão apontando corretamente
- Verifique os logs do Traefik: `make logs-traefik`

### Chatwoot não conecta ao banco
```bash
make migrate  # Roda migrações
```

## 📝 Licença

Projeto interno
