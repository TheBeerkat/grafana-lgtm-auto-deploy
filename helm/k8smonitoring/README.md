# k8s-monitoring Role

Deploys the **Grafana k8s-monitoring** stack using the upstream `grafana/k8s-monitoring`
Helm chart (v4.2.0).

The role provisions **Alloy** collectors that gather cluster metrics, logs, and traces
and forward them to the LGTM destinations (Mimir, Loki, and Tempo) running in the
`monitoring` namespace. It also deploys supporting exporters (kube-state-metrics and
node-exporter).

## Requirements

- The `kubernetes.core` Ansible collection
- Access to a Kubernetes cluster
- Mimir, Loki, and Tempo already deployed and reachable in the `monitoring` namespace

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `k8smonitoring_uninstall` | `false` | no | Set to `true` to uninstall the k8s-monitoring Helm release |

## Playbook Example

Deploy k8s-monitoring with the default configuration (metrics, logs, traces, events):

```yaml
- name: Deploy k8s-monitoring
  hosts: localhost
  connection: local
  tasks:
    - name: Install k8s-monitoring
      ansible.builtin.include_role:
        name: "./helm/k8smonitoring"
```

Uninstall:

```yaml
- name: Remove k8s-monitoring
  hosts: localhost
  connection: local
  tasks:
    - name: Uninstall k8s-monitoring
      ansible.builtin.include_role:
        name: "./helm/k8smonitoring"
      vars:
        k8smonitoring_uninstall: true
```

## Notes

- No mandatory role variables; the full configuration lives in `templates/values.yml`.
- Destinations are wired to Mimir, Loki, and Tempo gateway/distributor services in the
  `monitoring` namespace.
- Alloy uses annotation autodiscovery to scrape instrumented applications that carry
  `k8s.grafana.com/*` annotations, and Pod Logs are collected via Loki.
- The Alloy receiver (`alloy-receiver` daemonset) exposes OTLP endpoints used by
  instrumented applications to submit traces.