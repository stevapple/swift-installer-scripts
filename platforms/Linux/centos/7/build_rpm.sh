# This source file is part of the Swift.org open source project
#
# Copyright (c) 2021 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for Swift project authors

#!/usr/bin/env bash

set -ex

OUTDIR=/output
if [[ ! -d "$OUTDIR" ]]; then
    echo "$OUTDIR does not exist, so no place to copy the artifacts!"
    exit 1
fi

# always make sure we're up to date
yum update -y

# prepare direcoties
mkdir -p $HOME/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Add the spec
cp swift-lang.spec $HOME/rpmbuild/SPECS/
# Add the metadata for this swift version
cp /shared/metadata.inc $HOME/rpmbuild/SPECS/
# Add any patches
cp patches/*.patch $HOME/rpmbuild/SOURCES/

pushd $HOME/rpmbuild/SPECS
# install all the dependencies needed to build Swift from the spec file itself
yum-builddep -y ./swift-lang.spec
# Workaround to support clang-3.5 or a later version
echo -e ". /opt/rh/sclo-git25/enable\n. /opt/rh/llvm-toolset-7/enable\n. /opt/rh/devtoolset-8/enable\n" >> $HOME/.bashrc
sed -i -e 's/\*__block/\*__libc_block/g' /usr/include/unistd.h
# get the sources for Swift as defined in the spec file
spectool -g -R ./swift-lang.spec
# Now we proceed to build Swift. If this is successful, we
# will have two files: a SRPM file which contains the source files
# as well as a regular RPM file that can be installed via `dnf' or `yum'
rpmbuild -ba ./swift-lang.spec 2>&1 | tee /root/build-output.txt
popd

# Include the build log which can be used to determine what went
# wrong if there are no artifacts
cp $HOME/build-output.txt $OUTDIR
cp $HOME/rpmbuild/SRPMS/* $OUTDIR
cp $HOME/rpmbuild/RPMS/`uname -i`/* $OUTDIR