#!/bin/bash 

# This script installs some necessary .deb dependencies and then installs binary .whls for the packages
# specified in vendor-requirements.txt into the "vendor" directory. The actual process runs inside a Docker
# container; Docker is the only local prerequisite.

nginx_version="1.23.3"

if [[ ! -d "redis2-nginx-module" ]]; then
  git clone https://github.com/openresty/redis2-nginx-module.git
fi
if [[ ! -d "echo-nginx-module" ]]; then
  git clone https://github.com/openresty/echo-nginx-module.git
fi
if [[ ! -f "nginx-${nginx_version}.tar.gz" ]]; then
  wget "http://nginx.org/download/nginx-${nginx_version}.tar.gz"
fi

# The bind mount here enables us to write back to the host filesystem
docker run \
    --mount type=bind,source="$(pwd)",target=/home/vcap/app \
    --tmpfs /home/vcap/app/src \
    --name cf_bash \
    --rm \
    --pull always \
    --interactive \
    nginx:${nginx_version} /bin/bash \
    -eu \
    <<EOF
apt update
apt install gcc libpcre3-dev zlib1g-dev make libssl-dev -y

# Go where the app files are
cd /home/vcap/app

tar -xzvf nginx-${nginx_version}.tar.gz
cd nginx-${nginx_version}/
./configure --prefix=/ --error-log-path=stderr --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --without-http_uwsgi_module --without-http_scgi_module --with-pcre --with-pcre-jit --with-debug --with-cc-opt='-fPIC -pie' --with-ld-opt='-fPIC -pie -z now' --with-compat --with-stream=dynamic --with-http_sub_module --add-dynamic-module=/home/vcap/app/redis2-nginx-module --add-dynamic-module=/home/vcap/app/echo-nginx-module
make -j2
make install

# copy module back to host
cd ../
mkdir -p proxy/modules
cp /modules/ngx_http_redis2_module.so proxy/modules/ngx_http_redis2_module.so
cp /modules/ngx_http_echo_module.so proxy/modules/ngx_http_echo_module.so

# cleanup
rm -rf nginx-${nginx_version}*
rm -rf redis2-nginx-module
rm -rf echo-nginx-module/

EOF
