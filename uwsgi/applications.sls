{% from 'uwsgi/map.jinja' import uwsgi, sls_block with context %}
{% from 'uwsgi/application_config.sls' import application_states with context %}
{% from 'uwsgi/service.sls' import service_function with context %}

{% macro file_requisites(states) %}
      {%- for state in states %}
      - file: {{ state }}
      {%- endfor -%}
{% endmacro %}

include:
  - uwsgi.service
  - uwsgi.application_config

{% if grains['os_family']=="Gentoo" and grains['init']=="systemd" %}

{% for application, settings in uwsgi.applications.managed.items() %}
{% set conf = 'application_conf_' ~ loop.index0 %}
uwsgi-service-{{ application }}:
{% if settings.enabled == True %}
  service.running:
    - enable: True
{% elif settings.enabled == False %}
  service.dead:
    - enable: False
{% endif %}
    - name: {{ uwsgi.lookup.uwsgi_service }}@{{ application }}
    - watch:
      - file: {{ conf }}
    - require:
      - file: {{ conf }}

{% endfor %}

{% else %}

{% if application_states|length() > 0 %}
uwsgi_service_reload:
  service.{{ service_function }}:
    - name: {{ uwsgi.lookup.uwsgi_service }}
    - reload: True
    - use:
      - service: uwsgi_service
    - watch:
      {{ file_requisites(application_states) }}
    - require:
      {{ file_requisites(application_states) }}
      - service: uwsgi_service
{% endif %}

{% endif %}
