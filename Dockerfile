FROM cloudfoundry/cflinuxfs3

# Go where the app files are
RUN cd ~vcap/app

# Install any packaged dependencies for our vendored packages
# Install python3.7 because that's what the buildpak uses
RUN apt-get -y update --fix-missing
RUN apt-get -y install software-properties-common && \
  add-apt-repository ppa:deadsnakes/ppa
RUN apt-get -y update
RUN apt-get -y install swig build-essential python-dev libssl-dev python3.9 python3.9-distutils
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.9
