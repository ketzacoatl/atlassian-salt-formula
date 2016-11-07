{%- set ip = salt['grains.get']('ip4_interfaces')['eth0'][0] %}

include:
  - consul.agent

confluence-consul-service:
  file.managed:
    - name: /home/consul/conf.d/confluence_service.json
    - user: consul
    - group: consul
    - mode: 640
    - contents: |
        {
          "service": {
            "name": "confluence",
            "tags": ["atlassian"],
            "address": "{{ ip }}",
            "port": 8090,
            "checks": [
              {
                "script": "pgrep -u confluence java",
                "interval": "30s"
              }
            ]
          }
        }
    - watch_in:
        - service: consul-upstart

