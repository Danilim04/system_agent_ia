# AGENT.md — Guia de Contexto e Regras do Projeto

> **Este arquivo é a fonte de verdade para qualquer agente (IA ou humano) que interaja com este projeto.**
> Leia-o integralmente antes de fazer qualquer alteração.

---

## 1. Visão Geral do Projeto

Sistema integrado de atendimento ao cliente, composto por:

| Serviço | Função | Imagem |
|---------|--------|--------|
| **Chatwoot** | Plataforma de atendimento (chat, tickets) | `chatwoot/chatwoot:v4.4.0` |
| **n8n** | Automação de workflows | `n8nio/n8n:latest` |
| **Evolution API** | Integração com WhatsApp | `evoapicloud/evolution-api:v2.3.6` |
| **MinIO** | Object storage compatível com S3 | `minio/minio:latest` |
| **Traefik** | Reverse proxy, SSL e roteamento | `traefik:v3.6.1` |
| **PostgreSQL** | Banco de dados (com pgvector) | `pgvector/pgvector:pg15` |
| **Redis** | Cache e fila de mensagens | `redis:7-alpine` |
| **Portainer** | Monitoramento de containers | `portainer/portainer-ce:latest` |

**Todos os domínios são configuráveis via `.env`.** Nenhum domínio é hardcoded nas stacks.

---

## 2. Arquitetura

### 2.1 Orquestração: Docker Swarm

O projeto roda em **Docker Swarm** (não Docker Compose puro). O deploy é feito via `docker stack deploy`. O Makefile abstrai os comandos.

### 2.2 Duas Stacks Separadas

```
┌─────────────────────────────────────────────────────────────┐
│                    STACK: infra                              │
│  (deploy primeiro — os apps dependem dela)                  │
├─────────────────────────────────────────────────────────────┤
│  Traefik    → Reverse Proxy + TLS (Let's Encrypt)           │
│  PostgreSQL → Banco de dados compartilhado (pgvector)       │
│  Redis      → Cache + filas (compartilhado)                 │
│  Portainer  → UI de monitoramento                           │
└─────────────────────────────────────────────────────────────┘
                           │
                   rede: shared_network (overlay)
                           │
┌─────────────────────────────────────────────────────────────┐
│                     STACK: app                              │
│  (deploy depois — usa a rede criada pela infra)             │
├─────────────────────────────────────────────────────────────┤
│  MinIO + minio-init   → Storage S3                          │
│  n8n + n8n-worker     → Automação (queue mode com Redis)    │
│  chatwoot-web + chatwoot-worker → Atendimento               │
│  Evolution API        → WhatsApp                            │
└─────────────────────────────────────────────────────────────┘
```

**Regra fundamental:** A stack `infra` cria a rede `shared_network` (overlay, attachable). A stack `app` a consome como `external: true`. Sempre faça deploy da infra primeiro.

### 2.3 Rede

- **Nome:** `shared_network`
- **Driver:** `overlay` (attachable)
- **Definida em:** `stacks/infra.yml` (networks.network)
- **Referenciada em:** `stacks/app.yml` como `external: true`
- Todos os serviços de ambas as stacks estão nesta rede.

### 2.4 Comunicação Interna entre Serviços

- Serviços se comunicam pelo **nome do serviço** como hostname DNS dentro da rede overlay.
- Alguns serviços possuem **aliases** para comunicação interna:
  - `chatwoot-web` → alias `chatwoot-internal` (usado pela Evolution API)
  - `evolution-api` → alias `evolution-internal`
- Serviços da stack `infra` são referenciados pelo nome simples: `postgres`, `redis`.
- **Nenhum serviço de banco ou cache é exposto externamente.** Apenas Traefik expõe portas 80/443.

---

## 3. Estrutura de Pastas

```
system_agent_ia/
├── AGENT.md               # ← ESTE ARQUIVO (contexto para agentes)
├── Makefile               # Comandos simplificados (make deploy, make logs-*, etc.)
├── README.md              # Documentação resumida
├── .env.example           # Template de variáveis de ambiente
├── .env                   # Variáveis reais (NÃO versionado)
├── .gitignore
│
├── stacks/                # Definições Docker Swarm
│   ├── infra.yml          # Stack de infraestrutura (traefik, postgres, redis, portainer)
│   └── app.yml            # Stack de aplicações (n8n, chatwoot, evolution, minio)
│
├── config/                # Arquivos de configuração montados nos containers
│   ├── traefik/
│   │   └── dynamic/
│   │       └── tls.yml    # Cipher suites e versão mínima TLS
│   ├── postgres/
│   │   └── init.sql       # Script de criação dos bancos (n8n_db, chatwoot_db, evolution_db)
│   └── chatwoot/
│       └── trigger.rb     # Override do webhook trigger do Chatwoot (timeout 25s)
│
├── data/                  # Volumes locais (gitignored)
├── minio-data/            # Dados do MinIO (gitignored)
└── docs/
    └── README.md          # Documentação detalhada
```

---

## 4. Padrões e Convenções

### 4.1 Stacks YAML

| Regra | Detalhe |
|-------|---------|
| **Localização** | Toda stack YAML fica em `stacks/` |
| **Duas stacks** | `infra.yml` para infra, `app.yml` para apps. Novos serviços de app vão em `app.yml` |
| **Formato** | Docker Compose v3 com extensões Swarm (`deploy:`) |
| **Comentários** | Cada serviço tem um bloco de cabeçalho com `# ===` delimitadores e nome/descrição |
| **Indentação** | 2 espaços |

### 4.2 Deploy Config (obrigatório em todo serviço)

Todo serviço DEVE ter o bloco `deploy:` completo:

```yaml
deploy:
  mode: replicated
  replicas: 1
  update_config:
    parallelism: 1
    delay: 10s
    failure_action: rollback
  restart_policy:
    condition: on-failure
    delay: 5s
    max_attempts: 3
  resources:
    limits:
      memory: <LIMITE>
      cpus: "<LIMITE>"       # ← SEMPRE entre aspas (string)
    reservations:
      memory: <MÍNIMO>
      cpus: "<MÍNIMO>"       # ← SEMPRE entre aspas (string)
```

### 4.3 Traefik Labels (roteamento)

Todo serviço exposto externamente DEVE ter labels Traefik no bloco `deploy.labels`:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.<NOME>.rule=Host(`${VARIAVEL_HOST}`)"
  - "traefik.http.routers.<NOME>.entrypoints=websecure"
  - "traefik.http.routers.<NOME>.tls=true"
  - "traefik.http.routers.<NOME>.tls.certresolver=letsencrypt"
  - "traefik.http.services.<NOME>.loadbalancer.server.port=<PORTA>"
```

- O `<NOME>` do router/service deve ser único e representar o serviço.
- O host vem de variável de ambiente `${VARIAVEL_HOST}` definida no `.env`.
- Entrypoint é **sempre** `websecure` (HTTPS). O redirect HTTP→HTTPS é global no Traefik.
- TLS usa o resolver `letsencrypt` (ACME HTTP challenge).

### 4.4 Variáveis de Ambiente

| Regra | Detalhe |
|-------|---------|
| **Nunca hardcode segredos** | Use `${VARIAVEL}` referenciando `.env` || **Nunca hardcode domínios** | Todos os hosts vem de variáveis: `N8N_HOST`, `CHATWOOT_HOST`, `EVOLUTION_HOST`, `MINIO_HOST`, `MINIO_CONSOLE_HOST`, `TRAEFIK_HOST` || **Template** | Toda nova variável deve ser adicionada ao `.env.example` com valor placeholder |
| **Encoded** | Senhas usadas em URIs precisam de versão `_ENCODED` (URL-encoded) |
| **Defaults** | Use `${VAR:-default}` quando houver valor sensato padrão |
| **Agrupamento** | Variáveis no `.env.example` são agrupadas por seção com comentários `# ---` |

### 4.5 Volumes

| Regra | Detalhe |
|-------|---------|
| **Nomeação** | `<stack>_<serviço>_<finalidade>`. Ex: `app_n8n_data`, `infra_postgres_data` |
| **Declaração** | Cada volume usa `name:` explícito na seção `volumes:` da stack |
| **Config files** | Montados via bind mount com caminho absoluto e `:ro` quando possível |
| **Dados locais** | Diretório `data/` e `minio-data/` estão no `.gitignore` |

### 4.6 Configurações Customizadas

- Ficam em `config/<serviço>/`
- São montadas nos containers via bind mount (path absoluto do host)
- Exemplo: `config/chatwoot/trigger.rb` é montado como override no container Chatwoot

### 4.7 PostgreSQL — Bancos Compartilhados

Uma única instância PostgreSQL serve múltiplos serviços, cada um com seu banco:

| Banco | Serviço | Variável |
|-------|---------|----------|
| `n8n_db` | n8n | `POSTGRES_DB_N8N` |
| `chatwoot_db` | Chatwoot | `CHATWOOT_DB_NAME` |
| `evolution_db` | Evolution API | `EVOLUTION_DB_NAME` |

Novos bancos devem ser criados em `config/postgres/init.sql` e variáveis adicionadas ao `.env.example`.

### 4.8 Redis — Compartilhado com DB Index

Redis é compartilhado. Cada serviço usa um **DB index** diferente:

| DB | Serviço |
|----|---------|
| `0` | n8n (queue) |
| `1` | Evolution API (cache) |
| default | Chatwoot (via URL sem db index) |

Ao adicionar novo serviço que use Redis, **use um DB index que não conflite**.

### 4.9 Healthchecks

Serviços de infraestrutura (postgres, redis, minio) DEVEM ter `healthcheck:` definido.

### 4.10 Makefile

- Todos os comandos operacionais estão no `Makefile`.
- Novos serviços devem ganhar um target `logs-<serviço>`.
- O deploy usa um pipeline: `docker compose config | sed fix | docker stack deploy`.
- O `sed` fix é necessário porque `docker compose config` gera `cpus` como float e `published` como string, mas `docker stack deploy` espera o inverso.

---

## 5. Como Implementar um Novo Serviço

Siga este checklist ao adicionar qualquer novo serviço:

### 5.1 Checklist

- [ ] **1. Definir o serviço em `stacks/app.yml`** (ou `infra.yml` se for infraestrutura)
- [ ] **2. Adicionar bloco `deploy:`** completo (ver padrão 4.2)
- [ ] **3. Adicionar labels Traefik** se o serviço for exposto externamente (ver padrão 4.3)
- [ ] **4. Adicionar variáveis no `.env.example`** com placeholders e comentários
- [ ] **5. Adicionar variáveis no `.env`** com valores reais
- [ ] **6. Criar banco de dados** (se necessário) em `config/postgres/init.sql`
- [ ] **7. Definir volume nomeado** na seção `volumes:` com `name: <stack>_<servico>_data`
- [ ] **8. Adicionar à rede** `shared_network` (se app) ou `network` (se infra)
- [ ] **9. Adicionar `logs-<servico>`** no Makefile
- [ ] **10. Adicionar alias de rede** se outros serviços precisam se conectar por nome amigável
- [ ] **11. Documentar** no `docs/README.md` (tabela de serviços + URLs)
- [ ] **12. Testar** com `make deploy-app` (ou `deploy-infra`) e verificar com `make status`

### 5.2 Template de Serviço

```yaml
  # =============================================================================
  # NOVO-SERVICO - Descrição breve
  # =============================================================================
  novo-servico:
    image: imagem/servico:tag-fixa
    deploy:
      mode: replicated
      replicas: 1
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      resources:
        limits:
          memory: 1G
          cpus: "0.5"
        reservations:
          memory: 256M
          cpus: "0.1"
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.novo-servico.rule=Host(`${NOVO_SERVICO_HOST}`)"
        - "traefik.http.routers.novo-servico.entrypoints=websecure"
        - "traefik.http.routers.novo-servico.tls=true"
        - "traefik.http.routers.novo-servico.tls.certresolver=letsencrypt"
        - "traefik.http.services.novo-servico.loadbalancer.server.port=<PORTA>"
    environment:
      # Database (se necessário)
      DATABASE_URL: "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD_ENCODED}@postgres:5432/${NOVO_SERVICO_DB_NAME}"
      # Redis (se necessário — use DB index livre)
      REDIS_URL: "redis://:${REDIS_PASSWORD_ENCODED}@redis:6379/<DB_INDEX>"
      # Variáveis específicas
      NOVO_SERVICO_API_KEY: ${NOVO_SERVICO_API_KEY}
    volumes:
      - novo_servico_data:/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:<PORTA>/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    networks:
      shared_network:
        aliases:
          - novo-servico-internal  # Apenas se necessário
```

### 5.3 Template para `.env.example`

```dotenv
# -----------------------------------------------------------------------------
# NOVO SERVIÇO - Descrição
# URL: https://novo-servico.seudominio.com.br
# -----------------------------------------------------------------------------
NOVO_SERVICO_HOST=novo-servico.seudominio.com.br
NOVO_SERVICO_DB_NAME=novo_servico_db
NOVO_SERVICO_API_KEY=SUA_API_KEY_AQUI
```

### 5.4 Template para `config/postgres/init.sql`

Adicionar ao final do `init.sql`:

```sql
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'novo_servico_db') THEN
        CREATE DATABASE novo_servico_db;
        RAISE NOTICE 'Database novo_servico_db created';
    END IF;
END $$;

GRANT ALL PRIVILEGES ON DATABASE novo_servico_db TO admin;
```

### 5.5 Template para Makefile

Adicionar um target de logs:

```makefile
logs-novo-servico:
	@docker service logs -f --tail 100 $(APP_STACK)_novo-servico
```

---

## 6. Regras para Agentes de IA

### 6.1 Antes de Qualquer Alteração

1. **Leia este arquivo inteiro** para entender o contexto.
2. **Leia o arquivo que vai alterar** para entender o estado atual.
3. **Nunca crie stacks ou compose files novos** — use os existentes (`infra.yml`, `app.yml`).
4. **Nunca altere a estrutura de rede** sem motivo explícito.

### 6.2 Ao Editar Stacks

- Mantenha os blocos de comentários `# ===` como separadores de serviço.
- Respeite a ordem: volumes depois de services, networks no final.
- Valores de `cpus` SEMPRE entre aspas: `cpus: "0.5"` (nunca `cpus: 0.5`).
- Tags de imagem devem ser **fixas** para serviços críticos (chatwoot, evolution). Use `latest` apenas para ferramentas utilitárias (minio, n8n).

### 6.3 Ao Editar `.env` ou `.env.example`

- Mantenha o agrupamento por seções com comentários `# ---`.
- Toda variável nova no `.env` deve ser espelhada no `.env.example` com placeholder.
- Senhas com caracteres especiais precisam de versão `_ENCODED`.

### 6.4 Ao Editar Makefile

- Use tabs (não espaços) para indentação dos comandos.
- Mantenha cores nos outputs (`$(GREEN)`, `$(RED)`, etc.).
- Use as variáveis `$(INFRA_STACK)` e `$(APP_STACK)` ao invés de hardcode.
- Adicione novos targets ao `.PHONY` no topo do arquivo.

### 6.5 Ao Editar configs em `config/`

- Bind mounts usam caminho absoluto do repositório no host: `<REPO_PATH>/config/...`.
- O path atual é definido nos YAMLs — ao mover o projeto, ajustar os bind mounts.
- Monte como `:ro` (read-only) sempre que o container não precise escrever.

### 6.6 Deploy e Testes

- Deploy de teste: `make deploy-app` (ou `make deploy-infra`).
- Verificar status: `make status`.
- Ver logs: `make logs-<servico>`.
- O pipeline de deploy faz `docker compose config` → `sed` fix → `docker stack deploy`.

---

## 7. Referência Rápida de Comandos

```bash
make init              # Inicializa Docker Swarm + cria .env
make deploy            # Deploy completo (infra → wait → app)
make deploy-infra      # Deploy só infraestrutura
make deploy-app        # Deploy só aplicações
make down              # Para tudo
make down-app          # Para só apps
make down-infra        # Para só infra
make status            # Status dos serviços
make ps                # Lista containers
make logs-<servico>    # Logs de um serviço (traefik, postgres, redis, portainer, minio, n8n, n8n-worker, chatwoot, chatwoot-worker, evolution)
make migrate           # Migrações do Chatwoot
make restart           # Restart completo (down + deploy)
make clean             # Remove volumes órfãos
```

---

## 8. URLs do Ambiente (configuráveis via `.env`)

Todas as URLs são definidas por variáveis de ambiente no `.env`. Nenhum domínio é hardcoded.

| Serviço | Variável `.env` | Exemplo |
|---------|----------------|--------|
| Chatwoot | `CHATWOOT_HOST` | `https://chatwoot.seudominio.com.br` |
| n8n | `N8N_HOST` | `https://n8n.seudominio.com.br` |
| Evolution API | `EVOLUTION_HOST` | `https://evolution.seudominio.com.br` |
| MinIO API | `MINIO_HOST` | `https://minio.seudominio.com.br` |
| MinIO Console | `MINIO_CONSOLE_HOST` | `https://minio-console.seudominio.com.br` |
| Portainer | `MINIO_HOST` + `/monitoramento` | `https://minio.seudominio.com.br/monitoramento` |
| Traefik Dashboard | `TRAEFIK_HOST` | `https://traefik.seudominio.com.br` |
| Let's Encrypt (email) | `ACME_EMAIL` | `admin@seudominio.com.br` |

---

## 9. Segurança — Regras Invioláveis

1. **PostgreSQL e Redis NUNCA são expostos** em portas públicas. Acesso apenas via rede overlay.
2. **HTTPS obrigatório** para todo serviço externo. Redirect HTTP→HTTPS é global.
3. **Segredos vão no `.env`**, nunca hardcoded nas stacks.
4. **`.env` nunca é commitado** (está no `.gitignore`).
5. **TLS mínimo 1.2** com cipher suites seguras (configurado em `config/traefik/dynamic/tls.yml`).
6. Bind mounts de config são `:ro` quando possível.

---

## 10. Mapa de Dependências entre Serviços

```
postgres ←── n8n
         ←── chatwoot-web
         ←── chatwoot-worker
         ←── evolution-api

redis    ←── n8n (queue mode, DB 0)
         ←── n8n-worker (queue mode, DB 0)
         ←── chatwoot-web (sidekiq)
         ←── chatwoot-worker (sidekiq)
         ←── evolution-api (cache, DB 1)

minio    ←── evolution-api (S3 storage)
         ←── minio-init (cria buckets)

chatwoot-web (alias: chatwoot-internal) ←── evolution-api (webhook)

traefik  ←── todos os serviços com label traefik.enable=true
```

---

## 11. Portabilidade

Este projeto é **100% portável** para qualquer domínio, servidor ou empresa.

Para implantar em um novo ambiente:

1. Clone o repositório
2. Copie `.env.example` → `.env`
3. Preencha `.env` com os domínios e senhas do novo ambiente
4. Ajuste os bind mounts em `stacks/*.yml` se o path do repositório no host mudar
5. `make init && make deploy && make migrate`

**Nenhum arquivo versionado contém domínios, senhas ou dados específicos de empresa.**
Toda configuração específica fica no `.env` (que não é versionado).

---

*Última atualização: Fevereiro 2026*
