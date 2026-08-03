# Loki Role

Deploys and manages **Loki** for the LGTM observability stack using the upstream
`grafana-community/loki` Helm chart (v18.1.1).

The role provisions Loki into the `monitoring` namespace in **distributed mode**,
backed by an S3-compatible object store, and creates the required buckets.

## Requirements

- The `kubernetes.core` Ansible collection
- Access to a Kubernetes cluster
- An S3-compatible object store (MinIO, Ceph, AWS S3, Cloudflare R2, etc.)

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `loki_uninstall` | `false` | no | Set to `true` to uninstall the Loki Helm release |
| `chunk_bucket` | `"chunk"` | no | S3 bucket name for log chunks |
| `ruler_bucket` | `"ruler"` | no | S3 bucket name for ruler (alerting) state |
| `admin_bucket` | `"admin"` | no | S3 bucket name for admin/API state |
| `endpoint` | `""` | yes | S3-compatible endpoint (e.g. `minio.minio.svc.cluster.local:9000`) |
| `access_key` | `""` | yes | S3 access key |
| `secret_access_key` | `""` | yes | S3 secret access key |
| `allow_insecure_http` | `false` | no | Set to `true` for plain-HTTP object stores |
| `replicas` | `2` | no | Replica count for Loki components |
| `maxunavailable` | `1` | no | `maxUnavailable` for rolling updates |

## Playbook Example

Deploy Loki pointing at a local MinIO endpoint:

```yaml
- name: Deploy Loki
  hosts: localhost
  connection: local
  tasks:
    - name: Install Loki
      ansible.builtin.include_role:
        name: "./helm/loki"
      vars:
        chunk_bucket: "loki-chunk"
        ruler_bucket: "loki-ruler"
        admin_bucket: "loki-admin"
        endpoint: "http://minio.minio.svc.cluster.local:9000"
        access_key: "admin"
        secret_access_key: "toortoor"
        allow_insecure_http: true
        replicas: 3
        maxunavailable: 1
```

Uninstall:

```yaml
- name: Remove Loki
  hosts: localhost
  connection: local
  tasks:
    - name: Uninstall Loki
      ansible.builtin.include_role:
        name: "./helm/loki"
      vars:
        loki_uninstall: true
```

## Notes

- Variables `endpoint`, `access_key`, and `secret_access_key` are validated before
  deployment; the playbook fails if they are empty.
- Buckets are expected to exist or be created automatically by your object store
  (the stack provisioner creates: `loki-chunk`, `loki-ruler`, `loki-admin`).
- Chart values are rendered from `templates/values.yml`.