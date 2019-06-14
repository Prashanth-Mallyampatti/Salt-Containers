# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "autofs/map.jinja" import autofs with context %}
{% from "autofs/macros.jinja" import files_switch with context %}

include:
  - autofs.install

formula.autofs.config.master:
  file.managed:
    - name: {{ autofs.config }}/auto.master
    - source: {{ files_switch(
                    salt['config.get'](
                        tpldir ~ ':tofs:files:autofs-config',
                        ['auto.master']
                    )
              ) }}
    - mode: 644
    - user: root
    - group: root
    - template: jinja

formula.autofs.config.home:
  file.managed:
    - name: {{ autofs.config }}/auto.homeLdap
    - source: {{ files_switch(
                    salt['config.get'](
                        tpldir ~ ':tofs:files:autofs-config-home',
                        ['auto.homeLdap']
                    )
              ) }}
    - mode: 644
    - user: root
    - group: root
    - template: jinja
