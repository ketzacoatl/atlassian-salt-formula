{%- set ip = salt['grains.get']('ip4_interfaces')['eth0'][0] %}

include:
  - consul.agent

jira-consul-service:
  file.managed:
    - name: /home/consul/conf.d/jira_service.json
    - user: consul
    - group: consul
    - mode: 640
    - contents: |
        {
          "service": {
            "name": "jira",
            "tags": ["atlassian"],
            "address": "{{ ip }}",
            "port": 8080,
            "checks": [
              {
                "script": "pgrep -u jira java",
                "interval": "30s"
              }
            ]
          }
        }
    - watch_in:
        - service: consul-upstart

