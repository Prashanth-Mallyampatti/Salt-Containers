{% if grains.os_family == 'Suse'%}

formula.nfsd.sysconfig:
  module_and_function: file.search
  args:
    - /etc/sysconfig/nfs
    - '^MOUNTD_PORT.*2050'
  assertion: assertEqual
  expected-return: True

formula.nfsd.package:
  module_and_function: pkg.version
  args:
    - nfs-kernel-server
  assertion: assertNotEqual
  expected-return: ''

formula.nfsd.service:
  module_and_function: service.status
  args:
    - nfs-server
  assertion: assertEqual
  expected-return: True

{% elif grains.os_family == 'Debian'%}

formula.nfsd.defaults:
  module_and_function: file.search
  args:
    - /etc/default/nfs-kernel-server
    - '^RPCMOUNTDOPTS.*2050'
  assertion: assertEqual
  expected-return: True

formula.nfsd.package:
  module_and_function: pkg.version
  args:
    - nfs-kernel-server
  assertion: assertNotEqual
  expected-return: ''

formula.nfsd.service:
  module_and_function: service.status
  args:
    - nfs-server
  assertion: assertEqual
  expected-return: True

{% endif %}
