# -*- coding: utf-8 -*-
# vim: ft=sls
{% if salt['grains.get']('fit:site:region') == 'US' %}

include:
  - autofs.install
  - autofs.config
  - autofs.service

{% endif %}