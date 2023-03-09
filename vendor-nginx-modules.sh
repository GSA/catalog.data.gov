#!/bin/bash 

# This script installs some necessary .deb dependencies and then installs binary .whls for the packages
# specified in vendor-requirements.txt into the "vendor" directory. The actual process runs inside a Docker
# container; Docker is the only local prerequisite.

# Get the latest version of the cflinuxfs3 image
if [[ "$1" == "build" ]]; then
  docker build -t catalog-vendor .
fi

# The bind mount here enables us to write back to the host filesystem
docker run \
    --mount type=bind,source="$(pwd)",target=/home/vcap/app \
    --tmpfs /home/vcap/app/src \
    --name cf_bash \
    --rm -i catalog-vendor:latest  /bin/bash \
    -eu \
    <<EOF

# Go where the app files are
cd ~vcap/app

# As the VCAP user, cache .whls based on the frozen requirements for vendoring
git clone https://github.com/openresty/redis2-nginx-module.git
wget 'http://nginx.org/download/nginx-1.23.3.tar.gz'
tar -xzvf nginx-1.23.3.tar.gz
cd nginx-1.23.3/
pwd
./configure --prefix=/opt/nginx --add-dynamic-module=/home/vcap/app/redis2-nginx-module
make -j2
make install
cd ../
mkdir proxy/modules
cp /opt/nginx/modules/ngx_http_redis2_module.so proxy/modules/ngx_http_redis2_module.so
rm -rf nginx-1.*
rm -rf redis2-nginx-module

EOF
