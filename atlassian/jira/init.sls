# Install Atlassian Crowd
# Create a user for Crowd, use the common Atlassian group
# Hardcode a number of paths and versions, but keep it sane

{#- common to all apps in the atlassian suite -#}
{%- set group = 'atlassian' %}
{%- set atlassian_home = '/opt/atlassian' %}
{%- set atlassian_datadir = '/var/atlassian/application-data' %}

{#- app/service user and home #}
{%- set app = 'jira' %}
{%- set user = app %}
{%- set home = atlassian_home + '/' + user %}

{#- release info, version specific #}
{%- set version = '6.4' %}
{%- set tarball_checksum = 'sha512=d7b2a4925d1ad2c83e20484d13bd72ab4bad112d7d568f7255c7a7db786ab40afb64e6414a4527d8d9dedb8d6b145a24f11549bf41869db1fe96908ea60043a2' %}

{#- release info, non-version specific #}
{%- set base_url = 'https://www.atlassian.com/software/' + app + '/downloads/binary' %}
{%- set tarball = 'atlassian-' + app + '-' + version + '.tar.gz' %}
{%- set tarball_url = base_url + '/' + tarball %}

{#- local paths #}
{%- set install_to = home + '/release/' + version %}
{%- set active_app = home + '/current' %}
{%- set app_datadir = home + '/data' %}

{#- resource limits #}
{%- set jvm_max_mem = '1024' %}

include:
  - atlassian.core
  - atlassian.java.jre


# create a system user and /opt/atlassian/jira 
jira-user:
  user.present:
    - name: {{ user }}
    - gid: {{ group }}
    - system: True
    - home: {{ home }}
    - createhome: False
  file.directory:
    - name: {{ home }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: 750
    - makedirs: True
    - require:
        - user: jira-user
        - file: atlassian
        - group: atlassian


# create a directory for app data
jira-data:
  file.directory:
    - name: {{ app_datadir }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: 750
    - makedirs: True
    - require:
        - user: jira-user
        - file: jira-user


# create /opt/atlassian/jira/$version/ and unpack the tarball there
jira-release:
  file.directory:
    - name: {{ install_to }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: 750
    - makedirs: True
    - require:
        - user: jira-user
        - file: jira-user
        - group: atlassian
  archive.extracted:
    - name: {{ install_to }}
    - source: {{ tarball_url }}
    - source_hash: {{ tarball_checksum }}
    - if_missing: {{ install_to }}/bin/catalina.sh
    - archive_format: tar
    # use --strip-components, removes the leading path in the tarball
    - tar_options: 'z --strip-components=1'
    - archive_user: {{ user }}
    - require:
        - file: jira-release

# symlink /opt/atlassian/jira/current/ -> /opt/atlassian/jira/$version/
jira-active-release:
  file.symlink:
    - name: {{ home }}/current
    - target: {{ install_to }}
    - require:
        - archive: jira-release


# manage tomcat's server.xml for SSL/proxying
jira-tomcat-server:
  file.managed:
    - name: {{ install_to }}/conf/server.xml
    - source: salt://atlassian/files/jira/server.xml
    - user: {{ user }}
    - group: {{ group }}
    - mode: 640
    # note: atm, context is looked up in the template directly
    - template: jinja
    - require:
        - archive: jira-release


# install init script and ensure the service can run
jira-service:
  file.managed:
    - name: /etc/init/jira.conf
    - source: salt://atlassian/files/jira/upstart.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
        runas_user: {{ user }}
        runas_group: {{ group }}
        app_path: {{ active_app }}
        data_dir: {{ app_datadir }}
        bin_path: 'bin/start-jira.sh'
        bin_opts: '-fg'
        java_opts: ''
    - require:
        - user: jira-user
        - file: jira-active-release
        - file: jira-tomcat-server
        - file: jira-data
  service.running:
    - name: jira
    - enable: True
    - watch:
        - user: jira-user
        - pkg: openjre
        - file: jira-service
        - file: jira-release
        - archive: jira-release
        - file: jira-active-release
        - file: jira-tomcat-server
