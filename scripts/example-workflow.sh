#!/bin/bash

# ArcDeploy Example Workflow
# Demonstrates the complete deployment process

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

echo "🚀 ArcDeploy Example Workflow"
echo "============================="
echo ""
echo "This example demonstrates the complete ArcDeploy deployment process."
echo "Follow along to deploy your first test server!"
echo ""

# Step 1: Check prerequisites
echo -e "${BLUE}Step 1: Check Prerequisites${NC}"
echo "First, let's validate your setup..."
echo ""

if ! ./check-setup.sh; then
    echo ""
    echo -e "${YELLOW}⚠ Setup validation failed. Please fix the issues above and try again.${NC}"
    echo ""
    echo "Common fixes:"
    echo "1. Install dependencies: apt install curl jq"
    echo "2. Set Hetzner token: export HETZNER_TOKEN=\"your-token\""
    echo "3. Configure SSH key in cloud-init.yaml"
    echo ""
    exit 1
fi

echo ""
echo -e "${GREEN}✓ Setup validation passed!${NC}"
echo ""

# Step 2: Choose deployment option
echo -e "${BLUE}Step 2: Choose Deployment Option${NC}"
echo ""
echo "ArcDeploy offers several deployment options:"
echo ""
echo "1. Quick deploy (recommended) - Optimal defaults"
echo "2. Small server - Minimal cost for basic testing"
echo "3. Large server - High performance for heavy testing"
echo "4. Custom deployment - Full control over settings"
echo ""

read -p "Choose option (1-4): " -n 1 -r choice
echo ""
echo ""

case $choice in
    1)
        echo -e "${GREEN}Deploying with optimal defaults...${NC}"
        echo ""
        echo "Server type: cx31 (2 vCPU, 8GB RAM)"
        echo "Location: fsn1 (Germany)"
        echo "Expected cost: ~€13.10/month"
        echo ""
        read -p "Continue? (y/N): " -n 1 -r confirm
        echo ""
        if [[ $confirm =~ ^[Yy]$ ]]; then
            ./quick-deploy.sh
        else
            echo "Deployment cancelled."
            exit 0
        fi
        ;;
    2)
        echo -e "${GREEN}Deploying minimal server...${NC}"
        echo ""
        echo "Server type: cx11 (1 vCPU, 4GB RAM)"
        echo "Location: fsn1 (Germany)"
        echo "Expected cost: ~€4.15/month"
        echo ""
        read -p "Continue? (y/N): " -n 1 -r confirm
        echo ""
        if [[ $confirm =~ ^[Yy]$ ]]; then
            ./quick-deploy.sh small
        else
            echo "Deployment cancelled."
            exit 0
        fi
        ;;
    3)
        echo -e "${GREEN}Deploying high-performance server...${NC}"
        echo ""
        echo "Server type: cx41 (4 vCPU, 16GB RAM)"
        echo "Location: fsn1 (Germany)"
        echo "Expected cost: ~€26.20/month"
        echo ""
        read -p "Continue? (y/N): " -n 1 -r confirm
        echo ""
        if [[ $confirm =~ ^[Yy]$ ]]; then
            ./quick-deploy.sh large
        else
            echo "Deployment cancelled."
            exit 0
        fi
        ;;
    4)
        echo -e "${GREEN}Custom deployment...${NC}"
        echo ""
        echo "Available server types:"
        echo "  cx11 - 1 vCPU, 4GB RAM (€4.15/month)"
        echo "  cx21 - 2 vCPU, 8GB RAM (€8.30/month)"
        echo "  cx31 - 2 vCPU, 8GB RAM (€13.10/month)"
        echo "  cx41 - 4 vCPU, 16GB RAM (€26.20/month)"
        echo ""
        read -p "Enter server type (default: cx31): " server_type
        server_type=${server_type:-cx31}

        echo ""
        echo "Available locations:"
        echo "  fsn1 - Germany (Falkenstein)"
        echo "  nbg1 - Germany (Nuremberg)"
        echo "  hel1 - Finland (Helsinki)"
        echo "  ash  - USA (Ashburn, VA)"
        echo "  hil  - USA (Hillsboro, OR)"
        echo ""
        read -p "Enter location (default: fsn1): " location
        location=${location:-fsn1}

        echo ""
        read -p "Enter server name (default: auto-generated): " server_name

        echo ""
        echo "Configuration:"
        echo "  Server type: $server_type"
        echo "  Location: $location"
        echo "  Name: ${server_name:-auto-generated}"
        echo ""
        read -p "Continue? (y/N): " -n 1 -r confirm
        echo ""
        if [[ $confirm =~ ^[Yy]$ ]]; then
            if [[ -n "$server_name" ]]; then
                ./deploy-test-server.sh "$server_name" "$server_type" "$location"
            else
                ./deploy-test-server.sh "example-$(date +%m%d-%H%M)" "$server_type" "$location"
            fi
        else
            echo "Deployment cancelled."
            exit 0
        fi
        ;;
    *)
        echo "Invalid option. Exiting."
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}🎉 Deployment completed!${NC}"
echo ""
echo "What's next?"
echo ""
echo "1. Wait 5-10 minutes for the installation to complete"
echo "2. Access your server via SSH (port 2222)"
echo "3. Open the web interface in your browser"
echo "4. Complete the Blocklet Server setup wizard"
echo "5. Test your blocklet functionality"
echo ""
echo "Monitoring commands:"
echo "  ./quick-deploy.sh list                    # List all test servers"
echo "  ssh -p 2222 arcblock@YOUR_SERVER_IP      # SSH access"
echo "  http://YOUR_SERVER_IP:8080               # Web interface"
echo ""
echo "When you're done testing:"
echo "  ./quick-deploy.sh delete YOUR_SERVER_NAME"
echo ""
echo -e "${YELLOW}💡 Pro tip: Bookmark your server's IP for easy access!${NC}"
echo ""
echo "For troubleshooting, see: DEPLOYMENT.md"
echo "For ArcDeploy documentation, see: README.md"
echo ""
echo "Happy testing! 🚀"
