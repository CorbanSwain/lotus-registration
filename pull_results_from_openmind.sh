#!/bin/bash

declare -a arr=(
"bead/20170915/registration"
"bead/20171011/registration"
"bead/20180109/registration"
"fish/20171202/interpolate"
"fish/20171221/interpolate"
"worm/20170720/interpolate"
"worm/20171012/interpolate"
"worm/20171114/registration"
"worm/20171117/registration"
"worm/20171215/interpolate"
"worm/20180103/registration"
)

LPATH=/Users/justin/Desktop/DLFM
RPATH=jkinney@openmind.mit.edu:/om/user/jkinney/DLFM

for i in "${arr[@]}"; do
    echo "##"
    echo "## $i"
    echo "##"

    # split string at '/'
    DEST=$LPATH
    IFS='/' read -ra ADDR <<< "$i"
    for j in "${ADDR[@]}"; do
        DEST="$DEST/$j"
        # check if folders exist
        if [ ! -d "$DEST" ]; then
            echo ""
            echo $DEST
            echo 'Folder does not exist. Creating now.'
            mkdir $DEST
        fi
    done

    # pull results from openmind
    echo ""
    rsync -av --delete --exclude '*.mat' --exclude '*.tif' $RPATH/$i/ $LPATH/$i/
    echo ""
    echo ""
done


