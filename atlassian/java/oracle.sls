# more or less equivalent to the following:
#   apt-get -y -q update
#   apt-get -y -q upgrade
#   apt-get -y -q install software-properties-common htop
#   add-apt-repository ppa:webupd8team/java
#   apt-get -y -q update
#   echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
#   echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
#   apt-get -y -q install oracle-java8-installer
#   apt-get -y -q install oracle-java7-installer
#   update-java-alternatives -s java-8-oracle

{%- set java7 = 'oracle-java7-installer' %}
{%- set accept_7 = 'echo ' + java7 + ' shared/accepted-oracle-license-v1-1 select true' %}

{%- set java8 = 'oracle-java8-installer' %}
{%- set accept_8 = 'echo ' + java8 + ' shared/accepted-oracle-license-v1-1 select true' %}
{%- set set_selections = '/usr/bin/debconf-set-selections' %}
{%- set oracle_java = 'oracle-java8-installer' %}

oracle-java:
  pkgrepo.managed:
    - humanname: Oracle Java PPA
    - ppa: webupd8team/java
    - file: /etc/apt/sources.list.d/oracle_java.list
  cmd.run:
    - name: '{{ accept_8 }} | {{ set_selections }}'
    - require:
        - pkgrepo: oracle-java
  pkg.latest:
    - name: {{ oracle_java }}
    - require:
        - cmd: oracle-java

oracle-java-8:
  cmd.run:
    - name: 'update-java-alternatives -s java-8-oracle'
    - require:
        - pkg: oracle-java
