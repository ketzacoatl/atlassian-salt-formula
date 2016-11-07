{%- set ip = salt['grains.get']('ip4_interfaces')['eth0'][0] %}

include:
  - consul.agent

crowd-consul-service:
  file.managed:
    - name: /home/consul/conf.d/crowd_service.json
    - user: consul
    - group: consul
    - mode: 640
    - contents: |
        {
          "service": {
            "name": "crowd",
            "tags": ["atlassian"],
            "address": "{{ ip }}",
            "port": 8095,
            "checks": [
              {
                "script": "pgrep -u crowd java",
                "interval": "30s"
              }
            ]
          }
        }
    - watch_in:
        - service: consul-upstart

