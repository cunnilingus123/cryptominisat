#!/bin/bash

# Copyright (C) 2014  Mate Soos
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; version 2
# of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.

# This file wraps CMake invocation for TravisCI
# so we can set different configurations via environment variables.

set -e
set -x

#license check -- first print and then fail in case of problems
./utils/licensecheck/licensecheck.pl -m  ./src
NUM=`./utils/licensecheck/licensecheck.pl -m  ./src | grep UNK | wc -l`
if [ "$NUM" != "0" ]; then
    echo "There are some files without license information!"
    exit -1
fi

NUM=`./utils/licensecheck/licensecheck.pl -m  ./tests | grep UNK | wc -l`
if [ "$NUM" != "0" ]; then
    echo "There are some files without license information!"
    exit -1
fi

set -x

SOURCE_DIR=$(pwd)
cd build
BUILD_DIR=$(pwd)


# Note eval is needed so COMMON_CMAKE_ARGS is expanded properly
case $CMS_CONFIG in
    SLOW_DEBUG)
        sudo apt-get install libboost-program-options-dev
        eval cmake -DENABLE_TESTING:BOOL=ON \
                   -DSLOW_DEBUG:BOOL=ON \
                   "${SOURCE_DIR}"
    ;;

    NORMAL)
        sudo apt-get install libboost-program-options-dev
        eval cmake -DENABLE_TESTING:BOOL=ON \
                   "${SOURCE_DIR}"
    ;;

    LARGEMEM)
        sudo apt-get install libboost-program-options-dev
        eval cmake -DENABLE_TESTING:BOOL=ON \
                   -DLARGEMEM:BOOL=ON \
                   "${SOURCE_DIR}"
    ;;

    LARGEMEM_GAUSS)
        sudo apt-get install libboost-program-options-dev
        eval cmake -DENABLE_TESTING:BOOL=ON \
                   -DLARGEMEM:BOOL=ON \
                   -DUSE_GAUSS=ON \
                   "${SOURCE_DIR}"
    ;;

    COVERAGE)
        sudo apt-get install libboost-program-options-dev
        eval cmake -DENABLE_TESTING:BOOL=ON \
                   -DCOVERAGE:BOOL=ON \
                   "${SOURCE_DIR}"
    ;;

    STATIC)
        sudo apt-get install libboost-program-options-dev
        eval cmake -DENABLE_TESTING:BOOL=ON \
                   -DSTATICCOMPILE:BOOL=ON \
                   "${SOURCE_DIR}"
    ;;

    ONLY_SIMPLE)
        eval cmake -DENABLE_TESTING:BOOL=ON \
                   -DONLY_SIMPLE:BOOL=ON \
                   "${SOURCE_DIR}"
    ;;

    ONLY_SIMPLE_STATIC)
        eval cmake -DENABLE_TESTING:BOOL=ON \
                   -DONLY_SIMPLE:BOOL=ON \
                   -DSTATICCOMPILE:BOOL=ON \
                   "${SOURCE_DIR}"
    ;;

    STATS)
        sudo apt-get install libboost-program-options-dev
        eval cmake -DENABLE_TESTING:BOOL=ON \
                   -DSTATS:BOOL=ON \
                   "${SOURCE_DIR}"
    ;;

    NOZLIB)
        sudo apt-get install libboost-program-options-dev
        eval cmake -DENABLE_TESTING:BOOL=ON \
                   -DNOZLIB:BOOL=ON \
                   "${SOURCE_DIR}"
    ;;

    RELEASE)
        sudo apt-get install libboost-program-options-dev
        eval cmake -DENABLE_TESTING:BOOL=ON \
                   -DCMAKE_BUILD_TYPE:STRING=Release \
                   "${SOURCE_DIR}"
    ;;

    NOSQLITE)
        sudo apt-get install libboost-program-options-dev
        sudo apt-get remove libsqlite3-dev
        eval cmake -DENABLE_TESTING:BOOL=ON \
                   "${SOURCE_DIR}"
    ;;


    NOPYTHON)
        sudo apt-get install libboost-program-options-dev
        sudo apt-get remove python2.7-dev python-dev
        eval cmake -DENABLE_TESTING:BOOL=ON \
                   "${SOURCE_DIR}"
    ;;

    INTREE_BUILD)
        cd ..
        SOURCE_DIR=$(pwd)
        BUILD_DIR=$(pwd)
        sudo apt-get install libboost-program-options-dev
        eval cmake -DENABLE_TESTING:BOOL=ON \
                   "${SOURCE_DIR}"
    ;;

    WEB)
        sudo apt-get install libboost-program-options-dev

        cd "$SOURCE_DIR"
        #./cmsat_mysql_setup.sh
        cd "$BUILD_DIR"

        eval cmake -DENABLE_TESTING:BOOL=ON \
                   -DSTATS:BOOL=ON \
                   "${SOURCE_DIR}"
    ;;

    SQLITE)
        sudo apt-get install libboost-program-options-dev
        sudo apt-get install libsqlite3-dev

        eval cmake -DENABLE_TESTING:BOOL=ON \
                   -DSTATS:BOOL=ON \
                   "${SOURCE_DIR}"
    ;;

    NOTEST)
        sudo apt-get install libboost-program-options-dev
        eval cmake "${SOURCE_DIR}"
    ;;

    GAUSS)
        sudo apt-get install libboost-program-options-dev
        sudo apt-get install libsqlite3-dev

        eval cmake -DENABLE_TESTING:BOOL=ON \
                   -DUSE_GAUSS=ON \
                   "${SOURCE_DIR}"
    ;;

    M4RI)
        sudo apt-get install libboost-program-options-dev
        wget https://bitbucket.org/malb/m4ri/downloads/m4ri-20140914.tar.gz
        tar xzvf m4ri-20140914.tar.gz
        cd m4ri-20140914/
        ./configure
        make
        sudo make install
        cd ..

        eval cmake -DENABLE_TESTING:BOOL=ON \
            "${SOURCE_DIR}"
    ;;

    *)
        echo "\"${STP_CONFIG}\" configuration not recognised"
        exit 1
    ;;
esac

make

if [ "$CMS_CONFIG" == "NOTEST" ]; then
    sudo make install
    exit 0
fi

echo `ldd ./cryptominisat5_simple`
if [ "$CMS_CONFIG" = "ONLY_SIMPLE_STATIC" ] || [ "$CMS_CONFIG" = "STATIC_BIN" ] ; then
     ldd ./cryptominisat5_simple  | grep "not a dynamic"
fi

echo `ldd ./cryptominisat5`
if [ "$CMS_CONFIG" = "STATIC_BIN" ] ; then
     ldd ./cryptominisat5  | grep "not a dynamic"
fi

ctest -V
sudo make install

case $CMS_CONFIG in
    WEB)
        echo "1 2 0" | ./cryptominisat5 --sql 1 --zero-exit-status
    ;;

    SQLITE)
        echo "1 2 0" | ./cryptominisat5 --sql 2 --zero-exit-status
    ;;

    M4RI)
        echo "1 2 0" | ./cryptominisat5 --xor 1 --zero-exit-status
    ;;

    *)
        echo "\"${STP_CONFIG}\" Binary no extra testing (sql, xor, etc), skipping this part"
    ;;
esac

# elimination checks
# NOTE: minisat doesn't build with clang
if [ "$CMS_CONFIG" == "NORMAL" ] && [ "$CXX" != "clang++" ] ; then
    CMS_PATH="${BUILD_DIR}/cryptominisat5"
    cd ../tests/simp-checks/
    git clone --depth 1 https://github.com/msoos/testfiles.git

    echo "Cloning and making minisat..."
    git clone https://github.com/msoos/minisat.git
    cd minisat
    git checkout remotes/origin/only_elim_and_subsume
    git checkout -b only_elim_and_subsume
    make
    cd ..
    ./check_bve.py "$CMS_PATH" testfiles/*

    # building STP
    cd "${BUILD_DIR}"
    # minisat
    git clone --depth 1 https://github.com/niklasso/minisat.git
    cd minisat
    mkdir -p build
    cd build
    cmake ..
    make -j2
    sudo make install
    cd "${BUILD_DIR}"

    # STP
    git clone --depth 1 https://github.com/stp/stp.git
    cd stp
    mkdir -p build
    cd build
    cmake ..
    make -j2
    sudo make install
    cd "${BUILD_DIR}"
fi


#do fuzz testing
if [ "$CMS_CONFIG" != "ONLY_SIMPLE" ] && [ "$CMS_CONFIG" != "ONLY_SIMPLE_STATIC" ] && [ "$CMS_CONFIG" != "WEB" ] && [ "$CMS_CONFIG" != "NOPYTHON" ] && [ "$CMS_CONFIG" != "COVERAGE" ] && [ "$CMS_CONFIG" != "INTREE_BUILD" ] && [ "$CMS_CONFIG" != "STATS" ] && [ "$CMS_CONFIG" != "SQLITE" ] ; then
    cd ../scripts/fuzz/
    ./fuzz_test.py --novalgrind --small --fuzzlim 30
fi

cd ..
pwd
#we are now in the main dir, ./src dir is here

case $CMS_CONFIG in
    WEB)
        cd web
        sudo apt-get install python-software-properties
        sudo add-apt-repository -y ppa:chris-lea/node.js
        sudo apt-get update
        sudo apt-get install -y nodejs
        ./install_web.sh
    ;;

    *)
        echo "\"${STP_CONFIG}\" No further testing"
    ;;
esac

if [ "$CMS_CONFIG" = "COVERAGE" ]; then
  # capture coverage info
  lcov --directory build/cmsat5-src/CMakeFiles/libcryptominisat5.dir --capture --output-file coverage.info

  # filter out system and test code
  lcov --remove coverage.info 'tests/*' '/usr/*' --output-file coverage.info

  # debug before upload
  lcov --list coverage.info

  # only attempt upload if $COVERTOKEN is set
  if [ -n "$COVERTOKEN" ]; then
    coveralls-lcov --repo-token "$COVERTOKEN" coverage.info # uploads to coveralls
  fi
fi
