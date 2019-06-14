# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "autofs/map.jinja" import autofs with context %}

formula.autofs.pkg:
  pkg.installed:
    - name: {{ autofs.pkg }}
