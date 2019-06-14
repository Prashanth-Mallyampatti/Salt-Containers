{% from salt['file.join'](tpldir,"map.jinja") import nrpe with context %}

{{ sls }}.user.service_stop:
  service.dead:
    - name: {{ nrpe.service }}
    - prereq:
      - user: {{ sls }}.user
      - group: {{ sls }}.group
      - file: {{ sls }}.pid_dir

{{ sls }}.group:
  group.present:
  - name: nagios
{% if nrpe.gid is defined %}
  - gid: {{ nrpe.gid }}
{% endif %}

{{ sls }}.user:
  user.present:
    - name: nagios
    - shell: /bin/bash
{% if nrpe.uid is defined %}
    - uid: {{ nrpe.uid }}
{% endif %}
{% if nrpe.gid is defined %}
    - gid: {{ nrpe.gid }}
{% endif %}

{{ sls }}.pid_dir:
  file.directory:
    - name: {{ nrpe.pid_dir }}
{% if nrpe.uid is defined %}
    - user: {{ nrpe.user }}
{% endif %}
{% if nrpe.gid is defined %}
    - group: {{ nrpe.group }}
{% endif %}

{{ sls }}.user.service_start:
  service.running:
    - name: {{ nrpe.service }}
