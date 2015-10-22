{%- set ip = salt['grains.get']('ip4_interfaces')['eth0'][0] %}

include:
  - consul.agent

crucible-consul-service:
  file.managed:
    - name: /home/consul/conf.d/crucible_service.json
    - user: consul
    - group: consul
    - mode: 640
    - contents: |
        {
          "service": {
            "name": "crucible",
            "tags": ["atlassian"],
            "address": "{{ ip }}",
            "port": 8060,
            "checks": [
              {
                "script": "sudo service crucible status",
                "interval": "30s"
              }
            ]
          }
        }
    - watch_in:
        - service: consul-upstart

