# Install Atlassian Stash from binary installer

{%- set atlassian_group = 'atlassian' %}
{%- set atlassian_home = '/opt/atlassian' %}
{%- set atlassian_datadir = '/var/atlassian/application-data' %}

{%- set stash_user = 'stash' %}
{%- set stash_home = atlassian_home + '/' + stash_user %}

{%- set checksum = 'sha512=c4de7cc647e54854c4439e840d4c7683d6a6d4ea6b95ad34d91bfda9edc42c87bfdc624d6555e50f3af8504cca690747179215e36666515452d053c7a0c29a3b' %}
{%- set version = '3.7.1' %}

{%- set installer_bin = 'atlassian-stash-' + version + '-x64.bin' %}
{%- set installer_url = 'https://www.atlassian.com/software/stash/downloads/binary/' + installer_bin %}

stash-installer-bin:
  file.managed:
    - name: /root/{{ installer_bin }}
    - source: {{ installer_url }}
    - source_hash: {{ checksum }}
    - user: root
    - mode: 550

stash-installer-varfile:
  file.managed:
    - name: /root/stash.varfile
    - user: root
    - mode: 440
    - require:
        - file: stash-installer-bin
    - contents: |
       // Should Stash be installed as a Service? Must be ADMIN (default: true if the
       // process is running with administrator rights, false otherwise). If false,
       // the home and installation directories must be specified to point to
       // directories owned by the user
       app.install.service$Boolean=true

       // The ports Stash should bind to (defaults: portChoice=default, httpPort=7990,
       // serverPort=8006)
       portChoice=custom
       httpPort=7990
       serverPort=8006


       // Path to the Stash HOME directory (default: /var/atlassian/application-data/stash
       // if the process is running with administrator rights,
       // ~/atlassian/application-data/stash otherwise)
       app.stashHome={{ atlassian_datadir }}/stash


       // The target installation directory (default: /opt/atlassian/stash/<VERSION>
       // if the process is running with administrator rights, ~/atlassian/stash/<VERSION>
       // otherwise)
       app.defaultInstallDir={{ stash_home }}/{{ version }}


install-stash:
  cmd.run:
    - name: /root/{{ installer_bin }} -q -varfile /root/stash.varfile
    - user: root
    - require:
        - file: stash-installer-varfile
        - file: atlassian
        - user: stash
        - file: stash

