ufw-allow-crucible:
  file.managed:
    - name: /etc/ufw/applications.d/crucible.ufw
    - source: salt://atlassian/files/ufw/applications.d/app_config.jinja
    - user: root
    - group: root
    - mode: 0640
    - template: jinja
    - context:
        app: Crucible
        title: Atlassian Crucible
        description: Crucible project management
        ports: '8060/tcp'
  cmd.run:
    - name: 'ufw allow crucible'
    - watch:
        - file: ufw-allow-crucible
