# Get Secrets 
```bash
kubectl get secret mcp-gateway-secrets -n mcp-gateway -o json | jq '.data | map_values(@base64d)'
```

# Create Super Secrets (GitOps)
```bash
kubeseal.exe --format=yaml --cert=sealed-secrets-cert.crt < temp-secret.yaml > k8s/secrets/mcp-gateway-sealed-secret.yaml
```
```bash
kubectl apply -f k8s/secrets/mcp-gateway-sealed-secret.yaml
```