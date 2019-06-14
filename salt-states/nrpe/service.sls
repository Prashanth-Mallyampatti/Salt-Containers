# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "nrpe/map.jinja" import nrpe with context %}

include:
  - nrpe.config

{{ sls }}.service:
  service.running:
    - name: {{ nrpe.service.name }}
    - enable: True
    - watch:
      - file: nrpe.config.config