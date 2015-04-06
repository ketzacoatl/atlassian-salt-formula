# Install Atlassian Crucible
# Create a user for Crucible, use the common Atlassian group
# Hardcode a number of paths and versions, but keep it sane

{#- common to all apps in the atlassian suite -#}
{%- set group = 'atlassian' %}
{%- set atlassian_home = '/opt/atlassian' %}
{%- set atlassian_datadir = '/var/atlassian/application-data' %}

{#- app/service user and home #}
{%- set app = 'crucible' %}
{%- set user = app %}
{%- set home = atlassian_home + '/' + user %}

{#- release info, version specific #}
{%- set version = '3.7.0' %}
{%- set zipfile_checksum = 'sha512=73bf6fedc2cd53385b77d1ec48bd51faf60a83d3833ff03509902c657410d845c11bc3d0a648b37138e7d5bbc1078ab2d74b6c5f218c0ed790b41717866b3089' %}

{#- release info, non-version specific #}
# start with https://www.atlassian.com/software/fisheye/downloads/binary/fisheye-3.7.0.zip
{%- set base_url = 'https://downloads.atlassian.com/software/' + app + '/downloads' %}
{%- set zipfile = app + '-' + version + '.zip' %}
{%- set zipfile_url = base_url + '/' + zipfile %}

{#- local paths #}
{%- set install_to = home + '/release' %}
{%- set installed_path = install_to + '/fecru-' + version %}
{%- set active_app = home + '/current' %}
{%- set app_datadir = home + '/data' %}

{#- resource limits #}
{%- set jvm_max_mem = '1024' %}

include:
  - atlassian.core
  - atlassian.java.jre


# create a system user and /opt/atlassian/crucible 
crucible-user:
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
        - user: crucible-user
        - file: atlassian
        - group: atlassian


# create a directory for app data
crucible-data:
  file.directory:
    - name: {{ app_datadir }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: 750
    - makedirs: True
    - require:
        - user: crucible-user
        - file: crucible-user


# create /opt/atlassian/crucible/$version/ and unpack the tarball there
crucible-release:
  file.directory:
    - name: {{ install_to }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: 750
    - makedirs: True
    - require:
        - user: crucible-user
        - file: crucible-user
        - group: atlassian
  archive.extracted:
    - name: {{ install_to }}
    - source: {{ zipfile_url }}
    - source_hash: {{ zipfile_checksum }}
    - if_missing: {{ installed_path }}/bin/fisheyectl.sh
    - archive_format: zip
    - archive_user: {{ user }}
    - require:
        - file: crucible-release

# symlink /opt/atlassian/crucible/current/ -> /opt/atlassian/crucible/$version/
crucible-active-release:
  file.symlink:
    - name: {{ home }}/current
    - target: {{ installed_path }}
    - require:
        - archive: crucible-release


# manage tomcat's server.xml for SSL/proxying
#crucible-tomcat-server:
#  file.managed:
#    - name: {{ installed_path }}/conf/server.xml
#    - source: salt://atlassian/files/crucible/server.xml
#    - user: {{ user }}
#    - group: {{ group }}
#    - mode: 640
#    # note: atm, context is looked up in the template directly
#    - template: jinja
#    - require:
#        - archive: crucible-release

#crucible-env:
#  file.append:
#    - name: /etc/environment
#    - text: |
#        FISHEYE_INST={{ active_app }}


# install init script and ensure the service can run
crucible-service:
  file.managed:
    - name: /etc/init/crucible.conf
    - source: salt://atlassian/files/crucible/upstart.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
        runas_user: {{ user }}
        runas_group: {{ group }}
        app_path: {{ active_app }}
        data_dir: {{ app_datadir }}
        bin_path: 'bin/fisheyectl.sh'
        bin_opts: 'start'
        java_opts: ''
    - require:
        - user: crucible-user
        - file: crucible-active-release
#       - file: crucible-tomcat-server
        - file: crucible-data
#       - file: crucible-env
  service.running:
    - name: crucible
    - enable: True
    - watch:
        - user: crucible-user
        - pkg: openjre
        - file: crucible-service
        - file: crucible-release
        - archive: crucible-release
        - file: crucible-active-release
#       - file: crucible-tomcat-server
