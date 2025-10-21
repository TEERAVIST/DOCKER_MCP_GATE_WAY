#!/bin/bash

# MCP Gateway Kubernetes Deployment Script
# This script deploys the MCP Gateway to Kubernetes with proper liveness and readiness probes

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="mcp-gateway"
KUBECTL="kubectl"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    if ! $KUBECTL cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    print_success "kubectl is available and connected to cluster"
}

# Function to create namespace
create_namespace() {
    print_status "Creating namespace: $NAMESPACE"
    if $KUBECTL get namespace $NAMESPACE &> /dev/null; then
        print_warning "Namespace $NAMESPACE already exists"
    else
        $KUBECTL apply -f ../namespaces/mcp-gateway.yaml
        print_success "Namespace $NAMESPACE created"
    fi
}

# Function to create secrets
create_secrets() {
    print_status "Creating secrets"
    $KUBECTL apply -f ../secrets/mcp-gateway-secrets.yaml
    print_success "Secrets created"
}

# Function to create configmaps
create_configmaps() {
    print_status "Creating configmaps"
    $KUBECTL apply -f ../configmaps/mcp-gateway-config.yaml
    print_success "Configmaps created"
}

# Function to create persistent volumes
create_persistent_volumes() {
    print_status "Creating persistent volumes"
    $KUBECTL apply -f ../persistent-volumes/postgres-pv.yaml
    print_success "Persistent volumes created"
}

# Function to deploy services
deploy_services() {
    print_status "Deploying services"
    $KUBECTL apply -f ../services/mcp-gateway-services.yaml
    print_success "Services deployed"
}

# Function to deploy database
deploy_database() {
    print_status "Deploying PostgreSQL database"
    $KUBECTL apply -f ../deployments/postgres.yaml
    
    # Wait for PostgreSQL to be ready
    print_status "Waiting for PostgreSQL to be ready..."
    $KUBECTL wait --for=condition=ready pod -l app=postgres -n $NAMESPACE --timeout=300s
    print_success "PostgreSQL is ready"
}

# Function to deploy core services
deploy_core_services() {
    print_status "Deploying MCP Gateway"
    $KUBECTL apply -f ../deployments/mcp-gateway.yaml
    
    # Wait for MCP Gateway to be ready
    print_status "Waiting for MCP Gateway to be ready..."
    $KUBECTL wait --for=condition=ready pod -l app=mcp-gateway -n $NAMESPACE --timeout=300s
    print_success "MCP Gateway is ready"
}

# Function to deploy bridge services
deploy_bridge_services() {
    print_status "Deploying AI bridge services"
    $KUBECTL apply -f ../deployments/ai-bridges.yaml
    
    print_status "Deploying data bridge services"
    $KUBECTL apply -f ../deployments/data-bridges.yaml
    
    print_status "Deploying Playwright bridge service"
    $KUBECTL apply -f ../deployments/playwright.yaml
    
    # Wait for bridge services to be ready
    print_status "Waiting for bridge services to be ready..."
    $KUBECTL wait --for=condition=ready pod -l app=context7-bridge -n $NAMESPACE --timeout=300s &
    $KUBECTL wait --for=condition=ready pod -l app=gistpad-bridge -n $NAMESPACE --timeout=300s &
    $KUBECTL wait --for=condition=ready pod -l app=kaggle-bridge -n $NAMESPACE --timeout=300s &
    $KUBECTL wait --for=condition=ready pod -l app=mssql-bridge -n $NAMESPACE --timeout=300s &
    $KUBECTL wait --for=condition=ready pod -l app=playwright-bridge -n $NAMESPACE --timeout=600s &
    
    wait
    print_success "All bridge services are ready"
}

# Function to show deployment status
show_deployment_status() {
    print_status "Deployment status:"
    echo ""
    $KUBECTL get pods -n $NAMESPACE
    echo ""
    $KUBECTL get services -n $NAMESPACE
    echo ""
    
    # Get MCP Gateway URL
    GATEWAY_URL=$($KUBECTL get service mcp-gateway -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "localhost")
    GATEWAY_PORT=$($KUBECTL get service mcp-gateway -n $NAMESPACE -o jsonpath='{.spec.ports[0].port}')
    
    print_success "MCP Gateway is available at: http://$GATEWAY_URL:$GATEWAY_PORT"
    print_status "Username: admin"
    print_status "Password: changeme"
}

# Function to show logs
show_logs() {
    print_status "Showing logs for all services (press Ctrl+C to exit):"
    $KUBECTL logs -f -n $NAMESPACE --all-containers=true
}

# Main deployment function
deploy_all() {
    print_status "Starting MCP Gateway Kubernetes deployment..."
    echo ""
    
    check_kubectl
    create_namespace
    create_secrets
    create_configmaps
    create_persistent_volumes
    deploy_services
    deploy_database
    deploy_core_services
    deploy_bridge_services
    
    echo ""
    print_success "MCP Gateway deployment completed successfully!"
    echo ""
    
    show_deployment_status
}

# Function to cleanup deployment
cleanup() {
    print_warning "Cleaning up MCP Gateway deployment..."
    $KUBECTL delete namespace $NAMESPACE --ignore-not-found=true
    print_success "Cleanup completed"
}

# Function to scale services
scale_service() {
    local service=$1
    local replicas=$2
    
    if [ -z "$service" ] || [ -z "$replicas" ]; then
        print_error "Usage: $0 scale <service> <replicas>"
        exit 1
    fi
    
    print_status "Scaling $service to $replicas replicas"
    $KUBECTL scale deployment $service --replicas=$replicas -n $NAMESPACE
    $KUBECTL wait --for=condition=available deployment/$service -n $NAMESPACE --timeout=300s
    print_success "$service scaled to $replicas replicas"
}

# Main script logic
case "${1:-deploy}" in
    "deploy")
        deploy_all
        ;;
    "cleanup")
        cleanup
        ;;
    "status")
        show_deployment_status
        ;;
    "logs")
        show_logs
        ;;
    "scale")
        scale_service "$2" "$3"
        ;;
    "help"|"-h"|"--help")
        echo "MCP Gateway Kubernetes Deployment Script"
        echo ""
        echo "Usage: $0 [COMMAND] [OPTIONS]"
        echo ""
        echo "Commands:"
        echo "  deploy              Deploy MCP Gateway to Kubernetes (default)"
        echo "  cleanup             Remove MCP Gateway from Kubernetes"
        echo "  status              Show deployment status"
        echo "  logs                Show logs for all services"
        echo "  scale <svc> <rep>   Scale a service to specified replicas"
        echo "  help                Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 deploy           # Deploy all services"
        echo "  $0 scale mcp-gateway 3  # Scale MCP Gateway to 3 replicas"
        echo "  $0 status            # Show deployment status"
        echo "  $0 logs              # Show logs"
        echo "  $0 cleanup           # Remove all services"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac