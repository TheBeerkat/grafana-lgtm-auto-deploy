# nginx Role

Deploys and manages the **ingress-nginx** controller using the upstream
`ingress-nginx/ingress-nginx` Helm chart (v4.15.0).

The role deploys the controller into its own `ingress-nginx` namespace, exposed as a
**NodePort** service, so that Nginx Ingresses (such as Grafana) can route external traffic.

## Requirements

- The `kubernetes.core` Ansible collection
- Access to a Kubernetes cluster

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `ingress_nginx_uninstall` | `false` | no | Set to `true` to uninstall the ingress-nginx Helm release |

## Playbook Example

Deploy the ingress-nginx controller:

```yaml
- name: Deploy ingress-nginx
  hosts: localhost
  connection: local
  tasks:
    - name: Install ingress-nginx
      ansible.builtin.include_role:
        name: "./helm/nginx"
```

Uninstall:

```yaml
- name: Remove ingress-nginx
  hosts: localhost
  connection: local
  tasks:
    - name: Uninstall ingress-nginx
      ansible.builtin.include_role:
        name: "./helm/nginx"
      vars:
        ingress_nginx_uninstall: true
```
