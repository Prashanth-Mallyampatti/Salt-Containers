# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "nrpe/map.jinja" import nrpe with context %}

{{ sls }}.nrpe-pkg:
  pkg.installed:
    - names: {{ nrpe.pkg | json_encode_list }}
