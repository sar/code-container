#!/bin/sh

cd ../pkgs/

printf "[wget] fetch pkg dependencies: \n"
wget -i ../pkgs/dependencies.txt

printf "[sha256sum] compute hash diff output: \n"
sha256sum *.deb >> sha256sum.tmp
diff sha256sum.tmp sha256sum.txt

set +x;
