{%- set ip = salt['grains.get']('ip4_interfaces')['eth0'][0] %}
{%- set app = salt['pillar.get']('atlassian:bitbucket:app', 'bitbucket') %}

include:
  - consul.agent

stash-consul-service:
  file.managed:
    - name: /home/consul/conf.d/{{ app }}_service.json
    - user: consul
    - group: consul
    - mode: 640
    - contents: |
        {
          "service": {
            "name": "bitbucket",
            "tags": ["atlassian"],
            "address": "{{ ip }}",
            "port": 7990,
            "checks": [
              {
                "script": "sudo service {{ app }} status",
                "interval": "30s"
              }
            ]
          }
        }
    - watch_in:
        - service: consul-upstart
