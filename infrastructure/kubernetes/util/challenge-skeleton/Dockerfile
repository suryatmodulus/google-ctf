FROM kctf-nsjail

RUN apt-get -y update
RUN apt-get -y upgrade

COPY files /chroot/home/user
COPY config/nsjail.cfg /nsjail.cfg

CMD /usr/bin/k8s_nsjail_setup.sh && exec setpriv --init-groups --reset-env --reuid user --regid user --inh-caps=-all -- /usr/bin/nsjail --config /nsjail.cfg
