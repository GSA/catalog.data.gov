
# to create (just once) random org and datasets
if [ -z $RNDCODE ]; then
    export RNDCODE=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
fi
