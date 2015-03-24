# Install Atlassian Stash
# Create a user for Stash, use the common Atlassian group
# Hardcode a number of paths and versions, but keep it sane

{%- set group = 'atlassian' %}
{%- set atlassian_home = '/opt/atlassian' %}
{%- set atlassian_datadir = '/var/atlassian/application-data' %}

{%- set app = 'stash' %}
{%- set user = app %}
{%- set home = atlassian_home + '/' + user %}

{%- set version = '3.7.1' %}
{%- set tarball_checksum = 'sha512=02baa35f6ef884b5a3071f861367ceb7413b51319fb978111b2d7281ca4a5c9852749dd0dece66cf6e8297df4e4c25192cc543c9d1106e27ae6308f489d15526' %}

{%- set base_url = 'https://downloads.atlassian.com/software/' + app + '/downloads' %}
{%- set tarball = 'atlassian-' + app + '-' + version + '.tar.gz' %}
{%- set tarball_url = base_url + '/' + tarball %}

{%- set install_to = home + '/release/' + version %}
{%- set active_app = home + '/current' %}
{%- set app_datadir = home + '/data' %}

include:
  - atlassian.core
  - atlassian.java.jre


# create a system user and /opt/atlassian/stash 
stash-user:
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
        - user: stash-user
        - file: atlassian
        - group: atlassian


# create a directory for app data
stash-data:
  file.directory:
    - name: {{ app_datadir }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: 750
    - makedirs: True
    - require:
        - user: stash-user
        - file: stash-user


# create /opt/atlassian/stash/$version/ and unpack the tarball there
stash-release:
  file.directory:
    - name: {{ install_to }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: 750
    - makedirs: True
    - require:
        - user: stash-user
        - file: stash-user
        - group: atlassian
  archive.extracted:
    - name: {{ install_to }}
    - source: {{ tarball_url }}
    - source_hash: {{ tarball_checksum }}
    - if_missing: {{ install_to }}/bin/
    - archive_format: tar
    # use --strip-components, removes the leading path in the tarball
    - tar_options: 'z --strip-components=1 '
    - archive_user: {{ user }}
    - require:
        - file: stash-release

# symlink /opt/atlassian/stash/current/ -> /opt/atlassian/stash/$version/
stash-active-release:
  file.symlink:
    - name: {{ home }}/current
    - target: {{ install_to }}
    - require:
        - archive: stash-release


# ensure the service has env setup with proper umask (Atlassian recommended)
stash-user-set-umask:
  file.replace:
    - pattern: '# umask 0027'
    - repl: 'umask 0027'
    - name: {{ install_to }}/bin/setenv.sh


# install init script and ensure the service can run
stash-service:
  file.managed:
    - name: /etc/init.d/stash
    - source: salt://atlassian/files/stash/init.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 755
    - context:
        runas: {{ user }}
        app_path: {{ active_app }}
        data_dir: {{ app_datadir }}
    - require:
        - user: stash-user
        - file: stash-active-release
        - file: stash-data
        - file: stash-user-set-umask
  service.running:
    - name: stash
    - enable: True
    - require:
        - pkg: openjre
        - user: stash-user
    - watch:
        - file: stash-service
        - file: stash-release
        - file: stash-active-release
        - archive: stash-release
