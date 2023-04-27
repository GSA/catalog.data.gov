FROM cloudfoundry/cflinuxfs4
# Specify Python version
ARG PY_VERSION=3.8

# Go where the app files are
RUN cd ~vcap/app

# Install any packaged dependencies for our vendored packages
RUN apt-get -y update
RUN apt-get -y install software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get -y install swig build-essential python-dev${PY_VERSION} libssl-dev python${PY_VERSION}-distutils
RUN apt-get -y install python${PY_VERSION}

# Install PIP
RUN curl -sSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
RUN ${PY_VERSION} /tmp/get-pip.py
