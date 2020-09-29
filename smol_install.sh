#!/bin/bash

CHECK_INTERVAL_MINS=10
MAX_FAILS=3
#HOMEBIN=/home/$USER/bin
HOMEBIN=~/bin
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
#   SUDO_MESSAGE="Enter sudo password (install.sh needs to add netcycle.sh to /etc/sudoers so it's allowed to reboot)"
#   sudo -n true 2>/dev/null || echo $SUDO_MESSAGE
#   TMPFILE=$(mktemp /tmp/temporary-file.XXXXXXXX)
#   sudo cat /etc/sudoers | grep -v "#NETCYCLE-AUTO-INSTSALL$" > $TMPFILE
#   echo "$USER ALL=(ALL:ALL) NOPASSWD:~/bin/netcycle #NETCYCLE-AUTO-INSTALL" >> $TMPFILE


#   sudo sh -c "cat $TMPFILE > /etc/sudoers"

# Need to ensure that $TMPFILE is a valid sudoers file. Can use visudo?
# See https://stackoverflow.com/questions/323957/how-do-i-edit-etc-sudoers-from-a-script


#   rm $TMPFILE
}

function create_symlink()
{
    # Create ~/bin if doesn't exist
    [ -d ~/bin ] || ( mkdir ~/bin )
     
    # Copy to ~/bin/netcycle.sh and create link ~/bin/netcycle 
    cp $SCRIPTDIR/netcycle.sh ~/bin/netcycle.sh 
    ln -fs ~/bin/netcycle.sh ~/bin/netcycle
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
*/$CHECK_INTERVAL_MINS * * * * ~/bin/ip53 | sed "s/^/\$(date): /" >> $NETCYCLEDIR/netcycle.log 2>&1 #NETCYCLE-AUTO-INSTALL
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
