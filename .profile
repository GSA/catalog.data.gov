#!/bin/sh

export JAVA_HOME=/home/vcap/deps/0/apt/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$PATH:$JAVA_HOME/bin

# Setup saxon jar file on classpath
export CLASSPATH=$CLASSPATH:/home/vcap/deps/0/apt/usr/share/java/Saxon-HE.jar

# Copy our provided JKS cacerts to the expected location 
#
# TODO: Generate this file on the fly the way that ca-certificates-java package
#       does in the postinst script. We can make use of
#       ../deps/0/apt/usr/sbin/update-ca-certificates if needed, but it will require
#       wrangling env vars to point to the non-root locations that it expects to find.
if [ ! -f ../deps/0/apt/etc/ssl/certs/java/cacerts ]; then
    mkdir -p ../deps/0/apt/etc/ssl/certs/java
    cp ./config/cacerts ../deps/0/apt/etc/ssl/certs/java/cacerts
fi

# echo BEFORE:
# find /home/vcap/deps/0 -xtype l | wc -l
# find /home/vcap/deps/0 -xtype l

# Find any broken links pointing to /etc and point them to /home/vcap/deps/0/apt/etc instead
find /home/vcap/deps/0 -xtype l -exec bash -c 'target="$(readlink "{}")"; link="{}"; target="$(echo "$target" | sed "s+^/etc+/home/vcap/deps/0/apt/etc+")"; ln -Tfs "$target" "$link"' \;

# echo AFTER:
# find /home/vcap/deps/0 -xtype l | wc -l
# find /home/vcap/deps/0 -xtype l

# Test java + saxon installation with test transform:
# java net.sf.saxon.Transform fgdc-csdgm_sample.xml fgdcrse2iso19115-2.xslt
