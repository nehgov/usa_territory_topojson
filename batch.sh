#!/usr/bin/env sh

for i in {2014..2023};
do
    echo "Building year: ${i}"
    ./build.sh ${i}
done
