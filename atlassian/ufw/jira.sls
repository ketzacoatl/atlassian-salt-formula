ufw-allow-jira:
  file.managed:
    - name: /etc/ufw/applications.d/jira.ufw
    - source: salt://atlassian/files/ufw/applications.d/app_config.jinja
    - user: root
    - group: root
    - mode: 0640
    - template: jinja
    - context:
        app: JIRA
        title: Atlassian JIRA
        description: JIRA project management
        ports: '8080/tcp'
  cmd.run:
    - name: 'ufw allow jira'
    - watch:
        - file: ufw-allow-jira


