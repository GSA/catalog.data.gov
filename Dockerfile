FROM cloudfoundry/cflinuxfs3

# Go where the app files are
RUN cd ~vcap/app

# Install any packaged dependencies for our vendored packages
# Install python3.7 because that's what the buildpak uses
RUN apt-get -y update
# Install procedure for python: https://askubuntu.com/a/1171892
RUN wget https://www.python.org/ftp/python/3.7.12/Python-3.7.12.tgz && \
  tar xzvf Python-3.7.12.tgz && \
  cd Python-3.7.12 && \
  ./configure && \
  make && \
  make install
RUN apt-get -y install swig build-essential python-dev libssl-dev openssl

# Install PIP
RUN curl -sSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
RUN python3.7 /tmp/get-pip.py

