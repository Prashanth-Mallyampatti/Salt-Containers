# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "autofs/map.jinja" import autofs with context %}

include:
  - autofs.config

formula.autofs.service:
  service.running:
    - name: {{ autofs.service.name }}
    - enable: True
