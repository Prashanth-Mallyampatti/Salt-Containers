# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "nfs/map.jinja" import nfs with context %}

include:
  - nfs.config

nfs-name:
  service.running:
    - name: {{ nfs.service.name }}
    - enable: True
