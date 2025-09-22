#!/bin/bash
# scripts/setup.sh

echo "🚀 Setting up n8n + Chatwoot + WhatsApp Integration..."

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create directories
mkdir -p nginx/ssl scripts

# Generate encryption keys if not exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env
    
    # Generate secure keys
    N8N_KEY=$(openssl rand -hex 16)
    CHATWOOT_KEY=$(openssl rand -hex 32)
    EVOLUTION_KEY=$(openssl rand -hex 16)
    
    sed -i "s/your_32_character_encryption_key_here/$N8N_KEY/" .env
    sed -i "s/your_chatwoot_secret_key_base_here/$CHATWOOT_KEY/" .env
    sed -i "s/your_evolution_api_key_here/$EVOLUTION_KEY/" .env
    
    echo "✅ Environment file created with secure keys"
    echo "⚠️  Please edit .env file with your domain and credentials"
    exit 0
fi

echo "🏗️  Building and starting services..."
docker-compose up -d

echo "⏳ Waiting for services to be ready..."
sleep 30

# Setup Chatwoot database
echo "🔧 Setting up Chatwoot database..."
docker-compose exec chatwoot-web bundle exec rails db:chatwoot_prepare

echo "✅ Setup complete!"
echo ""
echo "🌐 Access your services:"
echo "   - n8n: https://$(grep N8N_HOST .env | cut -d'=' -f2)"
echo "   - Chatwoot: https://$(grep CHATWOOT_HOST .env | cut -d'=' -f2)"
echo "   - Evolution API: https://$(grep EVOLUTION_HOST .env | cut -d'=' -f2)"
echo ""
echo "📋 Next steps:"
echo "   1. Configure DNS to point your domains to this server"
echo "   2. Create your first n8n workflow"
echo "   3. Set up WhatsApp connection in Evolution API"
echo "   4. Configure Chatwoot inbox with Evolution API webhook"