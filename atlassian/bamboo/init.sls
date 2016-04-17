# Install Atlassian Crowd
# Create a user for Crowd, use the common Atlassian group
# Hardcode a number of paths and versions, but keep it sane
{% from "atlassian/bamboo/maps.jinja" import checksum_map, java_include_map, java_require_map with context %}

{#- common to all apps in the atlassian suite -#}
{%- set group = 'atlassian' %}
{%- set atlassian_home = '/opt/atlassian' %}

{#- app/service user and home #}
{%- set app = 'bamboo' %}
{%- set user = app %}
{%- set home = atlassian_home ~ '/' ~ user %}

{#- release info, version specific #}
{%- set default_version = '5.10.3' %}
{%- set version = salt['pillar.get']('atlassian:bamboo:version', default_version) %}
{%- set default_checksum = checksum_map[version] %}
{%- set java_include = java_include_map[version] %}
{%- set java_require = java_require_map[version] %}
{%- set tarball_checksum = salt['pillar.get']('atlassian:bamboo:checksum', default_checksum) %}

{#- release info, non-version specific #}
{%- set base_url = 'https://www.atlassian.com/software/' ~ app ~ '/downloads/binary' %}
{%- set tarball = 'atlassian-' ~ app ~ '-' ~ version ~ '.tar.gz' %}
{%- set tarball_url = base_url ~ '/' ~ tarball %}

{#- local paths #}
{%- set install_to = home ~ '/release/' ~ version %}
{%- set active_app = home ~ '/current' %}
{%- set app_datadir = home + '/data' %}

{#- resource limits #}
{%- set jvm_max_mem = '1024' %}

include:
  - atlassian.core
  - {{ java_include }}


# create a system user and /opt/atlassian/bamboo 
bamboo-user:
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
        - user: bamboo-user
        - file: atlassian
        - group: atlassian


# create a directory for app data
bamboo-data:
  file.directory:
    - name: {{ app_datadir }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: 750
    - makedirs: True
    - require:
        - user: bamboo-user
        - file: bamboo-user


# create /opt/atlassian/bamboo/$version/ and unpack the tarball there
bamboo-release:
  file.directory:
    - name: {{ install_to }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: 750
    - makedirs: True
    - require:
        - user: bamboo-user
        - file: bamboo-user
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
        - file: bamboo-release

# symlink /opt/atlassian/bamboo/current/ -> /opt/atlassian/bamboo/$version/
bamboo-active-release:
  file.symlink:
    - name: {{ home }}/current
    - target: {{ install_to }}
    - require:
        - archive: bamboo-release


# manage tomcat's server.xml for SSL/proxying
bamboo-tomcat-server:
  file.managed:
    - name: {{ install_to }}/conf/server.xml
    - source: salt://atlassian/files/bamboo/{{ version }}/server.xml
    - user: {{ user }}
    - group: {{ group }}
    - mode: 640
    # note: atm, context is looked up in the template directly
    - template: jinja
    - require:
        - archive: bamboo-release


# install init script and ensure the service can run
bamboo-service:
  file.managed:
    - name: /etc/init/bamboo.conf
    - source: salt://atlassian/files/bamboo/upstart.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
        runas_user: {{ user }}
        runas_group: {{ group }}
        app_path: {{ active_app }}
        data_dir: {{ app_datadir }}
        pid_path: {{ active_app }}/work/bamboo.pid
        bin_path: 'bin/start-bamboo.sh'
        bin_opts: '-fg'
        java_opts: ''
    - require:
        - user: bamboo-user
        - file: bamboo-active-release
        - file: bamboo-tomcat-server
        - file: bamboo-data
  service.running:
    - name: bamboo
    - enable: True
    - watch:
        - user: bamboo-user
        - pkg: {{ java_require }}
        - file: bamboo-service
        - file: bamboo-release
        - archive: bamboo-release
        - file: bamboo-active-release
        - file: bamboo-tomcat-server
