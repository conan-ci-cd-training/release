#!/bin/bash

# generate debian package
version=$1

rm -rf debian_gen
mkdir -p myapp_${version}/{DEBIAN,var}
mkdir -p myapp_${version}/var/myapp

cat << 'EOL' >> myapp_${version}/DEBIAN/control
Package: App 
Architecture: all
Maintainer: Yann Chaysinh
Priority: optional
Version: <VERSION>
Description: My Simple Debian package to deploy my 
EOL

sed -i "s/<VERSION>/${version}/" myapp_${version}/DEBIAN/control

cp App/bin/App myapp_${version}/var/myapp/

dpkg-deb --build myapp_${version}

dpkg -c myapp_${version}.deb

