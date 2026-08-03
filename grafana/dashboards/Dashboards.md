# Dashboards

Two Grafana dashboards shipped with this stack, imported from `grafana/dashboards/files/`.

## RED Dashboard

Application-level RED metrics for instrumented Spring Boot services. Source: Mimir (Prometheus) for metrics, Loki for logs.

### Traffic

| Panel | Purpose |
|-------|---------|
| Request Rate | Requests/sec broken down by method and HTTP status. |
| Total Throughput | Aggregate request rate across all endpoints. |

### Errors

| Panel | Purpose |
|-------|---------|
| Error Rate | Fraction of requests returning errors (5xx by default, toggle to 4xx via the `ErrorType` variable). |
| Top Failing Endpoints | Table of endpoints with the most errors in the window, sorted by failure count. |

### Duration

| Panel | Purpose |
|-------|---------|
| Latency Percentiles | p50 / p95 / p99 request latency over time. |
| Latency Distribution Over Time | Heatmap of request latency buckets. |
| P95 Latency By Endpoint | Top 10 endpoints by p95 latency. |

### Saturation

| Panel | Purpose |
|-------|---------|
| JVM Heap Usage | Current heap usage as a fraction of max heap. |
| GC Pause | Time spent in garbage collection, broken down by GC action. |

### Logs

| Panel | Purpose |
|-------|---------|
| Logs | Loki log stream filtered by `namespace` and `container`. |

### Variables

| Variable | Source | Default |
|----------|--------|---------|
| `namespace` | label `namespace` | `springapp` |
| `application` | label `application` | `springapp` |
| `ErrorType` | custom (5xx / 4xx) | `5xx` |
| `container` | label `container` | `spring-observability-app` |

## USE Dashboard

INFRASTRUCTURE USE metrics (Utilization, Saturation, Errors) for cluster nodes. Source: Mimir (Prometheus), job `node_exporter`.

### CPU

| Panel | Purpose |
|-------|---------|
| CPU Utilization | CPU used per node, as a fraction. |
| Load Average vs CPU Cores | Load 1/5 compared against core count per node. Load sustained above the cores line indicates saturation. |

### Memory

| Panel | Purpose |
|-------|---------|
| Memory Utilization | Used fraction of total memory, per node. |
| OOM Killed Pods | Table of pods terminated due to `OOMKilled`. |
| Memory Saturation | Swap usage and major-fault rate; sustained activity indicates memory pressure. |

### Disk

| Panel | Purpose |
|-------|---------|
| Filesystem Utilization | Used fraction of each mountpoint, per node. |
| Disk IO | Read/write throughput per node. |
| Disk Saturation | Percentage of time disks are busy serving I/O. |

### Network

| Panel | Purpose |
|-------|---------|
| Network Throughput | Receive/transmit bytes per second per node (virtual interfaces excluded). |
| Network Drops | Rx/Tx packet drop rate per node. |

### Variables

| Variable | Source |
|----------|--------|
| `instance` | label `instance` from `node_exporter` |

## Data Sources

- **RED** — Mimir (`prometheus`) for metrics, Loki for logs.
- **USE** — Mimir (`prometheus`) via the `integrations/node_exporter` job.