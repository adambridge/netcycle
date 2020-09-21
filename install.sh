#!/bin/bash

CHECK_INTERVAL_MINS=10
MAX_FAILS=3
USERHOME=/home/$USER
HOMEBIN=/home/$USER/bin
NETCYCLEDIR=/home/$USER/.netcycle

# Get directory that the install.sh and netcycle.sh are in
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function check_user()
{
    ROOT_MESSAGE="install.sh should not be run as root, run as the user whose crontab and home dir netcycle should be installed to."
    [ `whoami` != root ] || { echo $ROOT_MESSAGE && exit 1; }
}

function add_to_sudoers()
{
    SUDO_MESSAGE="Enter sudo password (install.sh needs to add netcycle.sh to /etc/sudoers so it's allowed to reboot)"
    sudo -n true 2>/dev/null || echo $SUDO_MESSAGE
    TMPFILE=$(mktemp /tmp/temporary-file.XXXXXXXX)
    sudo cat /etc/sudoers | grep -v "#NETCYCLE-AUTO-INSTSALL$" > $TMPFILE
    echo "$USER ALL=(ALL:ALL) NOPASSWD:$HOMEBIN/netcycle #NETCYCLE-AUTO-INSTALL" >> $TMPFILE
    sudo sh -c "cat $TMPFILE > /etc/sudoers"
    rm $TMPFILE
}

function create_symlink()
{
    # Create ~/bin if doesn't exist
    [ -d $HOMEBIN ] || ( mkdir $HOMEBIN )
     
    # Create link in ~/bin pointing to netcycle.sh 
    LNK=$(echo $HOMEBIN/netcycle)
    [ -e $LNK ] || ln -s $SCRIPTDIR/netcycle.sh $LNK
}

function add_config()
{
    # Create $NETCYCLEDIR if doesn't exist
    [ -d $NETCYCLEDIR ] || mkdir $NETCYCLEDIR
    
    # Create ~/.netcycle/fail_count and ~/.netcycle/max_fails
    [ -e $NETCYCLEDIR/max_fails ] || echo $MAX_FAILS > $NETCYCLEDIR/max_fails
    [ -e $NETCYCLEDIR/fail_count ] || echo 0 > $NETCYCLEDIR/fail_count
}

function add_to_crontab()
{
    TMPFILE=$(mktemp /tmp/temporary-file.XXXXXXXX)
    crontab -l | grep -v '#NETCYCLE-AUTO-INSTALL$' > $TMPFILE

    cat <<EOF >> $TMPFILE
*/$CHECK_INTERVAL_MINS * * * * bash -x $LNK >> $NETCYCLEDIR/netcycle.log 2>&1 #NETCYCLE-AUTO-INSTALL
EOF

    crontab $TMPFILE
    rm $TMPFILE
}

check_user
add_to_sudoers
create_symlink
add_config
add_to_crontab

exit 0 
