ufw-allow-stash:
  file.managed:
    - name: /etc/ufw/applications.d/stash.ufw
    - source: salt://atlassian/files/ufw/applications.d/app_config.jinja
    - user: root
    - group: root
    - mode: 0640
    - template: jinja
    - context:
        app: stash
        title: Atlassian Stash
        description: Stash git repository management
        ports: '7990,7999/tcp'
  cmd.run:
    - name: 'ufw allow stash'
    - watch:
        - file: ufw-allow-stash

