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
    zypper -n install vim && \
    zypper -n install vim-data && \
    mkdir /srv/salt && \
    touch /etc/salt/minion

RUN sed -i 's/#proxy_host:/proxy_host: 10.133.132.165/g' /etc/salt/minion && \
    sed -i 's/#proxy_port:/proxy_port: 8181/g' /etc/salt/minion

VOLUME ["/sys/fs/cgroup", "/run"]

ADD salt-minion.sh /

CMD /salt-minion.sh
CMD ["/sbin/init"]
