FROM opensuse:leap
ENV HTTP_PROXY "http://10.133.132.165:8181"
ENV HTTPS_PROXY "http://10.133.132.165:8181"

MAINTAINER FIT <DevOps@FIT>

RUN zypper ref && \
    zypper -n in salt-minion python-M2Crypto && \
    zypper clean -a && \
    mkdir /srv/salt
    
WORKDIR /root/salt-minion

ADD salt-minion.sh /

CMD /salt-minion.sh
