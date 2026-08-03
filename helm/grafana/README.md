# Grafana Role

Deploys and manages **Grafana** for the LGTM observability stack using the upstream
`grafana-community/grafana` Helm chart (v12.7.1).

The role provisions Grafana into the `monitoring` namespace with three pre-configured
datasources (Mimir, Loki, and Tempo) and optionally enables PVC-based persistence.

## Requirements

- The `kubernetes.core` Ansible collection (`ansible-galaxy collection install kubernetes.core`)
- Access to a Kubernetes cluster (through `kubectl`/kubeconfig)

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `grafana_uninstall` | `false` | no | Set to `true` to uninstall the Grafana Helm release |
| `persistence` | `true` | yes | Whether Grafana state is persisted on a PVC |

## Playbook Example

Deploy Grafana with persistence enabled:

```yaml
- name: Deploy Grafana
  hosts: localhost
  connection: local
  tasks:
    - name: Install Grafana
      ansible.builtin.include_role:
        name: "./helm/grafana"
      vars:
        persistence: true
```

Uninstall:

```yaml
- name: Remove Grafana
  hosts: localhost
  connection: local
  tasks:
    - name: Uninstall Grafana
      ansible.builtin.include_role:
        name: "./helm/grafana"
      vars:
        grafana_uninstall: true
```

## Notes

- Relies on the role defaults for most settings; the chart values are rendered from
  `templates/values.yml`.
- The datasources assume Mimir, Loki, and Tempo are reachable via their `monitoring`
  namespace services.