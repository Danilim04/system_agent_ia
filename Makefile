# =============================================================================
# Makefile - Comandos simplificados para gerenciamento do projeto
# =============================================================================
# Uso: make <comando>
# Exemplos:
#   make deploy        - Deploy completo (infra + app)
#   make logs-chatwoot - Ver logs do Chatwoot
#   make status        - Ver status de todos os serviços
# =============================================================================

.PHONY: help init deploy deploy-infra deploy-app down down-infra down-app \
        status logs migrate restart ps clean

# Cores para output
RED    := \033[0;31m
GREEN  := \033[0;32m
YELLOW := \033[0;33m
BLUE   := \033[0;34m
NC     := \033[0m # No Color

# Variáveis
STACK_DIR := stacks
INFRA_STACK := infra
APP_STACK := app
STACK_NAME := oivox

# =============================================================================
# HELP
# =============================================================================
help:
	@echo ""
	@echo "$(BLUE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║     Sistema de Atendimento - Chatwoot + n8n + Evolution      ║$(NC)"
	@echo "$(BLUE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)Comandos disponíveis:$(NC)"
	@echo ""
	@echo "  $(YELLOW)Inicialização:$(NC)"
	@echo "    make init              - Inicializa Docker Swarm e copia .env"
	@echo ""
	@echo "  $(YELLOW)Deploy:$(NC)"
	@echo "    make deploy            - Deploy completo (infra + app)"
	@echo "    make deploy-infra      - Deploy apenas infraestrutura"
	@echo "    make deploy-app        - Deploy apenas aplicações"
	@echo ""
	@echo "  $(YELLOW)Parar serviços:$(NC)"
	@echo "    make down              - Para tudo (app + infra)"
	@echo "    make down-app          - Para apenas aplicações"
	@echo "    make down-infra        - Para apenas infraestrutura"
	@echo ""
	@echo "  $(YELLOW)Monitoramento:$(NC)"
	@echo "    make status            - Status de todos os serviços"
	@echo "    make ps                - Lista todos os containers"
	@echo "    make logs              - Logs de todos os serviços"
	@echo "    make logs-SERVICE      - Logs de um serviço específico"
	@echo ""
	@echo "  $(YELLOW)Manutenção:$(NC)"
	@echo "    make migrate           - Roda migrações do Chatwoot"
	@echo "    make restart           - Reinicia todos os serviços"
	@echo "    make clean             - Remove volumes órfãos"
	@echo ""
	@echo "$(BLUE)Serviços disponíveis para logs:$(NC)"
	@echo "  traefik, postgres, redis, portainer, minio, n8n, chatwoot, evolution"
	@echo ""

# =============================================================================
# INICIALIZAÇÃO
# =============================================================================
init:
	@echo "$(BLUE)▶ Verificando Docker Swarm...$(NC)"
	@docker info --format '{{.Swarm.LocalNodeState}}' | grep -q 'active' || \
		(echo "$(YELLOW)Inicializando Docker Swarm...$(NC)" && docker swarm init)
	@echo "$(GREEN)✔ Docker Swarm ativo$(NC)"
	@echo ""
	@if [ ! -f .env ]; then \
		echo "$(YELLOW)▶ Criando arquivo .env a partir do template...$(NC)"; \
		cp .env.example .env; \
		echo "$(RED)⚠ IMPORTANTE: Edite o arquivo .env com suas configurações!$(NC)"; \
	else \
		echo "$(GREEN)✔ Arquivo .env já existe$(NC)"; \
	fi
	@echo ""
	@echo "$(GREEN)✔ Inicialização concluída!$(NC)"
	@echo "$(YELLOW)Próximo passo: make deploy$(NC)"

# =============================================================================
# DEPLOY
# =============================================================================
deploy: deploy-infra wait-infra deploy-app
	@echo ""
	@echo "$(GREEN)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║                    Deploy Completo! ✔                        ║$(NC)"
	@echo "$(GREEN)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(BLUE)URLs disponíveis:$(NC)"
	@echo "  • n8n:           https://$${N8N_HOST:-worflow.oivox.com.br}"
	@echo "  • Chatwoot:      https://$${CHATWOOT_HOST:-chatwoot.oivox.com.br}"
	@echo "  • Evolution API: https://$${EVOLUTION_HOST:-evolutionapi.oivox.com.br}"
	@echo "  • MinIO:         https://db.oivox.com.br"
	@echo "  • Monitoramento: https://db.oivox.com.br/monitoramento"
	@echo ""

# Função helper: docker compose config gera cpus como float e published como string,
# mas docker stack deploy espera cpus como string e published como integer
COMPOSE_FIX = sed 's/cpus: \([0-9.]*\)/cpus: "\1"/g' | sed 's/published: "\([0-9]*\)"/published: \1/g' | grep -v '^name: '

deploy-infra:
	@echo "$(BLUE)▶ Fazendo deploy da stack de infraestrutura...$(NC)"
	@docker compose -f $(STACK_DIR)/infra.yml --env-file .env config 2>/dev/null | $(COMPOSE_FIX) | docker stack deploy -c - $(INFRA_STACK)
	@echo "$(GREEN)✔ Stack $(INFRA_STACK) deployada$(NC)"

deploy-app:
	@echo "$(BLUE)▶ Fazendo deploy da stack de aplicações...$(NC)"
	@docker compose -f $(STACK_DIR)/app.yml --env-file .env config 2>/dev/null | $(COMPOSE_FIX) | docker stack deploy -c - $(APP_STACK)
	@echo "$(GREEN)✔ Stack $(APP_STACK) deployada$(NC)"

wait-infra:
	@echo "$(YELLOW)▶ Aguardando infraestrutura ficar pronta...$(NC)"
	@sleep 15
	@echo "$(GREEN)✔ Infraestrutura pronta$(NC)"

# =============================================================================
# PARAR SERVIÇOS
# =============================================================================
down: down-app down-infra
	@echo "$(GREEN)✔ Todos os serviços parados$(NC)"

down-app:
	@echo "$(BLUE)▶ Removendo stack de aplicações...$(NC)"
	@docker stack rm $(APP_STACK) 2>/dev/null || true
	@echo "$(GREEN)✔ Stack $(APP_STACK) removida$(NC)"

down-infra:
	@echo "$(BLUE)▶ Removendo stack de infraestrutura...$(NC)"
	@docker stack rm $(INFRA_STACK) 2>/dev/null || true
	@echo "$(GREEN)✔ Stack $(INFRA_STACK) removida$(NC)"

# =============================================================================
# MONITORAMENTO
# =============================================================================
status:
	@echo "$(BLUE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║                    Status dos Serviços                       ║$(NC)"
	@echo "$(BLUE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)Stack: $(INFRA_STACK)$(NC)"
	@docker stack services $(INFRA_STACK) 2>/dev/null || echo "Stack não encontrada"
	@echo ""
	@echo "$(YELLOW)Stack: $(APP_STACK)$(NC)"
	@docker stack services $(APP_STACK) 2>/dev/null || echo "Stack não encontrada"
	@echo ""

ps:
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

logs:
	@docker service logs -f --tail 100 $(filter-out $@,$(MAKECMDGOALS)) 2>/dev/null || \
		echo "Uso: make logs <nome-do-serviço>"

# Logs específicos por serviço
logs-traefik:
	@docker service logs -f --tail 100 $(INFRA_STACK)_traefik

logs-postgres:
	@docker service logs -f --tail 100 $(INFRA_STACK)_postgres

logs-redis:
	@docker service logs -f --tail 100 $(INFRA_STACK)_redis

logs-portainer:
	@docker service logs -f --tail 100 $(INFRA_STACK)_portainer

logs-minio:
	@docker service logs -f --tail 100 $(APP_STACK)_minio

logs-n8n:
	@docker service logs -f --tail 100 $(APP_STACK)_n8n

logs-n8n-worker:
	@docker service logs -f --tail 100 $(APP_STACK)_n8n-worker

logs-chatwoot:
	@docker service logs -f --tail 100 $(APP_STACK)_chatwoot-web

logs-chatwoot-worker:
	@docker service logs -f --tail 100 $(APP_STACK)_chatwoot-worker

logs-evolution:
	@docker service logs -f --tail 100 $(APP_STACK)_evolution-api

# =============================================================================
# MANUTENÇÃO
# =============================================================================
migrate:
	@echo "$(BLUE)▶ Rodando migrações do Chatwoot...$(NC)"
	@CONTAINER=$$(docker ps -q -f name=$(APP_STACK)_chatwoot-web); \
	if [ -n "$$CONTAINER" ]; then \
		docker exec $$CONTAINER bundle exec rails db:chatwoot_prepare; \
		echo "$(GREEN)✔ Migrações concluídas$(NC)"; \
	else \
		echo "$(RED)✘ Container do Chatwoot não encontrado$(NC)"; \
	fi

restart: down
	@sleep 5
	@$(MAKE) deploy

clean:
	@echo "$(BLUE)▶ Removendo volumes órfãos...$(NC)"
	@docker volume prune -f
	@echo "$(GREEN)✔ Limpeza concluída$(NC)"

# Permite passar argumentos para make logs
%:
	@:
