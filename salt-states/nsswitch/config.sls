# -*- coding: utf-8 -*-
# vim: ft=sls

{%- from "nsswitch/map.jinja" import nsswitch with context %}
{% set region = grains.get('fit:site:region', '') %}

nsswitch-config:
  file.managed:
    - name: {{ nsswitch.config }}
    - source: 
      - salt://{{ tpldir }}/files/{{ grains['id'] }}/nsswitch.conf
      - salt://{{ tpldir }}/files/{{ region }}/{{ grains['os_family'] }}/nsswitch.conf
      - salt://{{ tpldir }}/files/default/nsswitch.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja
