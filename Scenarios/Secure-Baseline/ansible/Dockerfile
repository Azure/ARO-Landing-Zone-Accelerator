FROM registry.access.redhat.com/ubi8/ubi as build

RUN \
  rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
  yum install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm && \
  yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    yum -y install \
      bash gcc libffi-devel git gpgme-devel libxml2-devel \
      libxslt-devel curl openssl-devel python3-devel unzip make azure-cli \
      glibc-locale-source glibc-langpack-en

RUN mkdir -p /opt/bin && \
  curl -slL https://storage.googleapis.com/kubernetes-release/release/v1.18.3/bin/linux/amd64/kubectl \
        -o kubectl && install kubectl /opt/bin/

RUN groupadd ansible --g 1000 && useradd -s /bin/bash -g ansible -u 1000 ansible -d /home/ansible

RUN mkdir -p /ansible/virtualenv && chown -R ansible:ansible /ansible

RUN localedef -c -f UTF-8 -i en_US en_US.UTF-8

USER ansible:ansible

WORKDIR /ansible

COPY . /ansible

# # set pathing
ENV PATH=/opt/bin:./virtualenv/bin:$PATH
ENV PYTHONPATH=./virtualenv/lib/python3.8/site-packages/
ENV ANSIBLE_PYTHON_INTERPRETER=./virtualenv/bin/python
# # set kubeconfig and ansible options
ENV KUBECONFIG=/ansible/.kube/config
ENV ANSIBLE_FORCE_COLOR=1
ENV LC_ALL=en_US.UTF-8

RUN make virtualenv
