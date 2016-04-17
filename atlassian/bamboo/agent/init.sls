# Install Bamboo Remote Agent
{#- Default parameters -#}
{%- set default_version = '5.10.3' %}
{%- set default_bamboo_master = 'bamboo.service.consul' %}

{#- Configurable parameters -#}
{%- set version = salt['pillar.get']('atlassian:bamboo_agent:version', default_version) %}
{%- set bamboo_master = salt['pillar.get']('atlassian:bamboo_agent:master_addr', default_bamboo_master) %}

{#- common to all apps in the atlassian suite -#}
{%- set group = 'atlassian' %}
{%- set atlassian_home = '/opt/atlassian' %}

{#- app/service user and home #}
{%- set app = 'bamboo-agent' %}
{%- set user = app %}
{%- set home = atlassian_home ~ '/' ~ user %}

{#- release info, version specific #}
{% from "atlassian/bamboo/agent/maps.jinja" import checksum_map, java_include_map, java_require_map with context %}
{%- set jarfile_checksum = 'sha512=' ~ checksum_map[version] %}
{%- set java_include = java_include_map[version] %}
{%- set java_require = java_require_map[version] %}

{#- release info, non-version specific #}
{%- set base_url = bamboo_master ~ '/agentServer/agentInstaller' %}
{%- set jarfile = 'atlassian-bamboo-agent-installer-' ~ version ~ '.jar' %}
{%- set jarfile_url = base_url ~ '/' ~ jarfile %}

{#- local paths #}
{%- set install_to = home ~ '/bin'  %}
{%- set app_datadir = home ~ '/data' %}

{#- resource limits #}
{%- set jvm_max_mem = '1024' %}

include:
  - atlassian.core
  - {{ java_include }}


# create a system user and /opt/atlassian/bamboo-agent
bamboo-agent-user:
  user.present:
    - name: {{ user }}
    - gid: {{ group }}
    - system: True
    - home: {{ home }}
    - createhome: False
    - groups:
        - docker
  file.directory:
    - name: {{ home }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: 750
    - makedirs: True
    - require:
        - user: bamboo-agent-user
        - file: atlassian
        - group: atlassian


# create a directory for app data
bamboo-agent-data:
  file.directory:
    - name: {{ app_datadir }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: 750
    - makedirs: True
    - require:
        - user: bamboo-agent-user
        - file: bamboo-agent-user


# create /opt/atlassian/bamboo_agent/bin/ and unpack the jarfile there
bamboo-agent-release:
  file.managed:
    - name: {{ install_to }}/{{ jarfile }}
    - source: {{ jarfile_url }}
    - source_hash: {{ jarfile_checksum }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: 750
    - makedirs: True
    - require:
        - user: bamboo-agent-user
        - file: bamboo-agent-user
        - group: atlassian


# install init script and ensure the service can run
bamboo-agent-service:
  file.managed:
    - name: /etc/init/bamboo-agent.conf
    - user: root
    - group: root
    - mode: 644
    - contents: |
        description "Atlassian Bamboo Remote (build) Agent"
        
        start on filesystem
        stop on runlevel [!2345]
        
        setuid {{ user }}
        setgid {{ group }}
        
        chdir {{ home }}
        
        script
        java -Dbamboo.Home={{ app_datadir }} -jar {{ install_to }}/{{ jarfile }} {{ bamboo_master }}/agentServer/
        end script
        
    - require:
        - user: bamboo-agent-user
        - file: bamboo-agent-release
        - file: bamboo-agent-data
  service.running:
    - name: bamboo-agent
    - enable: True
    - watch:
        - user: bamboo-agent-user
        - pkg: {{ java_require }}
        - file: bamboo-agent-service
        - file: bamboo-agent-release
