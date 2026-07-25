# Kubernetes Observability Stack (LGTM)

An end-to-end observability platform for Kubernetes, deploying **Loki**, **Grafana**, **Tempo**, and **Mimir** (the LGTM stack) with **Alloy-based cluster monitoring**. All components are orchestrated through Ansible playbooks that deploy upstream Helm charts.

## What Gets Deployed

| Component | Chart Version | Purpose |
|-----------|---------------|---------|
| **Loki** | 18.1.1 | Log aggregation (distributed mode, S3 backend) |
| **Grafana** | 12.7.1 | Dashboards and visualization |
| **Tempo** | 2.25.5 | Distributed tracing backend (OTLP) |
| **Mimir** | 6.0.6 | Long-term Prometheus metrics storage |
| **k8s-monitoring** | 4.2.0 | Alloy agents for cluster metrics, logs, and trace collection |
| **ingress-nginx** | 4.15.0 | Ingress controller for Grafana UI |

Everything deploys into the `monitoring` namespace. The ingress-nginx controller deploys separately into `ingress-nginx`.

## Prerequisites

### Required Tools

| Tool | Minimum Version | Purpose |
|------|-----------------|---------|
| [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) | 2.15+ | Playbook orchestration |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | 1.25+ | Kubernetes API access |
| [Helm](https://helm.sh/docs/intro/install/) | 3.12+ | Chart deployment |
| [Docker](https://docs.docker.com/get-docker/) or Podman | any | Building the demo app image |

### Required Ansible Collections

```bash
ansible-galaxy collection install kubernetes.core grafana.grafana
```

### Kubernetes Cluster

- **Minimum version:** 1.25 (1.28+ recommended)
- **Dynamic volume provisioning** must be available for Grafana persistence and Loki/Tempo/Mimir components that use PVCs.
- A local cluster such as Minikube works for development. Ensure it has sufficient resources:
  ```bash
  minikube start --cpus=4 --memory=8192 --driver=docker
  ```
  > If you are using Minikube, enable the ingress addon if you want to access Grafana via the ingress: `minikube addons enable ingress`

## Object Store Setup

Loki, Tempo, and Mimir all store data in S3-compatible object storage. Any S3-compatible service works — this could be MinIO, Ceph, SeaweedFS, or a cloud provider's S3 API.

The deploy script creates the following buckets automatically: `loki-chunk`, `loki-ruler`, `loki-admin`, `tempo`, `mimir-blocks`, `mimir-alertmanager`, `mimir-ruler`.

### Option A: External Object Store

Point the stack at your existing S3-compatible endpoint:

```bash
export OBJECT_STORE_ACCESS_KEY="<your-access-key>"
export OBJECT_STORE_SECRET_ACCESS_KEY="<your-secret-key>"
export OBJECT_STORE_ENDPOINT="<your-endpoint-hostname>"
```

The endpoint should be the hostname only (e.g. `minio.example.com`, `s3.us-east-1.amazonaws.com`). Do not include the `https://` prefix.

If your endpoint uses plain HTTP (no TLS), set `allow_insecure_http: true` and `insecure: true` in the Loki, Tempo, and Mimir role defaults under `helm/`.

### Option B: Local MinIO (Development)

For local development, MinIO manifests are provided in `PV/Cs/`. Deploy them first:

```bash
kubectl apply -f PV/Cs/minio/minio-secret.yml
kubectl apply -f PV/Cs/minio/minio-pvc.yml
kubectl apply -f PV/Cs/minio/minio-service.yml
kubectl apply -f PV/Cs/minio/minio-statefulset.yml
```

Then set your environment to point at MinIO:

```bash
export OBJECT_STORE_ACCESS_KEY="admin"
export OBJECT_STORE_SECRET_ACCESS_KEY="toortoor"
export OBJECT_STORE_ENDPOINT="minio.minio.svc.cluster.local:9000"
```

> The bundled MinIO uses hardcoded dev credentials and HTTP. Set the insecure flags mentioned above.

## Environment Configuration

Copy the example environment file and fill in your credentials:

```bash
cp .env.example .env
```

| Variable | Description |
|----------|-------------|
| `OBJECT_STORE_ACCESS_KEY` | S3-compatible access key |
| `OBJECT_STORE_SECRET_ACCESS_KEY` | S3-compatible secret key |
| `OBJECT_STORE_ENDPOINT` | S3 endpoint hostname (no `https://` prefix) |
| `OBJECT_STORE_ALLOW_INSECURE` | Set to `true` if the object store endpoint uses HTTP instead of HTTPS |
| `GRAFANA_URL` | Grafana API URL for dashboard imports (default: `http://localhost:3000`) |
| `GRAFANA_API_KEY` | Grafana API key for dashboard imports |

The Ansible playbooks read these values via `lookup('ansible.builtin.env', ...)`.

## Deploying the Stack

### Full Deployment

```bash
ansible-playbook deploy-stack-playbook.yml
```

This deploys in order: Loki, Grafana, Tempo, Mimir, k8s-monitoring, then the Grafana Ingress.

### Ingress Controller

The main playbook does **not** deploy the ingress-nginx controller. Deploy it separately:

```bash
ansible-playbook deploy-nginx-playbook.yml
```

To remove it:

```bash
ansible-playbook uninstall-nginx-playbook.yml
```

### Accessing Grafana

Once deployed, port-forward to Grafana:

```bash
kubectl port-forward svc/grafana -n monitoring 80:80
```

Open [http://localhost](http://localhost) in your browser.

Grafana comes pre-configured with three datasources:
- **Mimir** (default) — Prometheus-compatible metrics
- **Loki** — Logs
- **Tempo** — Distributed traces

### Verify the Stack

Check that all pods are running:

```bash
kubectl get pods -n monitoring
```

You should see pods for loki, grafana, tempo, mimir, and k8s-monitoring (alloy agents, kube-state-metrics, node-exporter).

### Importing Dashboards

After Grafana is running and you have an API key, import the dashboards:

```bash
ansible-playbook deploy-dashboards-playbook.yml
```

## Instrumenting a Spring Application

To integrate an existing Spring Boot application with this monitoring stack, you need to expose **metrics** (Prometheus), **traces** (OTLP), and **logs** (stdout).

### 1. Add Dependencies

Add these to your `pom.xml`:

```xml
<!-- Metrics: expose Prometheus endpoint -->
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
    <scope>runtime</scope>
</dependency>

<!-- Traces: Micrometer to OpenTelemetry bridge -->
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-tracing-bridge-otel</artifactId>
</dependency>

<!-- Traces: OTLP exporter -->
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-exporter-otlp</artifactId>
</dependency>
```

For Gradle builds, use the equivalent `implementation` / `runtimeOnly` declarations.

### 2. Configure Actuator Endpoints

In `application.yml`:

```yaml
spring:
  application:
    name: your-app-name

management:
  endpoints:
    web:
      exposure:
        include: health, metrics, prometheus
  endpoint:
    health:
      show-details: always
  tracing:
    sampling:
      probability: 1.0
  otlp:
    tracing:
      endpoint: http://k8smonitoring-alloy-receiver.monitoring.svc.cluster.local:4318/v1/traces
  metrics:
    tags:
      application: ${spring.application.name}
    distribution:
      percentiles-histogram:
        http.server.requests: true
        http.client.requests: true
      slo:
        http.server.requests: 50ms,100ms,200ms,500ms,1s,2s,5s
```

Key points:
- `management.otlp.tracing.endpoint` points to the k8s-monitoring Alloy receiver service. This is how traces reach Tempo.
- `management.tracing.sampling.probability: 1.0` traces every request. Lower this in production.
- SLO buckets and percentile histograms give you useful latency panels in Grafana.

### 3. Add Kubernetes Deployment Annotations

The k8s-monitoring Alloy agents use annotation autodiscovery to find and scrape your pods. Add these to your Deployment's pod template:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: your-app
  labels:
    app: your-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: your-app
  template:
    metadata:
      labels:
        app: your-app
      annotations:
        # Prometheus scrape annotations for Alloy metrics collector
        k8s.grafana.com/scrape: "true"
        k8s.grafana.com/metrics.path: "/actuator/prometheus"
        k8s.grafana.com/metrics.portNumber: "8080"
    spec:
      containers:
        - name: your-app
          image: your-app:latest
          ports:
            - containerPort: 8080
          livenessProbe:
            httpGet:
              path: /actuator/health/liveness
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /actuator/health/readiness
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 10
```

- `k8s.grafana.com/scrape: "true"` tells Alloy to scrape this pod.
- `k8s.grafana.com/metrics.path` and `k8s.grafana.com/metrics.portNumber` tell Alloy where the Prometheus endpoint is.
- **Traces** are sent directly by your app to the Alloy receiver service (configured in `application.yml` above) — no annotations needed for that.
- **Logs** are collected automatically from stdout/stderr by the Alloy log collector (daemonset). No configuration needed — just log to stdout.

### 4. Build and Load the Image

```bash
# Build the image
docker build -t your-app:latest ./path/to/your/app

# If using Minikube, load the image into the cluster
minikube image load your-app:latest
```

Set `imagePullPolicy: Never` in your deployment if using Minikube's local Docker daemon.

### 5. Deploy

```bash
kubectl apply -f your-deployment.yaml
kubectl apply -f your-service.yaml
```

### 6. Verify

After a few minutes, check Grafana:
- **Metrics** — Explore > Mimir datasource, query `http_server_requests_seconds_count`
- **Logs** — Explore > Loki datasource, query `{app="your-app-name"}`
- **Traces** — Explore > Tempo datasource, search by service name

## Uninstalling

```bash
ansible-playbook uninstall-stack-playbook.yml
```

This removes all components and deletes the `monitoring` namespace.

To also remove the ingress controller:

```bash
# Be careful — the current nginx uninstall role has a bug that deletes Grafana instead.
# Manually uninstall until fixed:
helm uninstall ingress-nginx -n ingress-nginx
```

## Useful Commands

```bash
# Port-forward Grafana
kubectl port-forward svc/grafana -n monitoring 80:80

# Port-forward MinIO console (if using local MinIO)
kubectl port-forward svc/minio -n minio 9001:9001

# Run the traffic generator against the demo app
./traffic_generator.sh

# Check all resources in the monitoring namespace
kubectl get all -n monitoring

# Watch pod status
kubectl get pods -n monitoring -w

# View Loki logs
kubectl logs -l app.kubernetes.io/name=loki -n monitoring

# Check Alloy agent logs
kubectl logs -l app.kubernetes.io/name=k8s-monitoring-alloy -n monitoring
```

## Known Issues
