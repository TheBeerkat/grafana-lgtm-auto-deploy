# Mimir Role

Deploys and manages **Mimir** for the LGTM observability stack using the upstream
`grafana/mimir-distributed` Helm chart (v6.0.6).

The role provisions Mimir into the `monitoring` namespace as a long-term Prometheus
metrics backend, backed by an S3-compatible object store with dedicated buckets for
blocks, alertmanager, and ruler state.

## Requirements

- The `kubernetes.core` Ansible collection
- Access to a Kubernetes cluster
- An S3-compatible object store

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `mimir_uninstall` | `false` | no | Set to `true` to uninstall the Mimir Helm release |
| `endpoint` | `""` | yes | S3-compatible endpoint (e.g. `minio.minio.svc.cluster.local:9000`) |
| `access_key` | `""` | yes | S3 access key |
| `secret_access_key` | `""` | yes | S3 secret access key |
| `blocks_bucket` | `""` | no | S3 bucket name for metric blocks |
| `alertmanager_bucket` | `""` | no | S3 bucket name for alertmanager state |
| `ruler_bucket` | `""` | no | S3 bucket name for ruler state |
| `insecure` | `false` | no | Set to `true` for plain-HTTP object stores |

## Playbook Example

Deploy Mimir against a local MinIO endpoint:

```yaml
- name: Deploy Mimir
  hosts: localhost
  connection: local
  tasks:
    - name: Install Mimir
      ansible.builtin.include_role:
        name: "./helm/mimir"
      vars:
        endpoint: "minio.minio.svc.cluster.local:9000"
        access_key: "admin"
        secret_access_key: "toortoor"
        blocks_bucket: "mimir-blocks"
        alertmanager_bucket: "mimir-alertmanager"
        ruler_bucket: "mimir-ruler"
        insecure: true
```

Uninstall:

```yaml
- name: Remove Mimir
  hosts: localhost
  connection: local
  tasks:
    - name: Uninstall Mimir
      ansible.builtin.include_role:
        name: "./helm/mimir"
      vars:
        mimir_uninstall: true
```

## Notes

- Variables `endpoint`, `access_key`, and `secret_access_key` are validated before
  deployment; the playbook fails if they are empty.
- Mimir is consumed by Grafana at `http://mimir-gateway.monitoring.svc.cluster.local`
  and receives pushes from the k8s-monitoring Alloy agents.
- Chart values are rendered from `templates/values.yml`.