#!/usr/bin/env sh

# to run: call from command line using two arguments:
#
# $> ./batch < start YYYY > < end YYYY >
#
# e.g.,
#
# $> ./batch 2014 2023
#
# NB: using YYYY format for year:
#
# yes: 2023
#  no: 23

# first year is start; second year is end
start=$1
end=$2

# loop through each year, calling ./build for that year
for ((i=$start; i<=$end; i++));
do
    echo "Building year: ${i}"
    ./build.sh ${i}
done
