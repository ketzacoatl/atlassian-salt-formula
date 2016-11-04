{%- set ip = salt['grains.get']('ip4_interfaces')['eth0'][0] %}

include:
  - consul.agent

bamboo-consul-service:
  file.managed:
    - name: /home/consul/conf.d/bamboo_service.json
    - user: consul
    - group: consul
    - mode: 640
    - contents: |
        {
          "service": {
            "name": "bamboo",
            "tags": ["atlassian"],
            "address": "{{ ip }}",
            "port": 8085,
            "checks": [
              {
                "script": "pgrep bamboo",
                "interval": "30s"
              }
            ]
          }
        }
    - watch_in:
        - service: consul-upstart

