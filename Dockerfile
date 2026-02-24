FROM redhat/ubi9

ARG http_proxy
ARG https_proxy
ARG no_proxy

COPY entrypoint.sh /entrypoint.sh
RUN dnf install python3.9 python3-pip -y && \
    dnf clean all
RUN pip3 install pip --upgrade && \
    pip3 install ansible-core
RUN ansible-galaxy collection install awx.awx community.general ansible.posix
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
