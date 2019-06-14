# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_package_install = tplroot ~ '.install' %}
{%- from tplroot ~ "/map.jinja" import sudoers with context %}
{%- from tplroot ~ "/macros.jinja" import files_switch with context %}
include:
  - {{ sls_package_install }}

sudoers-config-file-file-managed:
  file.managed:
    - name: {{ sudoers.config }}
    - source: 
        - salt://sudoers/files/{{grains.id}}/sudoers
        - salt://sudoers/files/default/sudoers
    - mode: 440
    - user: root
    - group: {{ sudoers.get('group', 'root') }}
    - template: jinja
    - check_cmd: {{ sudoers.get('execprefix', '/usr/sbin') }}/visudo -c -f
    - context:
        included: False
        sudoers: {{ sudoers|json }}
    - require:
      - sls: {{ sls_package_install }}

{% do sudoers.update(pillar.get('sudoers', {})) %}
{% set includedir = sudoers.get('includedir', '/etc/sudoers.d') %}
{% set included_files = sudoers.get('included_files', {}) %}
{% for included_file,spec in included_files.items() -%}
formula.sudoers.config.{{ included_file }}:
  file.managed:
    {% if '/' in included_file %}
    - name: {{ included_file }}
    {% else %}
    - name: {{ includedir }}/{{ included_file }}
    {% endif %}
    - user: root
    - group: {{ sudoers.get('group', 'root') }}
    - mode: 440
    - template: jinja
    - source: 
        - salt://sudoers/files/{{grains.id}}/sudoers
        - salt://sudoers/files/default/sudoers
    - check_cmd: {{ sudoers.get('execprefix', '/usr/sbin') }}/visudo -c -f
    - context:
        included: True
        sudoers: {{ spec|json }}
    - require:
      - file: sudoers-config-file-file-managed
{% endfor %}
  