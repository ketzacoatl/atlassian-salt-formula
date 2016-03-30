# Install Atlassian Confluence
# Create a user for Confluence, use the common Atlassian group
# Hardcode a number of paths and versions, but keep it sane
{% from "atlassian/confluence/maps.jinja" import checksum_map, url_map, java_include_map, java_require_map with context %}

{#- common to all apps in the atlassian suite -#}
{%- set group = 'atlassian' %}
{%- set atlassian_home = '/opt/atlassian' %}

{#- app/service user and home #}
{%- set app = 'confluence' %}
{%- set user = app %}
{%- set home = atlassian_home + '/' + user %}

{#- release info, version specific #}
{%- set default_version = '5.9.7' %}
{%- set version = salt['pillar.get']('atlassian:confluence:version', default_version) %}
{%- set default_checksum = checksum_map[version] %}
{%- set default_base_url = url_map[version] %}
{%- set java_include = java_include_map[version] %}
{%- set java_require = java_require_map[version] %}

{#- release info, non-version specific #}
{%- set tarball_checksum = salt['pillar.get']('atlassian:conflucence:checksum', default_checksum) %}
{%- set base_url = salt['pillar.get']('atlassian:confluence:base_url', default_base_url) %}
{%- set tarball = 'atlassian-' + app + '-' + version + '.tar.gz' %}
{%- set tarball_url = base_url + '/' + tarball %}

{#- local paths #}
{%- set install_to = home + '/release/' + version %}
{%- set active_app = home + '/current' %}
{%- set app_datadir = home + '/data' %}

include:
  - atlassian.core
  - {{ java_include }}


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
    - source_hash: sha512={{ tarball_checksum }}
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
    - source: salt://atlassian/files/confluence/{{ version }}/server.xml
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
    - source: salt://atlassian/files/confluence/{{ version }}/confluence-init.properties
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
        - pkg: {{ java_require }}
        - file: confluence-service
        - file: confluence-release
        - archive: confluence-release
        - file: confluence-active-release
        - file: confluence-tomcat-server
        - file: confluence-init-config
