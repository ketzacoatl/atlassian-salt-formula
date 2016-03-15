{%- set ip = salt['grains.get']('ip4_interfaces')['eth0'][0] %}

include:
  - consul.agent

stash-consul-service:
  file.managed:
    - name: /home/consul/conf.d/stash_service.json
    - user: consul
    - group: consul
    - mode: 640
    - contents: |
        {
          "service": {
            "name": "stash",
            "tags": ["atlassian"],
            "address": "{{ ip }}",
            "port": 7990,
            "checks": [
              {
                "script": "sudo service stash status",
                "interval": "30s"
              }
            ]
          }
        }
    - watch_in:
        - service: consul-upstart
