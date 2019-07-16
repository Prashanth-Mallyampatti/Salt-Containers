FROM scratch
ENV HTTP_PROXY "http://10.133.132.165:8181"
ENV HTTPS_PROXY "http://10.133.132.165:8181"

MAINTAINER itmall@FIT

ADD openSUSE-Leap-x86_64-42.3.0-docker-Build3.5.tar.xz /

RUN zypper install -y dbus-1 systemd-sysvinit
RUN cp /usr/lib/systemd/system/dbus.service /etc/systemd/system/; \
    sed -i 's/OOMScoreAdjust=-900//' /etc/systemd/system/dbus.service

RUN zypper ref && \
    zypper -n in salt-minion python-M2Crypto && \
    zypper clean -a && \
    zypper -n install vim && \
    zypper -n install vim-data && \
    zypper -n install ksh && \
    zypper -n install which && \
    zypper -n install command-not-found && \
    zypper -n install cron* && \
    mkdir /srv/salt && \
    touch /etc/salt/minion && \
    sed -i 's/#proxy_host:.*/proxy_host: http:\/\/10.133.132.165/g' /etc/salt/minion && \
    sed -i 's/#proxy_port:.*/proxy_port: 8181/g' /etc/salt/minion

VOLUME ["/sys/fs/cgroup", "/run"]

ADD salt-minion.sh /

CMD /salt-minion.sh
CMD ["/bin/bash"]
