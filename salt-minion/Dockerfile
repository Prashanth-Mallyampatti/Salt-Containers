FROM opensuse:leap
ENV HTTP_PROXY "http://10.133.132.165:8181"
ENV HTTPS_PROXY "http://10.133.132.165:8181"


MAINTAINER SUSE Containers Team <containers@suse.com>

RUN zypper ref && \
    zypper -n in salt-minion python-M2Crypto && \
    zypper clean -a

ADD salt-minion.sh /

CMD /salt-minion.sh
