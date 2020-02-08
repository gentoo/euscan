# Copyright 2020 Gentoo Authors
# Licensed under the GNU General Public License v2

FROM gentoo/stage3-amd64:20200208

RUN wget https://gentoo.osuosl.org/snapshots/gentoo-latest.tar.xz \
        && \
    tar -C /var/db/repos/ -x -p -f gentoo-latest.tar.xz \
        && \
    mv /var/db/repos/gentoo-20??????/ /var/db/repos/gentoo/ \
        && \
    rm gentoo-latest.tar.xz

RUN emaint sync --repo gentoo

RUN eselect profile show \
        && \
    echo 'net-analyzer/rrdtool python' > /etc/portage/package.use/net-analyzer--rrdtool \
        && \
    echo 'dev-lang/python:2.7 sqlite tk' > /etc/portage/package.use/dev-lang--python \
        && \
    echo 'PYTHON_TARGETS="${PYTHON_TARGETS} python2_7"' >> /etc/portage/make.conf \
        && \
    echo 'PYTHON_SINGLE_TARGET="python2_7"' >> /etc/portage/make.conf \
        && \
    echo 'USE="${USE} bindist -syslog"' >> /etc/portage/make.conf

# NOTE: First build dependencies, then runtime-only dependencies
RUN emerge --tree -v -j2 --color y -1uU \
            dev-lang/python:2.7 \
            dev-libs/cyrus-sasl \
            dev-python/pip \
            dev-python/setuptools \
            dev-python/wheel \
            net-nds/openldap \
            \
            app-portage/eix \
            app-portage/gentoolkit \
            app-portage/layman \
            net-analyzer/rrdtool \
            sys-apps/portage \
        && \
    rm -f /var/cache/distfiles/*

ENV PATH=/root/.local/bin/:${PATH}
COPY requirements.txt            /tmp/euscan/
RUN pip2 install --user -r /tmp/euscan/requirements.txt

COPY setup.py README.rst         /tmp/euscan/
COPY bin/                        /tmp/euscan/bin/
COPY pym/                        /tmp/euscan/pym/

WORKDIR /tmp/euscan/
RUN pip2 install --user .

RUN pip2 check
RUN bash -c 'diff -U0 <(pip2 freeze --user | sed "/^\(euscan\|virtualenv\)==/d" | sort -f) <(sed -e "s/ *#.*//" -e "/^$/d" /tmp/euscan/requirements.txt | sort -f)'

COPY euscanwww/                  /tmp/euscan/euscanwww/

COPY docker-entrypoint.sh        /root/

WORKDIR /tmp/euscan/euscanwww/

EXPOSE 55080
ENTRYPOINT ["/root/docker-entrypoint.sh"]
CMD []
