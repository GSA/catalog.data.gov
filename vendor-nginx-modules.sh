#!/bin/bash 

# This script installs some necessary .deb dependencies and then installs binary .whls for the packages
# specified in vendor-requirements.txt into the "vendor" directory. The actual process runs inside a Docker
# container; Docker is the only local prerequisite.

git clone https://github.com/openresty/redis2-nginx-module.git
git clone https://github.com/openresty/echo-nginx-module.git
wget 'http://nginx.org/download/nginx-1.21.3.tar.gz'

# The bind mount here enables us to write back to the host filesystem
docker run \
    --mount type=bind,source="$(pwd)",target=/home/vcap/app \
    --tmpfs /home/vcap/app/src \
    --name cf_bash \
    --rm \
    --pull always \
    --interactive \
    nginx:1.21.3 /bin/bash \
    -eu \
    <<EOF
apt update
apt install gcc libpcre3-dev zlib1g-dev make libssl-dev -y

# Go where the app files are
cd /home/vcap/app

tar -xzvf nginx-1.21.3.tar.gz
cd nginx-1.21.3/
./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-cc-opt='-g -O2 -fdebug-prefix-map=/data/builder/debuild/nginx-1.21.3/debian/debuild-base/nginx-1.21.3=. -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' --with-ld-opt='-Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie'  --add-dynamic-module=/home/vcap/app/redis2-nginx-module --add-dynamic-module=/home/vcap/app/echo-nginx-module
make -j2
make install

# copy module back to host
cd ../
mkdir -p proxy/
cp /etc/nginx/modules/ngx_http_redis2_module.so proxy/ngx_http_redis2_module.so
cp /etc/nginx/modules/ngx_http_echo_module.so proxy/ngx_http_echo_module.so

# cleanup
rm -rf nginx-1.*
rm -rf redis2-nginx-module
rm -rf redis2-echo-module

EOF
