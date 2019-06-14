{% from "monitoring/nrpe/map.jinja" import nrpe with context -%}

{% for package in nrpe.packages %}
formula.nrpe.{{ package }}:
  module_and_function: pkg.version
  args:
    - {{ package }}
  assertion: assertNotEqual
  expected-return: ''
{% endfor %}

{% for key,value in {
  'mode': '0644',
  'user': nrpe.user,
  'group': nrpe.group,
}.items() %}
formula.nrpe.config.{{ key }}:
  module_and_function: file.get_{{ key }}
  args:
    - {{ nrpe.server_dir }}/nrpe.cfg
  assertion: assertEqual
  expected-return: '{{ value }}'
{% endfor %}

formula.nrpe.config.symlink:
  module_and_function: file.readlink
  args:
    - /etc/nrpe.cfg
  assertion: assertEqual
  expected-return: /etc/nagios/nrpe.cfg

formula.nrpe.service:
  module_and_function: service.status
  args:
    - {{ nrpe.service }}
  assertion: assertTrue