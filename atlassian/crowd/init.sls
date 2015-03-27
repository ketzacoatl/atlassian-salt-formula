# Install Atlassian Crowd
# Create a user for Crowd, use the common Atlassian group
# Hardcode a number of paths and versions, but keep it sane

{#- common to all apps in the atlassian suite -#}
{%- set group = 'atlassian' %}
{%- set atlassian_home = '/opt/atlassian' %}
{%- set atlassian_datadir = '/var/atlassian/application-data' %}

{#- app/service user and home #}
{%- set app = 'crowd' %}
{%- set user = app %}
{%- set home = atlassian_home + '/' + user %}

{#- release info, version specific #}
{%- set version = '2.8.0' %}
{%- set tarball_checksum = 'sha512=7cb1d57653cc4bf2d720a623b876cd17e2b6ff45348626ec227e522de11cc5ab4138b58a07a7739a15d83669a028ebc0db371b6f2688c6dafc51ab9ec9bf7e35' %}


{#- release info, non-version specific #}
{%- set base_url = 'https://www.atlassian.com/software/' + app + '/downloads/binary' %}
{%- set tarball = 'atlassian-' + app + '-' + version + '.tar.gz' %}
{%- set tarball_url = base_url + '/' + tarball %}

{#- local paths #}
{%- set install_to = home + '/release/' + version %}
{%- set active_app = home + '/current' %}
{%- set app_datadir = home + '/data' %}

{#- resource limits #}
{%- set jvm_max_mem = '768' %}
{#- length of time upstart waits before killing non-responsive process #}
{#- http://upstart.ubuntu.com/cookbook/#kill-timeout -#}
{%- set init_kill_timeout = '90' %}

include:
  - atlassian.core
  - atlassian.java.jre


# create a system user and /opt/atlassian/crowd 
crowd-user:
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
        - user: crowd-user
        - file: atlassian
        - group: atlassian


# create a directory for app data
crowd-data:
  file.directory:
    - name: {{ app_datadir }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: 750
    - makedirs: True
    - require:
        - user: crowd-user
        - file: crowd-user


# create /opt/atlassian/crowd/$version/ and unpack the tarball there
crowd-release:
  file.directory:
    - name: {{ install_to }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: 750
    - makedirs: True
    - require:
        - user: crowd-user
        - file: crowd-user
        - group: atlassian
  archive.extracted:
    - name: {{ install_to }}
    - source: {{ tarball_url }}
    - source_hash: {{ tarball_checksum }}
    - if_missing: {{ install_to }}/apache-tomcat/bin/catalina.sh
    - archive_format: tar
    # use --strip-components, removes the leading path in the tarball
    - tar_options: 'z --strip-components=1 '
    - archive_user: {{ user }}
    - require:
        - file: crowd-release

# symlink /opt/atlassian/crowd/current/ -> /opt/atlassian/crowd/$version/
crowd-active-release:
  file.symlink:
    - name: {{ home }}/current
    - target: {{ install_to }}
    - require:
        - archive: crowd-release


# manage tomcat's server.xml for SSL/proxying
crowd-tomcat-server:
  file.managed:
    - name: {{ install_to }}/apache-tomcat/conf/server.xml
    - source: salt://atlassian/files/crowd/server.xml
    - user: {{ user }}
    - group: {{ group }}
    - mode: 640
    # note: atm, context is looked up in the template directly 
    - template: jinja
    - require:
        - archive: crowd-release


# install init script and ensure the service can run
crowd-service:
  file.managed:
    - name: /etc/init/crowd.conf
    - source: salt://atlassian/files/crowd/upstart.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
        runas_user: {{ user }}
        runas_group: {{ group }}
        data_dir: {{ app_datadir }}
        app_path: {{ active_app }}
        pid_path: {{ active_app }}/apache-tomcat/work/crowd.pid
        bin_path: 'apache-tomcat/bin/catalina.sh'
        bin_opts: 'start'
        # pulled these from crowd's startup.sh
        java_opts: '-Xms128m -Xmx512m -XX:MaxPermSize=256m -Dfile.encoding=UTF-8'
        description: 'Atlassian Crowd'
    - require:
        - user: crowd-user
        - file: crowd-active-release
        - file: crowd-data
        - file: crowd-tomcat-server
  service.running:
    - name: crowd
    - enable: True
    - watch:
        - user: crowd-user
        - pkg: openjre
        - file: crowd-service
        - file: crowd-release
        - archive: crowd-release
        - file: crowd-active-release
        - file: crowd-tomcat-server
