FROM rockylinux:9

LABEL org.opencontainers.image.source="https://github.com/giovtorres/slurm-docker-cluster" \
      org.opencontainers.image.title="slurm-docker-cluster" \
      org.opencontainers.image.description="Slurm Docker cluster on Rocky Linux 8" \
      org.label-schema.docker.cmd="docker-compose up -d" \
      maintainer="Giovanni Torres"

RUN set -ex \
    && yum makecache \
    && yum -y update \
    && yum -y install dnf-plugins-core
RUN yum config-manager --enable crb
RUN yum -y install \
       wget \
       bzip2 \
       perl \
       gcc \
       gcc-c++\
       git \
       gnupg \
       make \
       munge \
       munge-devel \
       python3-devel \
       python3-pip \
       python3 \
       mariadb-server \
       mariadb-devel \
       psmisc \
       bash-completion \
       vim-enhanced \
       http-parser-devel \
       json-c-devel \
       libyaml-devel \
       autoconf \
       automake \
       libtool \
       libtool-ltdl-devel \
       jansson-devel \
    && yum clean all \
    && rm -rf /var/cache/yum

RUN pip3 install Cython pytest

ARG GOSU_VERSION=1.17

RUN set -ex \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -rf "${GNUPGHOME}" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

RUN git clone --depth 1 --single-branch -b v1.12.0 https://github.com/benmcollins/libjwt.git libjwt \
    && pushd libjwt \
    && autoreconf --force --install \
    && ./configure --prefix=/usr/ \
    && make -j \
    && make install \
    && popd

RUN git clone --depth 1 --single-branch -b 0.2.5 https://github.com/yaml/libyaml libyaml \
    && pushd libyaml \
    && ./bootstrap \
    && ./configure --prefix=/usr/ \
    && make \
    && make install \
    && popd

ARG SLURM_TAG

RUN set -x \
    && git clone -b ${SLURM_TAG} --single-branch --depth=1 https://github.com/SchedMD/slurm.git \
    && pushd slurm \
    && ./configure --enable-debug --prefix=/usr --sysconfdir=/etc/slurm \
        --with-mysql_config=/usr/bin  --libdir=/usr/lib64 \
        --with-yaml=/usr/ --with-jwt=/usr/ \
    && make install \
    && install -D -m644 etc/cgroup.conf.example /etc/slurm/cgroup.conf.example \
    && install -D -m644 etc/slurm.conf.example /etc/slurm/slurm.conf.example \
    && install -D -m644 etc/slurmdbd.conf.example /etc/slurm/slurmdbd.conf.example \
    && install -D -m644 contribs/slurm_completion_help/slurm_completion.sh /etc/profile.d/slurm_completion.sh \
    && popd \
    && rm -rf slurm \
    && groupadd -r --gid=990 slurm \
    && useradd -r -g slurm --uid=990 slurm \
    && mkdir /etc/sysconfig/slurm \
        /var/spool/slurmd \
        /var/run/slurmd \
        /var/run/slurmdbd \
        /var/lib/slurmd \
        /var/log/slurm \
        /data \
    && touch /var/lib/slurmd/node_state \
        /var/lib/slurmd/front_end_state \
        /var/lib/slurmd/job_state \
        /var/lib/slurmd/resv_state \
        /var/lib/slurmd/trigger_state \
        /var/lib/slurmd/assoc_mgr_state \
        /var/lib/slurmd/assoc_usage \
        /var/lib/slurmd/qos_usage \
        /var/lib/slurmd/fed_mgr_state \
    && chown -R slurm:slurm /var/*/slurm* \
    && /sbin/create-munge-key


RUN mkdir -p /var/spool/slurm/statesave \
    && dd if=/dev/random of=/var/spool/slurm/statesave/jwt_hs256.key bs=32 count=1 \
    && chown slurm:slurm /var/spool/slurm/statesave/jwt_hs256.key \
    && chmod 0600 /var/spool/slurm/statesave/jwt_hs256.key \
    && chown slurm:slurm /var/spool/slurm/statesave \
    && chmod 0755 /var/spool/slurm/statesave

# setup slip
RUN yum -y install  python3.11 && \
  python3.11 -m ensurepip --upgrade

RUN python3.11 -m pip install --extra-index-url https://artefact.skao.int/repository/pypi-internal/simple ska-sdp-spectral-line-imaging

RUN python3.11 -m pip install flask flask_executor flask_shell2http
COPY cmd_executor.py /usr/local/bin/cmd_executor.py
EXPOSE 6999

COPY slurm.conf /etc/slurm/slurm.conf
COPY slurmdbd.conf /etc/slurm/slurmdbd.conf
RUN set -x \
    && chown slurm:slurm /etc/slurm/slurmdbd.conf \
    && chmod 600 /etc/slurm/slurmdbd.conf

RUN groupadd -r --gid=980 restd \
  && useradd -r -g restd --uid=980 restd 


RUN groupadd -r --gid=981 mark \
  && useradd -r -g mark --uid=981 mark

RUN mkdir /job && chmod -R ugo+rwx /job
RUN chmod -R ugo+w /var/spool/slurmd/

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY cluster_slip.py /usr/local/lib/python3.11/site-packages/ska_sdp_piper/piper/executors/distributed_executor.py
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["slurmdbd"]
