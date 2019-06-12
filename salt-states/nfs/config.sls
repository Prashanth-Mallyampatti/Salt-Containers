# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "nfs/map.jinja" import nfs with context %}
{% from "nfs/macros.jinja" import files_switch with context %}

include:
  - nfs.install

{% if grains.os_family == 'Suse'%}

formula.nfsd.defaults:
  cmd.run:
    - name: sed -i 's/MOUNTD_PORT=""/MOUNTD_PORT="2050"/' {{ nfs.defaults }}
    - unless:
        - ls {{ nfs.defaults }}
        - grep 2050 {{ nfs.defaults }}

{% elif grains.os_family == 'Debian'%}

formula.nfsd.defaults:
  cmd.run:
    - name: 'sed -i "/^RPCMOUNTDOPTS=/s/\"$/ -p 2050\"/" {{ nfs.defaults }}'
    - unless: grep 2050 {{ nfs.defaults }}

{% endif %}

