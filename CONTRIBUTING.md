# CONTRIBUTING

## Build and generate template yml locally

```
helm package ./charts/cadence
helm template cadence-release cadence-0.1.8.tgz > template_out.yaml
```

## Build and deploy to a k8s cluster

1. Build helm package and deploy to a k8s cluster
```
helm package ./charts/cadence
helm upgrade --install cadence-release cadence-0.1.8.tgz \
    -n cadencetest \
    --create-namespace
```

2. Port forward to check the UI
```
kubectl port-forward svc/cadence-release-web 8088:8088 -n cadencetest
```

Visit localhost:8088 and validate it is accessible.

3. Port forward frontend service to run CLI commands
```
kubectl port-forward svc/cadence-release-frontend 7833:7833 -n cadencetest
```

4. (optional) Register a domain:
```
cadence \
    --address localhost:7833 \
    --transport grpc \
    --domain default \
    domain register \
    --retention 1
```

5. Run samples:
- Clone https://github.com/uber-common/cadence-samples

- Run sample worker (run at samples repo root)
```
./bin/helloworld -m worker
```

- Trigger a workflow  (run at samples repo root)
```
./bin/helloworld -m trigger
```

6. Visit localhost:8088 and validate the new workflow exists!

## Generate helmdocs

Install [helm-docs](https://github.com/norwoodj/helm-docs):
```
go install github.com/norwoodj/helm-docs/cmd/helm-docs@latest
```

Run it
```
helm-docs
```

cadencechart/README.md file should be updated.


## Publish chart

After making changes to templates, increment the chart version in charts/cadence/Chart.yaml.
Then merge your changes and automation will take care of publishing the new version.
Cadence chart is hosted on github pages and automation is done using [Chart Releaser Action](https://helm.sh/docs/howto/chart_releaser_action/).
After new version is available in helm repo, deploy it to a K8s cluster to validate.
