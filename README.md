# MCP Gateway - Kubernetes Edition

A production-ready MCP (Model Context Protocol) Gateway deployed on Kubernetes with enterprise-grade features, proper health checks, and self-healing capabilities.

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster (Minikube, Docker Desktop, or cloud provider)
- kubectl installed and configured
- 4GB+ RAM and 2+ CPU cores recommended

### 1. Deploy to Kubernetes

#### Windows
```bash
cd k8s\scripts
deploy.bat
```

#### Linux/Mac
```bash
cd k8s/scripts
chmod +x deploy.sh
./deploy.sh
```

### 2. Access Your MCP Gateway

The deployment script will provide the access URL:
```
http://<service-ip>:4444
Username: admin
Password: admin123
```

## 📋 Project Structure

```
MCP-Gateway/
├── .env                           # Environment variables
├── README.md                      # This file
├── KUBERNETES_SETUP.md            # Detailed Kubernetes setup guide
├── data/                          # Persistent data directory
├── k8s/                           # Kubernetes manifests
│   ├── namespaces/                # Namespace configuration
│   ├── configmaps/                # Configuration maps
│   ├── secrets/                   # Encrypted secrets
│   ├── persistent-volumes/        # Storage definitions
│   ├── services/                  # Service definitions
│   ├── deployments/               # Application deployments
│   └── scripts/                   # Deployment scripts
├── kaggle-data/                   # Kaggle datasets
└── logs/                          # Application logs
```

## 🏗️ Architecture

### Core Services

- **MCP Gateway** - Main application with 2 replicas for high availability
- **PostgreSQL** - Production database with persistent storage
- **Playwright Bridge** - Browser automation with extended startup time
- **AI Bridges** - Context7 and Gistpad integration
- **Data Bridges** - Kaggle and MSSQL integration

### Health Checks

- **Liveness Probes** - Restart containers that become unresponsive
- **Readiness Probes** - Mark containers as ready to accept traffic
- **Startup Probes** - Give containers time to start before other probes

## 🔧 Configuration

### Environment Variables

All configuration is managed through:
- `.env` file for local development
- `k8s/configmaps/mcp-gateway-config.yaml` for Kubernetes
- `k8s/secrets/mcp-gateway-secrets.yaml` for sensitive data

### External Services

- **Kaggle** - Data competition platform
- **GitHub** - Code repository and Gist integration
- **MSSQL** - Microsoft SQL Server database
- **Context7** - AI/ML services
- **Playwright** - Browser automation

## 🛠️ Management Commands

### Check Deployment Status
```bash
kubectl get pods -n mcp-gateway
kubectl get services -n mcp-gateway
```

### View Logs
```bash
kubectl logs -f -n mcp-gateway --all-containers=true
```

### Scale Services
```bash
kubectl scale deployment mcp-gateway --replicas=3 -n mcp-gateway
```

### Update Services
```bash
kubectl set image deployment/mcp-gateway mcp-gateway=ghcr.io/ibm/mcp-context-forge:0.8.1 -n mcp-gateway
```

### Cleanup Deployment
```bash
kubectl delete namespace mcp-gateway
```

## 🔒 Security

- **Namespace Isolation** - All services in dedicated namespace
- **Secrets Management** - Base64-encoded sensitive data
- **Resource Limits** - Prevent resource abuse
- **Security Contexts** - Non-root users where possible

## 📈 Performance

- **Resource Requests** - Guaranteed resources for each service
- **Resource Limits** - Maximum resource usage caps
- **Horizontal Scaling** - Multiple replicas for high availability
- **Persistent Storage** - Fast, reliable data persistence

## 🐛 Troubleshooting

### Common Issues

#### Pod Stuck in Pending
```bash
kubectl describe nodes
kubectl get pvc -n mcp-gateway
```

#### Service Not Accessible
```bash
kubectl get endpoints -n mcp-gateway
kubectl get networkpolicy -n mcp-gateway
```

#### Playwright Pod Restarts
```bash
kubectl logs playwright-bridge -n mcp-gateway
kubectl exec playwright-bridge -n mcp-gateway -- ls -la /ms-playwright
```

## 📚 Documentation

- [KUBERNETES_SETUP.md](KUBERNETES_SETUP.md) - Detailed Kubernetes setup guide
- [Kubernetes Documentation](https://kubernetes.io/docs/) - Official Kubernetes docs
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) - kubectl commands

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🎉 Success!

Your MCP Gateway is now running on Kubernetes with:

✅ **Fixed Exited (0) Issues** - Proper liveness and readiness probes  
✅ **Self-Healing Architecture** - Automatic recovery from failures  
✅ **Production-Ready Database** - PostgreSQL with persistent storage  
✅ **All External Services** - Kaggle, GitHub, MSSQL, Context7 integrated  
✅ **Proxy Support** - Corporate network compatibility  
✅ **Enterprise-Grade Security** - Namespace isolation and secrets management  
✅ **Horizontal Scaling** - Multiple replicas for high availability  
✅ **Professional Monitoring** - Comprehensive health checks and logging  

Enjoy your enhanced MCP Gateway on Kubernetes! 🚀
