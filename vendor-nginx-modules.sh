#!/bin/bash 

# This script installs some necessary .deb dependencies and then installs binary .whls for the packages
# specified in vendor-requirements.txt into the "vendor" directory. The actual process runs inside a Docker
# container; Docker is the only local prerequisite.

git clone https://github.com/openresty/redis2-nginx-module.git
wget 'http://nginx.org/download/nginx-1.23.3.tar.gz'

# The bind mount here enables us to write back to the host filesystem
docker run \
    --mount type=bind,source="$(pwd)",target=/home/vcap/app \
    --tmpfs /home/vcap/app/src \
    --name cf_bash \
    --rm \
    --pull always \
    --interactive \
    nginx:1.23.3 /bin/bash \
    -eu \
    <<EOF

# Go where the app files are
cd /home/vcap/app

tar -xzvf nginx-1.23.3.tar.gz
cd nginx-1.23.3/
./configure --prefix=/opt/nginx --add-dynamic-module=/home/vcap/app/redis2-nginx-module
make -j2
make install

# copy module back to host
cd ../
mkdir proxy/modules
cp /opt/nginx/modules/ngx_http_redis2_module.so proxy/modules/ngx_http_redis2_module.so

# cleanup
rm -rf nginx-1.*
rm -rf redis2-nginx-module

EOF
