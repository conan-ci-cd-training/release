#!/bin/bash

# generate debian package
version=$1
name=$2

rm -rf debian_gen
mkdir -p ${name}_${version}/{DEBIAN,var}
mkdir -p ${name}_${version}/var/${name}

cat << 'EOL' >> ${name}_${version}/DEBIAN/control
Package: <NAME> 
Architecture: all
Maintainer: Yann Chaysinh
Priority: optional
Version: <VERSION>
Description: My Simple Debian package to deploy my 
EOL

sed -i "s/<VERSION>/${version}/" ${name}_${version}/DEBIAN/control
sed -i "s/<NAME>/${name}/" ${name}_${version}/DEBIAN/control

cp ${name}/bin/${name} ${name}_${version}/var/${name}/

dpkg-deb --build ${name}_${version}

dpkg -c ${name}_${version}.deb

