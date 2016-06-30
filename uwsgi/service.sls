{% from "uwsgi/map.jinja" import uwsgi, sls_block with context %}
{% set service_function = {True:'running', False:'dead'}.get(uwsgi.service.enable) %}


include:
  - uwsgi.install

{% if grains['os_family']=="Arch" %}
#TODO 
# still need to figure out how to get applicatication config name
# as service name and iterate and refresh the right one.
#

{% elif grains['os_family']=="Debian" %}

uwsgi_service:
  service.{{ service_function }}:
    {{ sls_block(uwsgi.service.opts) }}
    - name: {{ uwsgi.lookup.uwsgi_service }}
    - enable: {{ uwsgi.service.enable }}
    - require:
      - sls: uwsgi.install
    - watch:
      - pkg: uwsgi_install

{% elif grains['os_family']=="Gentoo" and grains['init']=="systemd" %}

uwsgi_service:
  file.managed:
    - name: /etc/systemd/system/uwsgi@.service
    - source: salt://uwsgi/files/uwsgi@.service
    - template: jinja
    - context:
        uwsgi: {{ uwsgi|json() }}

uwsgi_tmpdir_file:
  file.managed:
    - name: /etc/tmpfiles.d/uwsgi.conf
    - contents: 'd /run/uwsgi 0750 root nginx -'
  cmd.run:
    - name: systemd-tmpfiles --create uwsgi.conf
    - onchanges:
      - file: uwsgi_tmpdir_file

{% else %}
#TODO other os
{% endif%}
