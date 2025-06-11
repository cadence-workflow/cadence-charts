## 🚀 Cadence Helm Chart Setup Guide

1. Create a Namespace (Optional, but recommended)
```
kubectl create namespace <namespace>
```

2. Add Cadence-chart to repo and Install the Cadence Chart
```
helm repo add cadence https://cadence-workflow.github.io/cadence-charts

helm install my-cadence cadence/cadence -n <namespace> -f <path to custom values .yaml>

example:
 helm install my-cadence cadence/cadence -n vishwa-test -f /Users/vpatil16/Downloads/custom-values.yaml 
```
3. Upgrade the Cadence Chart (when new changes/versions are available)
```
helm upgrade my-cadence cadence/cadence -n <namespace>
```

4. Uninstall the Cadence Chart
```
helm delete my-cadence -n <namespace>
```


5. Check the Status of the Cadence Release
```
helm status my-cadence -n <namespace>
```

6. Check Installed Chart Version
```
helm list -n <namespace>
```

## 📊 Monitoring Setup (Prometheus + Grafana)

7. Add Prometheus Community Helm Repository
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

8. Install Prometheus + Grafana Stack
```
helm install my-prometheus prometheus-community/kube-prometheus-stack -n <namespace>
```

9. Retrieve Grafana Admin Password
```
kubectl get secret --namespace <namespace> my-prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```




## 📥 Download and Customize Cadence Grafana Dashboard JSON
1. Download the Cadence Grafana Dashboard JSON

```
curl https://raw.githubusercontent.com/cadence-workflow/cadence/refs/heads/master/docker/grafana/provisioning/dashboards/cadence-server.json -o cadence-server.json
```
✅ This fetches the cadence-server.json dashboard from the Cadence GitHub repository.

2. Add a Comma Before "version" Key (JSON Format Fix)
```
sed -i '' 's/.*\("version".*\)/,\1/' cadence-server.json
```
🛠️ Ensures the "version" key is correctly comma-separated from the preceding line. The -i '' is for macOS in-place editing.

3. Update the "uid" to a Custom Value (e.g., "prometheus")
```
sed -i '' 's/\("uid": "\).*/\1prometheus"/' cadence-server.json
```