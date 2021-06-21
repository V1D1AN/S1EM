#!/bin/bash

err_msg () { printf '\033[0;31m[ ERROR ]\033[0m' && echo -e "\t"$(date)"\t"$BASH_SOURCE"\t"$1; }
warn_msg () { printf '\033[1;33m[ WARN ]\033[0m' && echo -e "\t"$(date)"\t"$BASH_SOURCE"\t"$1; }
info_msg () { printf '\033[0;36m[ INFO ]\033[0m' && echo -e "\t"$(date)"\t"$BASH_SOURCE"\t"$1; }

info_msg "An Arkime Admin is being created...";

# SET DEFAULT CREDS IF NONE PASSED ##
#
if [ -z $ARKIME_USER ]; then ARKIME_USER="root"; fi;
if [ -z $ARKIME_PSWD ]; then ARKIME_PSWD="arkime_password"; fi;

## CREATE ADMIN USER ##
#
$ARKIME_DIR/bin/moloch_add_user.sh --insecure $ARKIME_USER "Arkime Admin" $ARKIME_PSWD --admin | tee -a /arkime/log/$(hostname).log > /dev/null;

info_msg "Admin User was created:\t"$ARKIME_USER;

#'lost'21jn
