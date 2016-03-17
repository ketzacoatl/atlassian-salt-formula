# Install Atlassian Bitbucket server
# Adapted from Atlassian Stash, Bitbucket's predecessor
# Create a user for , use the common Atlassian group
# Hardcode a number of paths and versions, but keep it sane
{% from "bitbucket/maps/bitbucket/checksum_map.jinja" import bitbucket_checksum_map with context %}
{% from "bitbucket/maps/stash/checksum_map.jinja" import stash_checksum_map with context %}

{%- set group = 'atlassian' %}
{%- set atlassian_home = '/opt/atlassian' %}
{%- set atlassian_datadir = '/var/atlassian/application-data' %}

{%- set app = salt['pillar.get']('atlassian:bitbucket:app', 'bitbucket') %}
{%- set user = app %}
{%- set home = atlassian_home ~ '/' ~ user %}

{%- if app == "bitbucket" %}
  {%- set default_version = '4.4.1' %}
  {%- set version = salt['pillar.get']('atlassian:bitbucket:version', default_version %}
  {%- set default_checksum = bitbucket_checksum_map[version] %}
  {%- set default_base_url = bitbucket_base_url_map[version] %}
  {%- set default_base_url = 'https://www.atlassian.com/software/stash/downloads/binary' %}
{%- elif app == "stash" %}
  {%- set default_version = '3.7.1' %}
  {%- set version = salt['pillar.get']('atlassian:bitbucket:version', default_version %}
  {%- set default_checksum = stash_checksum_map[version] %}
  {%- set default_base_url = 'https://downloads.atlassian.com/software/stash/downloads' %}
{%- endif %}

{%- set tarball_checksum = salt['pillar.get']('atlassian:bitbucket:checksum', default_checksum) %}
{%- set base_url = salt['pillar.get']('atlassian:bitbucket:base_url', default_base_url) %}

{%- set tarball = 'atlassian-' ~ app ~ '-' ~ version ~ '.tar.gz' %}
{%- set tarball_url = base_url ~ '/' ~ tarball %}

{%- set install_to = home ~ '/release/' ~ version %}
{%- set active_app = home ~ '/current' %}
{%- set app_datadir = home ~ '/data' %}

{#- resource limits #}
{%- set jvm_max_mem = '768' %}
{#- length of time upstart waits before killing non-responsive process #}
{#- http://upstart.ubuntu.com/cookbook/#kill-timeout -#}
{%- set init_kill_timeout = '90' %}

include:
  - atlassian.core
  - atlassian.java.jre
  - atlassian.bitbucket.backup_logs


# create a system user and /opt/atlassian/bitbucket
bitbucket-user:
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
        - user: bitbucket-user
        - file: atlassian
        - group: atlassian


# create a directory for app data
bitbucket-data:
  file.directory:
    - name: {{ app_datadir }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: 750
    - makedirs: True
    - require:
        - user: bitbucket-user
        - file: bitbucket-user


# create /opt/atlassian/bitbucket/$version/ and unpack the tarball there
bitbucket-release:
  file.directory:
    - name: {{ install_to }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: 750
    - makedirs: True
    - require:
        - user: bitbucket-user
        - file: bitbucket-user
        - group: atlassian
  archive.extracted:
    - name: {{ install_to }}
    - source: {{ tarball_url }}
    - source_hash: sha512={{ tarball_checksum }}
    - if_missing: {{ install_to }}/bin/
    - archive_format: tar
    # use --strip-components, removes the leading path in the tarball
    - tar_options: 'z --strip-components=1 '
    - archive_user: {{ user }}
    - require:
        - file: bitbucket-release

# symlink /opt/atlassian/bitbucket/current/ -> /opt/atlassian/bitbucket/$version/
bitbucket-active-release:
  file.symlink:
    - name: {{ home }}/current
    - target: {{ install_to }}
    - require:
        - archive: bitbucket-release


# ensure the service has env setup with proper umask (Atlassian recommended)
bitbucket-user-set-umask:
  file.replace:
    - pattern: '# umask 0027'
    - repl: 'umask 0027'
    - name: {{ install_to }}/bin/setenv.sh


# install init script and ensure the service can run
bitbucket-service:
  file.managed:
    - name: /etc/init/{{ app }}.conf
    - source: salt://atlassian/files/bitbucket/upstart.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
        kill_timeout: {{ init_kill_timeout }}
        runas_user: {{ user }}
        runas_group: {{ group }}
        app_path: {{ active_app }}
        data_dir: {{ app_datadir }}
        bin_path: bin/start-{{ app }}.sh
        java_opts: '-Xms768m -Xmx1g'
        log_path: {{ log_path }}
    - require:
        - user: bitbucket-user
        - file: bitbucket-active-release
        - file: bitbucket-data
        - file: bitbucket-user-set-umask
        - file: bitbucket-log-file
  service.running:
    - name: {{ app }}
    - enable: True
    - require:
        - pkg: openjre
        - user: bitbucket-user
    - watch:
        - file: bitbucket-service
        - file: bitbucket-release
        - file: bitbucket-active-release
        - archive: bitbucket-release
