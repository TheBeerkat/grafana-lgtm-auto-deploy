# Grafana Dashboards Role

Imports and removes Grafana dashboard JSON files into a running Grafana instance.

The role reads every `*.json` file in its `files/` directory and applies it via the
Grafana API using the `grafana.grafana.dashboard` module. It deploys by default and
can be toggled to uninstall by changing the `dashboard_state` variable.

## Requirements

- The `grafana.grafana` Ansible collection (`ansible-galaxy collection install grafana.grafana`)
- A running Grafana instance with an API key

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `grafana_url` | `http://localhost:3000` | no | Base URL of the Grafana API |
| `grafana_api_key` | `ey...` | yes | Grafana API key with dashboard edit permissions |
| `dashboard_state` | `present` | no | `present` to import dashboards, anything else to remove them |

## Playbook Example

Import all dashboards from `files/`:

```yaml
- name: Import Grafana dashboards
  hosts: localhost
  connection: local
  tasks:
    - name: Deploy dashboards
      ansible.builtin.include_role:
        name: "./grafana/dashboards"
      vars:
        grafana_url: "http://localhost:3000"
        grafana_api_key: "glsa_ABCDEF..."
```

Remove all dashboards:

```yaml
- name: Remove Grafana dashboards
  hosts: localhost
  connection: local
  tasks:
    - name: Uninstall dashboards
      ansible.builtin.include_role:
        name: "./grafana/dashboards"
      vars:
        grafana_url: "http://localhost:3000"
        grafana_api_key: "glsa_ABCDEF..."
        dashboard_state: absent
```

## Notes

- Dashboard JSON files are placed in the role's `files/` directory (e.g. RED and USE
  dashboard definitions). See [Dashboards.md](./Dashboards.md) for a description of each
  dashboard and its panels.
- Import uses `overwrite: true`, so re-running reimports and updates existing dashboards.