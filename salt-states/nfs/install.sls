# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "nfs/map.jinja" import nfs with context %}

nfs-pkg:
  pkg.installed:
    - name: {{ nfs.pkg }}
