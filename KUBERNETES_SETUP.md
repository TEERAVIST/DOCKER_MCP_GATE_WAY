# Kubernetes Setup Guide for MCP Gateway

This guide will help you deploy your MCP Gateway to Kubernetes with proper liveness and readiness probes, addressing the Exited (0) issues you encountered with Docker Compose.

## 🎯 Why Kubernetes?

- **Production-Ready Orchestration** - Enterprise-grade container management
- **Self-Healing** - Automatic restarts with proper liveness probes
- **Scaling** - Horizontal and vertical scaling capabilities
- **Rolling Updates** - Zero-downtime deployments
- **Resource Management** - Precise CPU and memory allocation
- **Service Discovery** - Built-in load balancing and networking
- **Health Monitoring** - Advanced health checks and monitoring

## 📋 Prerequisites

1. **Kubernetes Cluster** running (Minikube, Docker Desktop, or cloud provider)
2. **kubectl** installed and configured
3. **Docker** installed and running
4. **Sufficient resources** (minimum 4GB RAM, 2 CPU cores)
5. **Administrator privileges** for cluster management

## 🚀 Quick Setup with Minikube

### 1. Start Minikube
```bash
# Start Minikube with sufficient resources
minikube start --memory=4096 --cpus=2 --disk-size=20g

# Enable addons
minikube addons enable ingress
minikube addons enable metrics-server
```

### 2. Verify Cluster Status
```bash
# Check cluster status
kubectl get nodes

# Check cluster info
kubectl cluster-info
```

## 🔧 Configuration

### 1. Update Secrets
Edit `k8s/secrets/mcp-gateway-secrets.yaml` and replace the placeholder values with your actual base64-encoded credentials:

```bash
# Generate base64 values
echo -n "your-value" | base64

# Example for PostgreSQL password
echo -n "your-secure-postgres-password" | base64
```

### 2. Verify Configuration
```bash
# Validate YAML files
kubectl apply --dry-run=client -f k8s/namespaces/
kubectl apply --dry-run=client -f k8s/configmaps/
kubectl apply --dry-run=client -f k8s/secrets/
```

## 🚀 Deployment Options

### Option 1: Automated Deployment (Recommended)

#### Windows
```bash
# Navigate to scripts directory
cd k8s\scripts

# Run deployment script
deploy.bat
```

#### Linux/Mac
```bash
# Navigate to scripts directory
cd k8s/scripts

# Make script executable
chmod +x deploy.sh

# Run deployment script
./deploy.sh
```

### Option 2: Manual Deployment

#### Step 1: Create Namespace
```bash
kubectl apply -f k8s/namespaces/mcp-gateway.yaml
```

#### Step 2: Create ConfigMaps and Secrets
```bash
kubectl apply -f k8s/configmaps/mcp-gateway-config.yaml
kubectl apply -f k8s/secrets/mcp-gateway-secrets.yaml
```

#### Step 3: Create Persistent Volumes
```bash
kubectl apply -f k8s/persistent-volumes/postgres-pv.yaml
```

#### Step 4: Deploy Services
```bash
kubectl apply -f k8s/services/mcp-gateway-services.yaml
```

#### Step 5: Deploy Database
```bash
kubectl apply -f k8s/deployments/postgres.yaml

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n mcp-gateway --timeout=300s
```

#### Step 6: Deploy Core Services
```bash
kubectl apply -f k8s/deployments/mcp-gateway.yaml

# Wait for MCP Gateway to be ready
kubectl wait --for=condition=ready pod -l app=mcp-gateway -n mcp-gateway --timeout=300s
```

#### Step 7: Deploy Bridge Services
```bash
# AI Bridges
kubectl apply -f k8s/deployments/ai-bridges.yaml

# Data Bridges
kubectl apply -f k8s/deployments/data-bridges.yaml

# Playwright Bridge
kubectl apply -f k8s/deployments/playwright.yaml
```

## 🔍 Health Checks and Probes

### Liveness Probes
- **Purpose**: Restart containers that become unresponsive
- **Configuration**: 3 failures trigger restart
- **Frequency**: Every 30 seconds after initial delay

### Readiness Probes
- **Purpose**: Mark containers as ready to accept traffic
- **Configuration**: 3 failures mark as not ready
- **Frequency**: Every 10 seconds after initial delay

### Startup Probes
- **Purpose**: Give containers time to start before other probes
- **Configuration**: Extended timeouts for complex services
- **Special Handling**: Playwright gets 10 minutes for browser installation

### Playwright-Specific Solution
The Exited (0) issue is resolved by:
1. **Extended startup probe** - 10 minutes for browser installation
2. **Proper process management** - Using `exec` to maintain main process
3. **Health check file** - Creating `/tmp/playwright-ready` on startup
4. **Graceful shutdown handling** - Proper signal handling

## 📊 Monitoring and Troubleshooting

### Check Deployment Status
```bash
# Show all pods
kubectl get pods -n mcp-gateway

# Show services
kubectl get services -n mcp-gateway

# Show detailed pod information
kubectl describe pod <pod-name> -n mcp-gateway
```

### View Logs
```bash
# Show logs for specific pod
kubectl logs <pod-name> -n mcp-gateway

# Follow logs in real-time
kubectl logs -f <pod-name> -n mcp-gateway

# Show logs for all services
kubectl logs -f -n mcp-gateway --all-containers=true
```

### Debug Health Issues
```bash
# Check pod events
kubectl get events -n mcp-gateway --sort-by=.metadata.creationTimestamp

# Check resource usage
kubectl top pods -n mcp-gateway

# Execute commands in pod
kubectl exec -it <pod-name> -n mcp-gateway -- /bin/bash
```

### Common Issues and Solutions

#### Pod Stuck in Pending
```bash
# Check resource requests vs available resources
kubectl describe nodes

# Check if PVC is bound
kubectl get pvc -n mcp-gateway
```

#### Playwright Pod Restarts
```bash
# Check startup logs
kubectl logs playwright-bridge -n mcp-gateway

# Check if browser installation is complete
kubectl exec playwright-bridge -n mcp-gateway -- ls -la /ms-playwright
```

#### Service Not Accessible
```bash
# Check service endpoints
kubectl get endpoints -n mcp-gateway

# Check network policies
kubectl get networkpolicy -n mcp-gateway
```

## 🔧 Service Management

### Scale Services
```bash
# Scale MCP Gateway to 3 replicas
kubectl scale deployment mcp-gateway --replicas=3 -n mcp-gateway

# Scale PostgreSQL (not recommended for production)
kubectl scale deployment postgres --replicas=1 -n mcp-gateway
```

### Update Services
```bash
# Update deployment with new image
kubectl set image deployment/mcp-gateway mcp-gateway=ghcr.io/ibm/mcp-context-forge:0.8.1 -n mcp-gateway

# Check rollout status
kubectl rollout status deployment/mcp-gateway -n mcp-gateway
```

### Rollback Updates
```bash
# View rollout history
kubectl rollout history deployment/mcp-gateway -n mcp-gateway

# Rollback to previous version
kubectl rollout undo deployment/mcp-gateway -n mcp-gateway
```

## 🔒 Security Best Practices

### Network Security
```bash
# View network policies
kubectl get networkpolicy -n mcp-gateway

# Create network policy (example)
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: mcp-gateway-netpol
  namespace: mcp-gateway
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: mcp-gateway
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: mcp-gateway
EOF
```

### Resource Limits
All deployments include:
- **Resource requests** - Guaranteed resources
- **Resource limits** - Maximum resources
- **Security contexts** - Non-root users where possible

### Secrets Management
- **Base64 encoding** for all sensitive data
- **Namespace isolation** for secrets
- **Role-based access control** (RBAC) recommended

## 📈 Performance Tuning

### Resource Optimization
```bash
# Check resource usage
kubectl top pods -n mcp-gateway

# Adjust resource limits
kubectl patch deployment mcp-gateway -n mcp-gateway -p '{"spec":{"template":{"spec":{"containers":[{"name":"mcp-gateway","resources":{"limits":{"memory":"1Gi"}}}]}}}}'
```

### Horizontal Pod Autoscaling
```bash
# Create HPA for MCP Gateway
kubectl autoscale deployment mcp-gateway --cpu-percent=70 --min=2 --max=10 -n mcp-gateway

# Check HPA status
kubectl get hpa -n mcp-gateway
```

## 🌐 Accessing Services

### Minikube
```bash
# Get service URL
minikube service mcp-gateway -n mcp-gateway --url

# Access service
minikube service mcp-gateway -n mcp-gateway
```

### Port Forwarding
```bash
# Forward MCP Gateway port
kubectl port-forward service/mcp-gateway 4444:4444 -n mcp-gateway

# Forward PostgreSQL port (for debugging)
kubectl port-forward service/postgres 5432:5432 -n mcp-gateway
```

### Ingress (Advanced)
```bash
# Create ingress resource
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mcp-gateway-ingress
  namespace: mcp-gateway
spec:
  rules:
  - host: mcp-gateway.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: mcp-gateway
            port:
              number: 4444
EOF
```

## 🧹 Cleanup

### Remove Entire Deployment
```bash
# Using deployment script
cd k8s\scripts
deploy.bat cleanup

# Or manually
kubectl delete namespace mcp-gateway
```

### Remove Specific Services
```bash
# Remove specific deployment
kubectl delete deployment mcp-gateway -n mcp-gateway

# Remove specific service
kubectl delete service mcp-gateway -n mcp-gateway
```

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes Health Checks](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)

## 🎉 Success!

Your MCP Gateway is now running on Kubernetes with proper health checks and monitoring! 

**Key Improvements Achieved:**
✅ **Resolved Exited (0) Issues** - Proper liveness and readiness probes  
✅ **Self-Healing** - Automatic restarts on failures  
✅ **Production-Ready** - Enterprise-grade orchestration  
✅ **Scalable** - Horizontal scaling capabilities  
✅ **Monitored** - Comprehensive health checks  
✅ **Secure** - Namespace isolation and secrets management  

**Next Steps:**
1. Explore your MCP Gateway at the provided URL
2. Monitor service health with `kubectl get pods -n mcp-gateway`
3. Scale services as needed
4. Set up monitoring and alerting
5. Consider setting up CI/CD pipelines

Enjoy your enhanced MCP Gateway on Kubernetes! 🚀