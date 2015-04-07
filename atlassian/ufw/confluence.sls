ufw-allow-confluence:
  file.managed:
    - name: /etc/ufw/applications.d/confluence.ufw
    - source: salt://atlassian/files/ufw/applications.d/app_config.jinja
    - user: root
    - group: root
    - mode: 0640
    - template: jinja
    - context:
        app: Confluence
        title: Atlassian Confluence
        description: Confluence project management
        ports: '8090/tcp'
  cmd.run:
    - name: 'ufw allow confluence'
    - watch:
        - file: ufw-allow-confluence
