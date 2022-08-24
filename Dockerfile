FROM cloudfoundry/cflinuxfs3

# Go where the app files are
RUN cd ~vcap/app

# Install any packaged dependencies for our vendored packages
# Install python3.7 because that's what the buildpak uses
RUN apt-get -y update
RUN apt-get -y install swig build-essential libssl-dev
RUN sudo apt-get install libssl-dev openssl && \
  wget https://www.python.org/ftp/python/3.7.13/Python-3.7.13.tgz && \
  tar xzvf Python-3.7.13.tgz && \
  cd Python-3.7.13 && \
  ./configure && \
  make && \
  sudo make install

# Install PIP
RUN curl -sSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
RUN python3.7 /tmp/get-pip.py

