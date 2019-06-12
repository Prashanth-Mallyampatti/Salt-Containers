FROM opensuse:leap
ENV HTTP_PROXY "http://10.133.132.165:8181"
ENV HTTPS_PROXY "http://10.133.132.165:8181"

MAINTAINER itmall@FIT


RUN zypper install -y dbus-1 systemd-sysvinit
RUN cp /usr/lib/systemd/system/dbus.service /etc/systemd/system/; \
    sed -i 's/OOMScoreAdjust=-900//' /etc/systemd/system/dbus.service

RUN zypper ref && \
    zypper -n in salt-minion python-M2Crypto && \
    zypper clean -a && \
    mkdir /srv/salt

VOLUME ["/sys/fs/cgroup", "/run"]

ADD salt-minion.sh /

CMD /salt-minion.sh
CMD ["/sbin/init"]
