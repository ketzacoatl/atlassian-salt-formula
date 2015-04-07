# Install Atlassian Confluence
# Create a user for Confluence, use the common Atlassian group
# Hardcode a number of paths and versions, but keep it sane

{#- common to all apps in the atlassian suite -#}
{%- set group = 'atlassian' %}
{%- set atlassian_home = '/opt/atlassian' %}
{%- set atlassian_datadir = '/var/atlassian/application-data' %}

{#- app/service user and home #}
{%- set app = 'confluence' %}
{%- set user = app %}
{%- set home = atlassian_home + '/' + user %}

{#- release info, version specific #}
{%- set version = '5.7.1' %}
{%- set tarball_checksum = 'sha512=7e90a748f7ea2e4a161e8ddaa5789bc3ec0ee0c47a8a3cf4b4d7f8160a819e6c040577de69c6750c3477e06de9d63d869e27c0067f6181280863aa03aed8a5a7' %}

{#- release info, non-version specific #}
{%- set base_url = 'https://downloads.atlassian.com/software/' + app + '/downloads' %}
{%- set tarball = 'atlassian-' + app + '-' + version + '.tar.gz' %}
{%- set tarball_url = base_url + '/' + tarball %}

{#- local paths #}
{%- set install_to = home + '/release/' + version %}
{%- set active_app = home + '/current' %}
{%- set app_datadir = home + '/data' %}

include:
  - atlassian.core
  - atlassian.java.jre


# create a system user and /opt/atlassian/confluence
confluence-user:
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
        - user: confluence-user
        - file: atlassian
        - group: atlassian


# create a directory for app data
confluence-data:
  file.directory:
    - name: {{ app_datadir }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: 750
    - makedirs: True
    - require:
        - user: confluence-user
        - file: confluence-user


# create /opt/atlassian/confluence/$version/ and unpack the tarball there
confluence-release:
  file.directory:
    - name: {{ install_to }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: 750
    - makedirs: True
    - require:
        - user: confluence-user
        - file: confluence-user
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
        - file: confluence-release

# symlink /opt/atlassian/confluence/current/ -> /opt/atlassian/confluence/$version/
confluence-active-release:
  file.symlink:
    - name: {{ home }}/current
    - target: {{ install_to }}
    - require:
        - archive: confluence-release


# manage tomcat's server.xml for SSL/proxying
confluence-tomcat-server:
  file.managed:
    - name: {{ install_to }}/conf/server.xml
    - source: salt://atlassian/files/confluence/server.xml
    - user: {{ user }}
    - group: {{ group }}
    - mode: 640
    # note: atm, context is looked up in the template directly
    - template: jinja
    - require:
        - archive: confluence-release


# manage Confluence's confluence-init.properties
confluence-init-config:
  file.managed:
    - name: {{ install_to }}/confluence/WEB-INF/classes/confluence-init.properties
    - source: salt://atlassian/files/confluence/confluence-init.properties
    - user: {{ user }}
    - group: {{ group }}
    - mode: 640
    # note: atm, context is looked up in the template directly
    - template: jinja
    - context:
        data_dir: {{ app_datadir }}
    - require:
        - archive: confluence-release
        - file: confluence-data
        - user: confluence-user
        - group: atlassian



# install init script and ensure the service can run
confluence-service:
  file.managed:
    - name: /etc/init/confluence.conf
    - source: salt://atlassian/files/confluence/upstart.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
        runas_user: {{ user }}
        runas_group: {{ group }}
        app_path: {{ active_app }}
        bin_path: 'bin/startup.sh'
        bin_opts: '-fg'
        pid_path: {{ active_app }}/work/confluence.pid
        java_opts: ''
    - require:
        - user: confluence-user
        - file: confluence-active-release
        - file: confluence-tomcat-server
        - file: confluence-init-config
        - file: confluence-data
  service.running:
    - name: confluence
    - enable: True
    - watch:
        - user: confluence-user
        - pkg: openjre
        - file: confluence-service
        - file: confluence-release
        - archive: confluence-release
        - file: confluence-active-release
        - file: confluence-tomcat-server
        - file: confluence-init-config
