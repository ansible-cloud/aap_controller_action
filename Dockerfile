FROM redhat/ubi9
COPY entrypoint.sh /entrypoint.sh
RUN dnf install python3.9 -y
RUN dnf install python3-pip -y
RUN pip3 install pip --upgrade
RUN pip3 install ansible-core
RUN ansible-galaxy collection install awx.awx
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
