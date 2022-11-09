FROM cloudfoundry/cflinuxfs3

# Go where the app files are
RUN cd ~vcap/app

# Install any packaged dependencies for our vendored packages
RUN apt-get -y update
RUN apt-get -y install software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get -y install swig build-essential python-dev libssl-dev python3.8-distutils
RUN apt-get -y install python3.8

# Install PIP
RUN curl -sSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
RUN python3.9 /tmp/get-pip.py
