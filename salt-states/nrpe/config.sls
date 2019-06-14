# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{% from "nrpe/map.jinja" import nrpe with context %}
{% from "nrpe/macros.jinja" import files_switch with context %}

include:
  - nrpe.install

{{ sls }}.config:
  file.managed:
    - name: {{ nrpe.config }}
    - source: {{ files_switch(
                    salt['config.get'](
                        tpldir ~ ':tofs:files:template-config',
                        ['nrpe.cfg']
                    )
              ) }}
      - salt://files/{{ tplroot }}/nrpe.cfg
    - template: jinja
    - mode: 644
    - user: {{ nrpe.user }}
    - group: {{ nrpe.group }}
    - show_changes: False
    - template: jinja
    - makedirs: True

{{ sls }}.fit_plugins:
  file.recurse:
    - name: {{ nrpe.plugin_dir }}/fit-plugins
    - source: salt://{{ tpldir }}/files/fit-plugins
    - show_changes: False
    - user: {{ nrpe.user }}
    - group: {{ nrpe.group }}
    - file_mode: 0755


{# CHECK IF THESE ARE NEEDED
{{ sls }}.pid_folder:
  file.directory:
    - name: /var/run/nrpe
    - user: {{ nrpe.user }}
    - group: {{ nrpe.group }}
    - mode: 0755

{{ sls }}.config.symlink:
  file.symlink:
    - name: /etc/nrpe.cfg
    - target: /etc/nagios/nrpe.cfg
    - force: True
#}
