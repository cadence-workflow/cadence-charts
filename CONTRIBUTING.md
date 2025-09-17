# CONTRIBUTING

## Build and generate template yml locally

```bash
helm package ./charts/cadence
# Replace with current chart version
helm template cadence-release cadence-0.2.0.tgz > template_out.yaml
```

## Build and deploy to a k8s cluster

### 1. Update dependencies (if needed)
```bash
cd charts/cadence
helm dependency update
cd ../..
```

### 2. Build helm package and deploy to a k8s cluster
```bash
helm package ./charts/cadence
# Replace with current chart version
helm upgrade --install cadence-release cadence-0.2.0.tgz \
    -n cadencetest \
    --create-namespace
```

### 3. Port forward to check the UI
```bash
kubectl port-forward svc/cadence-release-web 8088:8088 -n cadencetest
```

Visit http://localhost:8088 and validate it is accessible.

### 4. Port forward frontend service to run CLI commands
```bash
kubectl port-forward svc/cadence-release-frontend 7833:7833 -n cadencetest
```

### 5. (Optional) Register a domain:
```bash
cadence \
    --address localhost:7833 \
    --transport grpc \
    --domain default \
    domain register \
    --retention 1
```

### 6. Run samples:
- Clone https://github.com/cadence-workflow/cadence-samples

- Run sample worker (execute at samples repo root):
```bash
./bin/helloworld -m worker
```

- Trigger a workflow (execute at samples repo root):
```bash
./bin/helloworld -m trigger
```

### 7. Validate deployment
Visit http://localhost:8088 and validate the new workflow exists!

## Generate helm documentation

Install [helm-docs](https://github.com/norwoodj/helm-docs):
```bash
go install github.com/norwoodj/helm-docs/cmd/helm-docs@latest
```

Generate documentation:
```bash
helm-docs
```

The `charts/cadence/README.md` file should be updated automatically.

## Release Process

### Before making a release:

1. **Update appVersion and dependencies**: 
   - Check if Cadence has a new release and update `appVersion` in `Chart.yaml`
   - Verify dependencies are using latest-1 stable versions:
     - Cassandra: Currently using `11.x.x` from Bitnami 
     - PostgreSQL: Currently using `16.x.x` from Bitnami  
     - MySQL: Currently using `12.x.x` from Bitnami
   - Update `global.image.tag` in `values.yaml` to match `appVersion`

2. **Update dependencies**:
   ```bash
   cd charts/cadence
   helm dependency update
   cd ../..
   ```

3. **Test the changes**:
   - Build and deploy locally following the steps above
   - Validate all functionality works as expected

4. **Increment chart version**: Update the `version` field in `charts/cadence/Chart.yaml`:
   - Patch version (0.2.1): Bug fixes, dependency updates
   - Minor version (0.3.0): New features, breaking changes
   - Major version (1.0.0): Major breaking changes

5. **Update documentation**: Run `helm-docs` to regenerate the README.md

### Publishing:

After making changes to templates and incrementing the chart version in `charts/cadence/Chart.yaml`, merge your changes to the main branch. 

The automation will handle publishing the new version using [Chart Releaser Action](https://helm.sh/docs/howto/chart_releaser_action/). The Cadence chart is hosted on GitHub Pages.

After the new version is available in the helm repository, deploy it to a Kubernetes cluster to validate the release.

## Version Management Checklist

When updating versions, ensure consistency across:
- [ ] `Chart.yaml`: `version` (chart version) and `appVersion` (Cadence version)
- [ ] `values.yaml`: `global.image.tag` (should match appVersion)
- [ ] Dependencies in `Chart.yaml` (check for updates, aim for latest-1 stable)
- [ ] Update dependencies with `helm dependency update`
- [ ] Test deployment locally
- [ ] Run `helm-docs` to update documentation