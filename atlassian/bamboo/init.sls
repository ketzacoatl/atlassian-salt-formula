# Install Atlassian Crowd
# Create a user for Crowd, use the common Atlassian group
# Hardcode a number of paths and versions, but keep it sane

{#- common to all apps in the atlassian suite -#}
{%- set group = 'atlassian' %}
{%- set atlassian_home = '/opt/atlassian' %}
{%- set atlassian_datadir = '/var/atlassian/application-data' %}

{#- app/service user and home #}
{%- set app = 'bamboo' %}
{%- set user = app %}
{%- set home = atlassian_home + '/' + user %}

{#- release info, version specific #}
{%- set version = '5.9.4' %}
{%- set tarball_checksum = 'sha512=0c968e25dc7b73bbbbd7f32bee3cf3ddfa07587c88245e34b7b427e12b84315826b706dc896d5b1a361ffadc9d978b8e2d3d9b8fae9e0223f870f3a1933970b8' %}

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
    - source_hash: {{ tarball_checksum }}
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
    - source: salt://atlassian/files/bamboo/server.xml
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
        - pkg: openjre
        - file: bamboo-service
        - file: bamboo-release
        - archive: bamboo-release
        - file: bamboo-active-release
        - file: bamboo-tomcat-server
