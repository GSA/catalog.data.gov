#!/bin/sh

# If it's missing in our app directory, install the version of Saxon that we're
# after.
#
# TODO: Figure out why libsaxon-java's provided saxon.jar isn't working
export saxon_ver=9.9.1-7
if [ ! -f ./saxon.jar ]; then
    curl https://repo1.maven.org/maven2/net/sf/saxon/Saxon-HE/${saxon_ver}/Saxon-HE-${saxon_ver}.jar  > saxon.jar
fi

# Now it can be invoked like so:
#   java -cp ./saxon.jar net.sf.saxon.Transform -s:fgdc-csdgm_sample.xml -xsl:fgdcrse2iso19115-2.xslt -o:iso_sample.xml
# or 
#   java -Djavax.net.ssl.trustStore=./cacerts -jar ./saxon.jar fgdc-csdgm_sample.xml fgdcrse2iso19115-2.xslt 

