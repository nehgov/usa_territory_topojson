#!/usr/bin/env sh
#################################################################################
#
# [ PROJ ] Spatial
# [ FILE ] batch
# [ AUTH ] Benjamin Skinner; bskinner@neh.gov
# [ INIT ] 22 November 2024
#
################################################################################

usage()
{
    cat <<EOF

 PURPOSE:
 This script batch builds topojson files from US Census shapefiles.

 USAGE:
 $0 <arguments>

 ARGUMENTS:
    [-s]       Survey year start
    [-e]       Survey year end (if blank, assumed same as start)
    [-r]       Resolution: 500k, 5m, 20m

 EXAMPLE:

 ./batch -s 2021 -r 5m
 ./build -s 2020 -e 2021 -r 500k

EOF
}

s_flag=0
e_flag=0
r_flag=0

while getopts "hs:e:r:" opt;
do
    case $opt in
    h)
        usage
        exit 1
        ;;
    s)
        start=$OPTARG
        s_flag=1
        ;;
    e)
        end=$OPTARG
        e_flag=1
        ;;
    r)
        set -f
        IFS=,
        res=($OPTARG)
        r_flag=1
        ;;
    \?)
        usage
        exit 1
        ;;
    esac
done

# check for missing arguments
if (( $s_flag==0 )) || (( $r_flag==0 )); then
    echo "Missing one or more arguments"
    usage
    exit 1
fi

if (( $e_flag==0 )); then
    end=start
fi

# --- loop ---------------------------------------

for ((i=$start; i<=$end; i++));
do
    for j in "${res[@]}";
    do
        echo "Building year: ${i} at ${j} resolution"
        ./build.sh -y ${i} -r ${j}
    done
done

# ------------------------------------------------------------------------------
# end batch
################################################################################
