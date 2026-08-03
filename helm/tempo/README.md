# Tempo Role

Deploys and manages **Tempo** for the LGTM observability stack using the upstream
`grafana-community/tempo-distributed` Helm chart (v2.25.5).

The role provisions Tempo into the `monitoring` namespace with an S3-compatible
object store backend, OTLP receivers, and the metrics generator enabled.

## Requirements

- The `kubernetes.core` Ansible collection
- Access to a Kubernetes cluster
- An S3-compatible object store

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `tempo_uninstall` | `false` | no | Set to `true` to uninstall the Tempo Helm release |
| `access_key` | `""` | yes | S3 access key |
| `secret_key` | `""` | yes | S3 secret access key |
| `bucket` | `""` | yes | S3 bucket name for traces |
| `endpoint` | `""` | yes | S3-compatible endpoint (e.g. `minio.minio.svc.cluster.local:9000`) |
| `insecure` | `false` | no | Set to `true` for plain-HTTP object stores |
| `otlp_grpc` | `true` | no | Enable the OTLP gRPC receiver |
| `otlp_http` | `true` | no | Enable the OTLP HTTP receiver |
| `zipkin` | `false` | no | Enable the Zipkin receiver |
| `jaeger_http` | `false` | no | Enable the Jaeger (thrift HTTP) receiver |

## Playbook Example

Deploy Tempo with OTLP receivers against a local MinIO endpoint:

```yaml
- name: Deploy Tempo
  hosts: localhost
  connection: local
  tasks:
    - name: Install Tempo
      ansible.builtin.include_role:
        name: "./helm/tempo"
      vars:
        access_key: "admin"
        secret_key: "toortoor"
        bucket: "tempo"
        endpoint: "minio.minio.svc.cluster.local:9000"
        insecure: true
        otlp_grpc: true
        otlp_http: true
        zipkin: false
        jaeger_http: false
```

Uninstall:

```yaml
- name: Remove Tempo
  hosts: localhost
  connection: local
  tasks:
    - name: Uninstall Tempo
      ansible.builtin.include_role:
        name: "./helm/tempo"
      vars:
        tempo_uninstall: true
```

## Notes

- Variables `access_key`, `secret_key`, `endpoint`, and `bucket` are validated before
  deployment; the playbook fails if they are empty.
- The OTLP HTTP receiver (`:4318`) and gRPC receiver (`:4317`) are used by the
  k8s-monitoring Alloy agents and instrumented applications.
- Chart values are rendered from `templates/values.yml`.