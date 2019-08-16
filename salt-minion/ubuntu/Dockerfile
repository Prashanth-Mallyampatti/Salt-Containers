FROM ubuntu:18.04
ENV http_proxy "http://10.133.132.165:8181"
ENV https_proxy "http://10.133.132.165:8181"
ENV container docker

MAINTAINER Prashanth_M@SYNTAX

ARG DEBIAN_FRONTEND=noninteractive

RUN \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install ubuntu-server && \
    apt-get install -y build-essential && \
    apt-get install -y software-properties-common && \
    apt-get install -y curl git htop man unzip vim wget python openssh-server openssh-client && \
    apt-get install -y locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/lib/dpkg/lock* && \
    rm -rf /var/cache/apt/archives/lock && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ENV LANG en_US.utf8

RUN cd /lib/systemd/system/sysinit.target.wants/ \
    && ls | grep -v systemd-tmpfiles-setup | xargs rm -f $1

RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/basic.target.wants/* \
    /lib/systemd/system/anaconda.target.wants/* \
    /lib/systemd/system/plymouth* \
    /lib/systemd/system/systemd-update-utmp*

RUN systemctl set-default multi-user.target
ENV init /lib/systemd/systemd
VOLUME [ "/sys/fs/cgroup" ]

RUN \
    wget -O - https://repo.saltstack.com/apt/ubuntu/18.04/amd64/latest/SALTSTACK-GPG-KEY.pub | apt-key add - && \
    touch /etc/apt/sources.list.d/saltstack.list && \
    echo "deb http://repo.saltstack.com/apt/ubuntu/18.04/amd64/latest bionic main" >> /etc/apt/sources.list.d/saltstack.list && \
    apt-get update && \
    apt-get install -y salt-minion && \
    mkdir /srv/salt

RUN touch /etc/salt/minion && \
    sed -i 's/#proxy_host:.*/proxy_host: http:\/\/10.133.132.165/g' /etc/salt/minion && \
    sed -i 's/#proxy_port:.*/proxy_port: 8181/g' /etc/salt/minion




RUN service salt-minion restart

CMD ["/usr/sbin/init"]
