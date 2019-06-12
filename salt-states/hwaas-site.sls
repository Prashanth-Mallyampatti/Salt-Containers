hwaas-user:
  user.present:
    - name: hwaas
    - home: /home/hwaas

git-client-package:
  pkg.installed:
    - name: git

hwaas-source:
  git.latest:
    - name: https://github.com/floyd-may/hwaas.git
    - rev: master
    - target: /home/hwaas/hwaas-site

hwaas-npm-install:
  cmd.wait:
    - name: zypper install -y npm
    - cwd: /home/hwaas/hwaas-site
    - watch:
      - git: hwaas-source

hwaas-build-script:
  cmd.wait:
    - name: npm run-script build
    - cwd: /home/hwaas/hwaas-site
    - watch:
      - cmd: hwaas-npm-install
