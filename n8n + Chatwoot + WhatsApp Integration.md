# n8n + Chatwoot + WhatsApp Integration

Solução completa para automação de workflows com integração WhatsApp usando Docker Compose.

## 🚀 Características

- **Simples**: Deploy com um comando
- **Escalável**: Serviços separados e configuráveis
- **Seguro**: HTTPS automático, autenticação e senhas seguras
- **Completo**: n8n + Chatwoot + Evolution API + Redis + PostgreSQL

## 📋 Pré-requisitos

- Docker & Docker Compose
- Domínio configurado (subdomínios apontando para o servidor)
- Portas 80 e 443 liberadas

## 🛠️ Instalação

1. **Clone e configure:**
```bash
git clone <repository>
cd whatsapp-automation
chmod +x scripts/*.sh
./scripts/setup.sh