FROM cloudfoundry/cflinuxfs3

# Go where the app files are
RUN cd ~vcap/app

# Install any packaged dependencies for our vendored packages
# Install python3.7 because that's what the buildpak uses
RUN apt-get -y update
RUN apt-get -y install swig build-essential python-dev libssl-dev python3

# Install PIP
RUN curl -sSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
RUN python3 /tmp/get-pip.py

