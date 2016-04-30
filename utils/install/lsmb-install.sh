#!/bin/bash


## ############################
## A rough script to install LedgerSMB directly from a git clone
## It should install all dependencies on a debian/mint/ubuntu system as of 2016 01 01
## Be warned this is a work in progress and may break for you
##
## bug reports and patches welcome
##
## ############################

Script_VERSION='0.01a'


###  http://ledgersmb.org/faq#n299 # info on installing 1.4.10.1 on wheezy
cat <<EOF
	    
EOF


if [[ "$USER" == "root" ]]; then
    cat <<-EOF
	=========================================================================
	=========================================================================
	==  ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR  ==
	=========================================================================
	=========================================================================
	==                                                                     ==
	==               You must run this script as a USER                    ==
	== It will ask for your password when it needs to have root privlidges ==
	==                                                                     ==
	=========================================================================
	=========================================================================
	
EOF
    exit 1
fi

declare -a -r MenuKeys_1=({{0..9},{a..z}});
declare -a -r MenuKeys_2=({{0..9},{a..z}}{{0..9},{a..z}});
#i=0; time declare -A -r MenuKeys_1_Lookup=([{{0..9},{a..z}}]='"'$((i++))'"');
#i=0; time declare -A -r MenuKeys_2_Lookup=([{{0..9},{a..z}}{{0..9},{a..z}}]='"'$((i++))'"');
i=0; declare -A MenuKeys_1_Lookup; eval MenuKeys_1_Lookup[{{0..9},{a..z}}]="$((i++))";
i=0; declare -A MenuKeys_2_Lookup; eval MenuKeys_2_Lookup[{{0..9},{a..z}}{{0..9},{a..z}}]="$((i++))";

GetKey() {  # $1=valid key list    $2=Prompt    Result is stored in global $Key
	    # key list requires a single key to be upper case, this is used as the default
	    # User input is case insensitive
	    # prompt can contain and "echo" escape sequences. eg: \n for newline
	    
	# -l arg to declare or local means convert to lowercase on assignment.
    declare -g -l Key=9999;                             # default to invalid key
    local -l validkeys="${1:-yn}"                       # use a default key list of yn
    local prompt="${2:-Press y to continue.}"           # use a sensible default prompt
    local -l defaultKey=${1//[[:lower:]]/};             # Remove all lower case chars from $1 (validkeys)
    defaultKey=${defaultKey:-${validkeys:0:1}};         # Incase there are no Uppercase chars use first char as default
    defaultKey=${defaultKey:0:1};                       # Only use the first upper case char as default
#    defaultKey=${defaultKey,,};                         # change DefaultKey to lowercase
#    validkeys=${validkeys,,};                           # We are case insensitive for our matches so convert to lowercase

    printf "$prompt [${validkeys^^${defaultKey}}] ";    # Prompt with the default key as uppercase
    while ! [[ ${validkeys} =~ ${Key} ]]; do            # loop until we get a valid key or null
        read -sn1 Key;
        #Key=${Key,,}; # force new key to be lowercase
    done
    : ${Key:=${defaultKey}}; 
    printf "\n";
}

GetKey2() {  # $1=valid 1st key list    $2=valid 2nd key list    $3=Prompt    Result is stored in global $Key
	    # key list requires a single key to be upper case, this is used as the default
	    # User input is case insensitive
	    # prompt can contain and "echo" escape sequences. eg: \n for newline
	    
	# -l arg to declare or local means convert to lowercase on assignment.
    declare -g -l Key=9999;                             # default to invalid key
    declare -l Key2=9999;                             # default to invalid key
    local -l validkeys1="${1:-yn}"                       # use a default key list of yn
    local -l validkeys2="${2:-yn}"                       # use a default key list of yn
    local prompt="${3:-Press y to continue.}"           # use a sensible default prompt
    local -l defaultKey1=${1//[[:lower:]]/};             # Remove all lower case chars from $1 (validkeys)
    local -l defaultKey2=${2//[[:lower:]]/};             # Remove all lower case chars from $1 (validkeys)
    defaultKey=${defaultKey:-${validkeys1:0:1}};         # Incase there are no Uppercase chars use first char as default
    defaultKey=${defaultKey:0:1};                       # Only use the first upper case char as default
    defaultKey2=${defaultKey2:-${validkeys2:0:1}};         # Incase there are no Uppercase chars use first char as default
    defaultKey2=${defaultKey2:0:1};                       # Only use the first upper case char as default

    printf "$prompt [${validkeys1^^${defaultKey1}}][${validkeys2^^${defaultKey2}}] ";    # Prompt with the default key as uppercase
    while ! [[ ${validkeys1} =~ ${Key} ]]; do            # loop until we get a valid key or null
        read -sn1 Key;
    done
    while ! [[ ${validkeys2} =~ ${Key2} ]]; do            # loop until we get a valid key or null
        read -sn1 Key2;
    done
    : ${Key:=${defaultKey1}};
    : ${Key2:=${defaultKey2}};
    Key+=${Key2};
    printf "\n";
}

TestKey() {
    local Z=${1:-8888};
    [[ ${Key:-9999} == "${Z,,}" ]];
}

# Packages to remove that are installed automatically by other things
# This gets done as the last process in this script so any other installs have already completed.
declare -a debXenRemoveThese
debXenRemoveThese_DefKeys=yN
debXenRemoveThese+=("laptop-detect");
debXenRemoveThese+=("popularity-contest");
debXenRemoveThese+=("libfuse2");

declare -a debBaseUtils
debBaseUtils_DefKeys=Yn
debBaseUtils+=("make");
debBaseUtils+=("mc");
debBaseUtils+=("htop");
debBaseUtils+=("ssh");
debBaseUtils+=("git");
debBaseUtils+=("ssmtp"); # basic smtp mail forwarder
debBaseUtils+=("avahi-utils"); # we want this so the system is discoverable by hostname using something like lsmb15.local
debBaseUtils+=("apt-transport-https");

declare -a debPostgres
debPostgres_DefKeys=Yn
debPostgres+=("postgresql");
debPostgres+=("postgresql-client");
debPostgres+=("postgresql-contrib");
debPostgres+=("libpgobject-simple-perl");
debPostgres+=("libpgobject-simple-role-perl");
debPostgres+=("libpgobject-util-dbmethod-perl");


###- PGObject::Simple           ...missing.
###- PGObject::Simple::Role     ...missing.
#- PGObject::Type::BigFloat   ...missing.
#- PGObject::Type::DateTime   ...missing.
###- PGObject::Util::DBMethod   ...missing.

#- TeX::Encode                ...missing.

#- App::LedgerSMB::Admin      ...missing. (would need 0.04)
###- Carp::Always               ...missing.
###- XML::Simple                ...missing.


#########################
# perl Makefile.PL
#
#- App::LedgerSMB::Admin      ...missing. (would need 0.04)
#- PGObject::Type::BigFloat   ...missing.
#- PGObject::Type::DateTime   ...missing.
#Auto-install the 3 mandatory module(s) from CPAN? [y]

declare -a debPerl
debPerl_DefKeys=Yn
#fixme#debPerl+=("wkhtml"); # really need a debCore package group
debPerl+=("make");
debPerl+=("cpanminus");
debPerl+=("libmodule-install-perl");
debPerl+=("libdatetime-perl");
debPerl+=("libdbi-perl");
debPerl+=("libdbd-pg-perl");
debPerl+=("libcgi-simple-perl");
debPerl+=("libtemplate-perl");
debPerl+=("libmime-lite-perl");
debPerl+=("liblocale-maketext-lexicon-perl");
debPerl+=("libtest-exception-perl");
debPerl+=("libtest-trap-perl");
debPerl+=("liblog-log4perl-perl");
debPerl+=("libmath-bigint-gmp-perl");
debPerl+=("libfile-mimeinfo-perl");
debPerl+=("libtemplate-plugin-number-format-perl");
debPerl+=("libconfig-general-perl");
debPerl+=("libdatetime-format-strptime-perl");
debPerl+=("libio-stringy-perl");
debPerl+=("libmoose-perl");
debPerl+=("libconfig-inifiles-perl");
debPerl+=("libnamespace-autoclean-perl");
#debPerl+=("libcarp-always-perl");       # only used for debugging
debPerl+=("libjson-perl");
debPerl+=("libpgobject-perl");          #missing from INSTALL.md
debPerl+=("libperl-critic-perl");       #missing from INSTALL.md
debPerl+=("libcarp-always-perl");
debPerl+=("libtex-encode-perl");
debPerl+=("libxml-simple-perl");
#debPerl+=("libtex-encode-perl");
#for i in "${debPerl[@]}"; do echo $i; done;

declare -a debLaTeX
debLaTeX_DefKeys=nY
debLaTeX+=("libtemplate-plugin-latex-perl");
debLaTeX+=("texlive-latex-recommended");
debLaTeX+=("libimage-size-perl");
debLaTeX+=("liblatex-decode-perl");

declare -a debTrustCommerce
debTrustCommerce_DefKeys=yN
debTrustCommerce+=("libnet-tclink-perl");

declare -a debOOO
debOOO_DefKeys=Yn
debOOO+=("libxml-twig-perl");
debOOO+=("libopenoffice-oodoc-perl");

declare -a debStarman
debStarman_DefKeys=Yn
debStarman+=("starman");
debStarman+=("libcgi-emulate-psgi-perl");
debStarman+=("libplack-perl");


declare -a debDocker
debDocker_DefKeys=yN
debDockerRepoAdd='apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D';
debDockerSourcesName='/etc/apt/sources.list.d/docker.list';
debDockerSourcesContent='deb https://apt.dockerproject.org/repo debian-jessie main';
debDocker+=("docker-engine");

declare -a debPrinting
debPrinting_DefKeys=Yn
debPrinting+=("cups-bsd");
debPrinting+=("cups-daemon");

#declare -a deb
#deb_DefKeys=nY
#deb+=("");

Div='==================\n'

char2dec() {
    printf "%d" "'$1"
}

dec2char() {
    printf -v tmp "%o" $1;      # kludge :::: convert decimal to octal first
    printf "\\$tmp";            # print octal as ascii
}
#RUN DEBIAN_FRONTENT=noninteractive;
Install_BaseUtils() {
    if TestPackagesInstalled debBaseUtils; then DefKeys=yN; else DefKeys=$debBaseUtils_DefKeys; fi
    GetKey $DefKeys "\n${Div} Base Utilities\n${Div}${debBaseUtils[*]}\n${Div}Install Base Utilities?"
    if TestKey "y"; then
        sudo apt-get -y install "${debBaseUtils[@]}";
    fi
}

Clone_LSMB_Master() {
    [[ -d ~/"src/LedgerSMB/git/LedgerSMB" ]] && { 
        printf "\n${Div}You already have a copy of LSMB at '~/src/LedgerSMB/git/LedgerSMB'\n${Div}";
        return;
    }
    GetKey Yn "\n${Div} Clone LSMB Master\n${Div}Target Dir = '~/src/LedgerSMB/git'\n${Div}Clone LSMB Master?"
    if TestKey "y"; then
        mkdir -p ~/"src/LedgerSMB/git"
        pushd ~/"src/LedgerSMB/git" >/dev/null
#        git clone https://github.com/ledgersmb/LedgerSMB.git
        git clone https://github.com/sbts/LedgerSMB.git
        popd >/dev/null
    fi
}

Pull_LSMB_Master() {
    GetKey Yn "\n${Div} Pull LSMB Master\n${Div}Target Dir = '~/src/LedgerSMB/git'\n${Div}Pull LSMB Master?"
    if TestKey "y"; then
        pushd ~/"src/LedgerSMB/git/LedgerSMB" >/dev/null
        git pull
        popd >/dev/null
    fi
}

SelectVersion() {
    local -a Versions='master'
    local -a Releases
    local -i Idx=1
    local Keys="0"
    local Keys2
    local tmp

    pushd ~/"src/LedgerSMB/git/LedgerSMB" >/dev/null
    echo -en "\n${Div:0:-2}${Div} Available Versions\n${Div:0:-2}${Div}"
    echo -e "\tKey: Version";
    printf "\t%2s:    %s\n" ${MenuKeys_1[0]} "${Versions[0]} [default]";

    for i in `git tag | sort`; do
        if ! [[ ${i:0:1} =~ [0-9] ]]; then continue; fi
        j="${i/./,}";           # convert the first . to a , so we can strip everything after the second .
        j="${j%%[^0-9,]*}";     # strip any trailing stuff after the minor version
        j="${j/,/.}";           # convert the , back into a .
        if [[ ${Versions[@]} =~ ${j} ]]; then continue; fi # if it already exists in Versions skip it
        Versions+=("$j");
        printf "\t%2s:    %s\n" ${MenuKeys_1[$Idx]} "${Versions[$Idx]}";
        Keys+="${MenuKeys_1[$Idx]}"
        (( Idx++));
    done
    echo -en "${Div:0:-2}${Div}"
    GetKey "$Keys" "Select Version to install"
#    ver="${Keys%%${Key}*}";     # strip all possible keys after and including selected one
#    ver=${#ver};                # the number of keys remaining is the index to the Versions array
    Version=${Versions[${MenuKeys_1_Lookup[$Key]}]};  #

    echo -en "\n${Div:0:-2}${Div} Available Releases\n${Div:0:-2}${Div}"
    Idx=0; Keys=''; Keys2='';
    if ! [[ ${Version} =~ "${Versions[0]}" ]]; then
        for i in `git tag | sort -V`; do
            if ! [[ ${i:0:1} =~ [0-9] ]]; then continue; fi
            if ! [[ ${i} =~ "$Version" ]]; then continue; fi # if it doesn't match the version number skip it
            Releases+=("$i");
            printf "\t%2s:    %s\n" ${MenuKeys_2[$Idx]} "${Releases[$Idx]}";
            tmp="${MenuKeys_2[$Idx]}"
            if ! [[ $Keys =~ ${tmp:0:1} ]]; then Keys+="${tmp:0:1}"; fi
            if ! [[ $Keys2 =~ ${tmp:1:1} ]]; then Keys2+="${tmp:1:1}"; fi
    #        Keys2+="${tmp:1:1}"
            (( Idx++));
    #        echo ":$i"
        done
        echo -en "${Div:0:-2}${Div}"
        GetKey2 "$Keys" "$Keys2" "Select Release to install"
        tmp="$Key";
        Release="${Releases[${MenuKeys_2_Lookup[$Key]}]}"
    fi

    if [[ "$Version" == "${Versions[0]}" ]]; then Release="$Version"; fi
    
    echo "Release='$Release'"
    git checkout -f $TAG
    popd >/dev/null
}

createPostgresSuperUser() {
    echo
    echo "do not use this function [ createPostgresSuperUser() ]"
    echo
    exit 999;
    # First parameter is the user name
    LSMBDBUSER=$1
    # Second parameter is the password
    LSMBDBPW=$2

    su - postgres -c psql <<-EOT
       DO
       \$\$
       DECLARE num_users integer;
       BEGIN
           SELECT count(*)
               into num_users
           FROM pg_user
           WHERE usename = '$LSMBDBUSER';

           IF num_users = 0 THEN
               CREATE ROLE $LSMBDBUSER WITH SUPERUSER LOGIN NOINHERIT ENCRYPTED PASSWORD '$LSMBDBPW';
           ELSE
               ALTER ROLE $LSMBDBUSER WITH SUPERUSER LOGIN NOINHERIT ENCRYPTED PASSWORD '$LSMBDBPW';
           END IF;
       END
       \$\$
       ;
       EOT
}

SetupPostgres() {

    echo -e "${Div}${Div}"
    echo "Configuring Postgres access for user lsmb_dbadmin."
    echo -e "${Div}"
    if (( `find /etc/postgresql -name postgresql.conf | grep -c '$'` == 1 )); then
        echo -e "\tmodifying pg_hba.conf"
        sudo sed -i.bak1 -r '
            /local[[:space:]]*all[[:space:]]*lsmb_dbadmin*/ d
            /local[[:space:]]*all[[:space:]]*all*/ ilocal\tall\t\tlsmb_dbadmin\t\t\t\tmd5
          ' `find /etc/postgresql -name pg_hba.conf`
    else
        echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
        echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
        echo '%%   ERROR ERROR ERROR  ERROR ERROR ERROR   %%';
        echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
        echo '%% can'"'"'t automatically edit pg_hba.conf     %%';
        echo '%% there is either no pg_hba.conf file or   %%';
        echo '%% or                                       %%';
        echo '%% there is more than one pg_hba.conf file  %%';
        echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
        echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
        echo;
        echo 'Please add the following line to pg_hba.conf';
        echo -e "local\tall\t\tlsmb_dbadmin\t\t\t\tmd5";
        echo 'it MUST be added immediately above the line';
        echo -e "local\tall\t\tall\t\t\t\tpeer";
        read -p 'Press ENTER to continue';
    fi
    echo -e "${Div}${Div}"
    echo "Configuring Postgres accessibility."
    #echo -e "${Div}"
    GetKey yN "\n${Div} Enable Postgres Client Connections from other machines?\n${Div}this is only needed if you want to directly connect to the database with management tools on other computer\n${Div}Postgres: Allow remote access?"
    if TestKey "y"; then
        echo -e "${Div}"
        echo -e "\tmodifying postgresql.conf"
        echo -e "${Div}"
        if (( `find /etc/postgresql -name postgresql.conf | grep -c '$'` == 1 )); then
            sudo sed -i.bak "/listen_addresses/ s/'.*'/'*'/" `find /etc/postgresql -name postgresql.conf`;
        else
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%%     ERROR ERROR ERROR  ERROR ERROR ERROR     %%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%% can'"'"'t automatically edit postgresql.conf     %%';
            echo '%% there is either no postgresql.conf file or   %%';
            echo '%% or                                           %%';
            echo '%% there is more than one postgresql.conf file  %%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo;
            echo 'Please edit the following line to postgresql.conf';
            echo -e "listen_addresses 'localhost'";
            echo 'to look like';
            echo -e "listen_addresses '*'";
            read -p 'Press ENTER to continue';
        fi
        export Net='';
        while read IP R; do
            if [[ $IP =~ ^default ]]; then
                Dev=${R##*dev };
            else
                if [[ $R =~ $Dev.*proto ]]; then
                    Net=$IP;
                fi;
            fi;
        done < <( ip route show; )
        if [[ -z $Net ]]; then
            Net='192.168.1.0/24';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%%   ERROR ERROR ERROR  ERROR ERROR ERROR   %%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%% can'"'"'t identify your local network        %%';
            echo '%% using a default network address of       %%';
            echo '%% 192.168.1.0/24                           %%';
            echo '%% please edit pg_hba.conf to correct this  %%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            read -p 'Press ENTER to continue';
        fi
        if (( `find /etc/postgresql -name pg_hba.conf | grep -c '$'` == 1 )); then
            echo -e "\tmodifying pg_hba.conf"
            sudo sed -i.bak2 -r "
                /host[[:space:]]*all[[:space:]]*all[[:space:]]*${Net%/*}/ d
                /host[[:space:]]*all[[:space:]]*all[[:space:]]*127/ ihost\tall\t\tlsmb_dbadmin\t$Net\t\tmd5
              " `find /etc/postgresql -name pg_hba.conf`
        else
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%%   ERROR ERROR ERROR  ERROR ERROR ERROR   %%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%% can'"'"'t automatically edit pg_hba.conf     %%';
            echo '%% there is either no pg_hba.conf file or   %%';
            echo '%% or                                       %%';
            echo '%% there is more than one pg_hba.conf file  %%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo;
            echo 'Please add the following line to pg_hba.conf';
            echo -e "host\tall\t\tlsmb_dbadmin\t$Net\t\tmd5";
            echo 'it MUST be added immediately above the line';
            echo -e "host\tall\t\tall\t127.0.0.1/32\t\tmd5";
            read -p 'Press ENTER to continue';
        fi
    else
        echo -e "${Div}"
        echo -e "\tmodifying postgresql.conf to disable remote connections"
        echo -e "${Div}"
        if (( `find /etc/postgresql -name postgresql.conf | grep -c '$'` == 1 )); then
            sudo sed -i.bak "/listen_addresses/ s/'.*'/'localhost'/" `find /etc/postgresql -name postgresql.conf`;
        else
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%%     ERROR ERROR ERROR  ERROR ERROR ERROR     %%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%% can'"'"'t automatically edit postgresql.conf     %%';
            echo '%% there is either no postgresql.conf file or   %%';
            echo '%% or                                           %%';
            echo '%% there is more than one postgresql.conf file  %%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo;
            echo 'Please edit the following line to postgresql.conf';
            echo -e "listen_addresses '*'";
            echo 'to look like';
            echo -e "listen_addresses 'localhost'";
            read -p 'Press ENTER to continue';
        fi
        export Net='';
        while read IP R; do
            if [[ $IP =~ ^default ]]; then
                Dev=${R##*dev };
            else
                if [[ $R =~ $Dev.*proto ]]; then
                    Net=$IP;
                fi;
            fi;
        done < <( ip route show; )
        if [[ -z $Net ]]; then
            Net='192.168.1.0/24';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%%   ERROR ERROR ERROR  ERROR ERROR ERROR   %%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%% can'"'"'t identify your local network        %%';
            echo '%% using a default network address of       %%';
            echo '%% 192.168.1.0/24                           %%';
            echo '%% please edit pg_hba.conf to correct this  %%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            read -p 'Press ENTER to continue';
        fi
        if (( `find /etc/postgresql -name pg_hba.conf | grep -c '$'` == 1 )); then
            echo -e "\tmodifying pg_hba.conf to disable remote connections"
            sudo sed -i.bak2 -r "/host[[:space:]]*all[[:space:]]*lsmb_dbadmin[[:space:]]*${Net%/*}/ d" `find /etc/postgresql -name pg_hba.conf`
        else
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%%   ERROR ERROR ERROR  ERROR ERROR ERROR   %%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%% can'"'"'t automatically edit pg_hba.conf     %%';
            echo '%% there is either no pg_hba.conf file or   %%';
            echo '%% or                                       %%';
            echo '%% there is more than one pg_hba.conf file  %%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
            echo;
            echo 'Please add the following line to pg_hba.conf';
            echo -e "host\tall\t\tlsmb_dbadmin\t$Net\t\tmd5";
            echo 'it MUST be added immediately above the line';
            echo -e "host\tall\t\tall\t127.0.0.1/32\t\tmd5";
            read -p 'Press ENTER to continue';
        fi
    fi
    if (( `find /etc/postgresql -name pg_hba.conf | grep -c '$'` == 1 )); then
        echo -e "${Div}${Div}Your pg_hba.conf file contains these entries"
        echo -e "Please check that they are correct\n${Div}"
        sudo egrep -v '^[[:space:]]*#|^$' `find /etc/postgresql -name pg_hba.conf`
        echo -e "${Div}\n"
    fi
    echo -e "${Div}${Div}"
    echo "adding posgres database admin user 'lsmb_dbadmin'"
    echo -e "${Div}"
    #echo "Please enter new password for user 'lsmb_dbadmin'"
    if [[ `sudo -u postgres psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='lsmb_dbadmin'"` == 1 ]]; then
        echo "Database Admin User 'lsmb_dbadmin' already exists...."
        GetKey yN "Do you want to replace it?"
        if TestKey "y"; then
            sudo -u postgres dropuser lsmb_dbadmin 
        fi
    fi
    if ! [[ `sudo -u postgres psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='lsmb_dbadmin'"` == 1 ]]; then
        sudo -u postgres createuser --pwprompt --createdb --login --createrole --superuser lsmb_dbadmin
    fi

        ## test that you can login OK with
    echo -e "\n${Div}"
    echo -e "\tTesting that you can now log in to the database."
    echo -e "${Div}"
        psql -l --password -U lsmb_dbadmin -d postgres -h localhost
        #sudo su -c "psql -l --password -U lsmb_dbadmin -d postgres -h localhost" postgres
    cat <<-"EOF"
    it should have returned something like
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges  
-----------+----------+----------+-------------+-------------+-----------------------
 postgres  | postgres | UTF8     | en_AU.UTF-8 | en_AU.UTF-8 |
 template0 | postgres | UTF8     | en_AU.UTF-8 | en_AU.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_AU.UTF-8 | en_AU.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(3 rows)
EOF
    echo -e "${Div}"
    echo -e "${Div}"
    read -sn1 -p 'Press any key to Continue'; echo

    echo "retrieving roles information for user lsmb_dbadmin"
    psql -U lsmb_dbadmin -d postgres -h localhost -c '\du lsmb_dbadmin;'
    read -sn1 -p 'Press any key to Continue'; echo

}

debInstallPackages() {

    if TestPackagesInstalled debPerl; then DefKeys=yN; else DefKeys=$debPerl_DefKeys; fi
    GetKey $DefKeys "\n${Div} Perl Packages\n${Div}${debPerl[*]}\n${Div}Install Perl?"
    if TestKey "y"; then
        sudo apt-get -y install "${debPerl[@]}";
    fi

    if TestPackagesInstalled debPostgres; then DefKeys=yN; else DefKeys=$debPostgres_DefKeys; fi
    GetKey $DefKeys "\n${Div} Postgres Packages\n${Div}${debPostgres[*]}\n${Div}Install Postgres?"
    if TestKey "y"; then
        sudo apt-get -y install "${debPostgres[@]}";
        SetupPostgres;
    fi

    if TestPackagesInstalled debPrinting; then DefKeys=yN; else DefKeys=$debLaTeX_DefKeys; fi
    GetKey $DefKeys "\n${Div} Minimum Cups Client Packages\n${Div}${debPrinting[*]}\n${Div}Install Print Service?"
    if TestKey "y"; then
        sudo apt-get -y install "${debPrinting[@]}";
        echo "You can set a default server by adding....";
        echo "    ServerName printserver.mydomain[:port]";
        echo "to /etc/cups/client.conf";
        echo "otherwise you can specify a server using the -h option to lpr";
    fi

    if TestPackagesInstalled debLaTeX; then DefKeys=yN; else DefKeys=$debLaTeX_DefKeys; fi
    GetKey $DefKeys "\n${Div} LaTeX Packages\n${Div}${debLaTeX[*]}\n${Div}Install LaTeX?"
    if TestKey "y"; then
        sudo apt-get -y install "${debLaTeX[@]}";
    fi

    if TestPackagesInstalled debOOO; then DefKeys=yN; elseDefKeys=$debOOO_DefKeys; fi
    GetKey $DefKeys "\n${Div} Open Office Output Packages\n${Div}${debOOO[*]}\n${Div}Install Open Office Output?"
    if TestKey "y"; then
        sudo apt-get -y install "${debOOO[@]}";
    fi

    if TestPackagesInstalled debStarman; then DefKeys=yN; else DefKeys=$debStarman_DefKeys; fi
    GetKey $DefKeys "\n${Div} Starman Webserver Packages\n${Div}${debStarman[*]}\n${Div}Install Starman?"
    if TestKey "y"; then
        sudo apt-get -y install "${debStarman[@]}";
    fi

    if TestPackagesInstalled debTrustCommerce; then DefKeys=yN; else DefKeys=$debTrustCommerce_DefKeys; fi
    GetKey $DefKeys "\n${Div} TrustCommerce Packages\n${Div}${debTrustCommerce[*]}\n${Div}Install TrustCommerce?"
    if TestKey "y"; then
        sudo apt-get -y install "${debTrustCommerce[@]}";
    fi

cat <<EOF
${Div%\\n}
${Div%\\n}
    See this for info about xelatex and non-ascii unicode chars
    http://ledgersmb.org/faq/localization/im-using-non-ascii-unicode-characters-why-cant-i-generate-pdf-output
EOF
}

WriteHostsEntries() {
    ####echo "# Deprecated function 'WriteHostsEntries()' instead install avahi on all systems that need to be discoverable and use 'hostname.local' urls"
    ####exit
    local Date=`date "+%Y%m%d-%H%M%S"`
    local Domain=`hostname -d`
    local BackupIP=`getent hosts backup.local`; : ${BackupIP:="192.168.1.100"};
    local PosgresIP=`getent hosts postgres.local`; : ${PostgresIP:="127.0.2.1"};
    cat <<-EOF
	${Div%\\n}
	 /etc/hosts Entries
	${Div%\\n}
	$BackupIP
	$PostgresIP
	${Div%\\n}

EOF
    GetKey yN "Add (or replace) hosts entries?"

    read -n -e -i "${BackupIP:-127.0.2.1}" -p 'Enter Backup Machine IP Address: ' BackupIP
    read -n -e -i "${PostgresIP:-127.0.2.2}" -p 'Enter Postgres Database IP Address: ' PostgresIP
    sudo cp /etc/hosts /etc/hosts.${Date}
    awk '!/^# Auto Generated Content Below Here/ { print; } /^# Auto Generated Content Below Here/ { exit; }' /etc/hosts.${Date} | sudo tee /etc/hosts >/dev/null
    cat <<EOF | sudo tee -a /etc/hosts >/dev/null
# Auto Generated Content Below Here # lsmb-install.sh
# These lines may be overwritten if the script is re-run
# It is probably best to not change anything below this point

$BackupIP backup
$PostgresIP postgres

EOF
}
echo


dumpSSMTP() {
    echo "=========================================================="
    echo " SSMTP_ROOT=$SSMTP_ROOT"
    echo " SSMTP_MAILHUB=$SSMTP_MAILHUB"
    echo " SSMTP_HOSTNAME=$SSMTP_HOSTNAME"
    echo " SSMTP_USE_TLS=$SSMTP_USE_TLS"
    echo " SSMTP_USE_STARTTLS=$SSMTP_USE_STARTTLS"
    echo " SSMTP_AUTH_USER=$SSMTP_AUTH_USER"
    echo " SSMTP_AUTH_PASS=$SSMTP_AUTH_PASS"
    echo " SSMTP_FROMLINE_OVERRIDE=$SSMTP_FROMLINE_OVERRIDE"
    echo " SSMTP_AUTH_METHOD=$SSMTP_AUTH_METHOD"
    echo " SSMTP_AUTH_USER=$SSMTP_AUTH_USER"
    echo " SSMTP_AUTH_PASS=$SSMTP_AUTH_PASS"
    echo " SSMTP_FROMLINE_OVERRIDE=$SSMTP_FROMLINE_OVERRIDE"
    echo "=========================================================="
}
cfgSSMTP() {
# Configure outgoing mail to use host, other run time variable defaults
    F() { awk 'BEGIN { FS="="; } /^'${1,,}'=/ { print $2; }' /etc/ssmtp/ssmtp.conf; }

    ## sSMTP
#    export SSMTP_ROOT=`awk 'BEGIN { FS="="; } /^root=/ { print $2; }' /etc/ssmtp/ssmtp.conf`
    export SSMTP_ROOT=`F root`
    export SSMTP_MAILHUB=`F mailhub`
    export SSMTP_HOSTNAME=`F hostname`
    export SSMTP_USE_STARTTLS=`F UseSTARTTLS`
    export SSMTP_AUTH_USER=`F AuthUser`
    export SSMTP_AUTH_PASS=`F AuthPass`
    export SSMTP_FROMLINE_OVERRIDE='yes'
    export SSMTP_AUTH_METHOD=`F AuthMethod`; SSMTP_AUTH_METHOD=''; # cram-md5 is not supported by some major hosting these days, leave it off
dumpSSMTP
    read -ei "${SSMTP_ROOT/%postmaster/}"               -p '      Email address to forward system mail to: ' SSMTP_ROOT
    SSMTP_MAILHUB="${SSMTP_MAILHUB/%mail/}"
    read -ei "${SSMTP_MAILHUB:=mail.${SSMTP_ROOT##*@}}" -p '                              Mailserver Name: ' SSMTP_MAILHUB
    read -ei "${SSMTP_HOSTNAME:=lsmb.example.com}"      -p '    Hostname.Domain [eg:server.ledgersmb.org]: ' SSMTP_HOSTNAME
    read -ei "${SSMTP_USE_TLS:=YES}"                    -p '                                      Use TLS: ' SSMTP_USE_TLS
    read -ei "${SSMTP_USE_STARTTLS:=YES}"               -p '                                 Use STARTTLS: ' SSMTP_USE_STARTTLS
#    read -ei "${SSMTP_AUTH_METHOD}"                     -p 'Password type: [cram-md5 | "" for plain text]: ' SSMTP_AUTH_METHOD
    read -ei "${SSMTP_AUTH_USER:-${SSMTP_ROOT}}"        -p '                      Authentication Username: ' SSMTP_AUTH_USER
    read -ei "${SSMTP_AUTH_PASS}"                       -p '                                     Password: ' SSMTP_AUTH_PASS
    read -ei "${SSMTP_FROMLINE_OVERRIDE:=YES}"          -p '          Allow LedgerSMB to set From address: ' SSMTP_FROMLINE_OVERRIDE
#    read -ei "${}" -p '' 
#https://wiki.archlinux.org/index.php/SSMTP
    sudo chown root:mail /etc/ssmtp/ssmtp.conf
    sudo chmod 640 /etc/ssmtp/ssmtp.conf;
#export POSTGRES_HOST postgres


}

Install_Docker() {
cat <<EOF
${Div}Install Docker on this system?
${Div}before continuing see
    https://docs.docker.com/engine/installation/debian/
and the source for this script.
Test that the apt repository for docker is correctly installed with.
    apt-cache policy docker-engine
    
EOF
    if TestPackagesInstalled debDocker; then DefKeys=yN; else DefKeys=$debDocker_DefKeys; fi
    GetKey $DefKeys "\n${Div}Install Docker?"
    if TestKey "y"; then
        echo -e "${Div}Docker: Installing Repository Key${Div}"
        $debDockerRepoAdd
        echo -e "${Div}Docker: Installing Repository${Div}"
        cat <<-EOF | sudo tee $debDockerSourcesName >/dev/null
		# Repository for Docker Containers Engine
		
		$debDockerSourcesContent
		
EOF
        echo -e "${Div}Docker: Retrieving Package Lists\n${Div}"
        sudo apt-get update
        echo -e "${Div}Docker: Installing Packages\n${Div}${debDocker[@]}\n${Div}"
        sudo apt-get install -y "${debDocker[@]}";
        echo -e "${Div}Starting Docker Service\n${Div}"
        sudo service docker start
        echo -e "${Div}Running Hello World test container\n${Div}"
        sudo docker run hello-world
        echo -e "${Div}$Div"
    fi
}

TestPackagesInstalled() {
    local -n PL=$1
#    (( $(apt-cache pkgnames | egrep -c -x "`for p in "${PL[@]}"; do printf "%s|" "$p"; done`") == ${#PL[@]} ));
    !((
        $(apt-cache pkgnames | \
            egrep -c -x "$(
                for p in "${PL[@]}"; do # seperate patterns with a pipe
                    printf "%s|" "$p";
                 done
            )"
        ) \
        == ${#PL[@]}
    ));
}


# todo fixme
#TestPackagesInstalled debBaseUtils && echo yes || echo no
#exit
#
#cfgSSMTP
#dumpSSMTP
##    echo " =$"
#exit


CPAN_InstallPackages() {
#    if TestPackagesInstalled debBaseUtils; then DefKeys=yN; else DefKeys=$debBaseUtils_DefKeys; fi
    DefKeys=yN;
    GetKey $DefKeys "\n${Div} LedgerSMB Perl Depencencies\n${Div}This will install any perl depenancies from cpan INCLUDING most development and testing dependencies at the moment.\nIF you don't want the dev and testing dependencies you may need to install by hand from the list of packages found in Makefile.PL\n${Div}Install Missing Perl Dependencies using cpanm?"
    if TestKey "y"; then
        cc --version > /dev/null || cat <<-EOF
		${Div}
		${Div}
		    WARNING
		${Div}
		    Installing Dependencies via CPAN may fail as you don't have a C compiler installed.
		${Div}
		${Div}
	EOF

        cpanm --installdeps .
        cat <<-EOF
		${Div}
		${Div}
		    WARNING
		${Div}
		    Check the results from 'cpanm' carefully if any failure is indicated then not all dependencies were installed.
		    In that case you will need to manually run the following from your LedgerSMB install dir
		    cpanm --installdeps .
		    (NOTE: Don't forget the . at the end of the command!)
		    which will show what the actual failed package was and a logfile you can look at for the cause
		${Div}
		${Div}
	EOF
        read -p 'Press Enter to continue'
        echo
        echo
    fi
}

CheckCPAN_Config_Exists() {
    if [[ -z $(find . -path *cpan/prefs) ]]; then
        sudo apt-get install -y cpanminus
        echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
        echo "%% Please run cpan and set it up for use with local lib %%"
        echo "%%   this should be as easy as selecting all defaults   %%"
        echo "%% Then log out and back in again                       %%"
        echo "%% Then re-run this script.                             %%"
        echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

        echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
        echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
        echo "%% Then log out and back in again                       %%"
        echo "%% Then log out and back in again                       %%"
        echo "%% Then log out and back in again                       %%"
        echo "%% Then log out and back in again                       %%"
        echo "%% Then log out and back in again                       %%"
        echo "%% Then log out and back in again                       %%"
        echo "%% Then log out and back in again                       %%"
        echo "%% Then log out and back in again                       %%"
        echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
        echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

        exit 0
    fi
}

oldManualSteps() {
cat <<EOF
${Div%\\n}
${Div%\\n}

WARNING
    as of 6th Jan 2016 there was a bug in master that causes the main ledgersmb page to show as a blank page.
    revert the offending commit with
    git revert 283406c62d5da1b6415f869f12ebdf97836112c3
    this is due to be resolved by middle of jan 2016
/WARNING

copy to install dir with
sudo mkdir -p /opt/lsmb-$Release
sudo chown $USER:$USER /opt/lsmb-$Release
cp -a ~/src/LedgerSMB/git/LedgerSMB/* /opt/lsmb-$Release
cd /opt/lsmb-$Release

useradd -c "LedgerSMB" -e "" -M -r -U ledgersmb
perl tools/dbsetup  perl tools/dbsetup.pl --company $CREATE_DATABASE


echo -e "\n\n\n\n\n\n\n\n\n\n\n";clear;starman -l :80 --preload-app tools/starman.psgi

EOF

}

ManualSteps() {
cat <<EOF
${Div%\\n}
${Div%\\n}

WARNING
    as of 6th Jan 2016 there was a bug in master that causes the main ledgersmb page to show as a blank page.
    revert the offending commit with
    git revert 283406c62d5da1b6415f869f12ebdf97836112c3
    this is due to be resolved by middle of jan 2016
/WARNING


Now start your server with
echo -e "\n\n\n\n\n\n\n\n\n\n\n";clear;starman -l :8080 --preload-app tools/starman.psgi

NOTE: the following links assume that you created a db / company called dev15
      you will need to edit the link to suit your chosen company name
Then browse to http://$HOSTNAME.local:8080/setup.pl
    * enter username "lsmb_dbadmin"
    * enter the postgres admin password you set earlier
    * enter the new db name you want to create
      eg: dev15
    * follow the in browser prompts
    
    * once you have finished in setup.pl browse to http://$HOSTNAME.local:8080/login.pl?company=dev15
EOF

}

CheckCPAN_Config_Exists


GetKey yN "\n${Div} Update Available Package List\n${Div}Run\napt-get update\n${Div}Update Package List?"
if TestKey "y"; then
    sudo apt-get update
fi

Install_BaseUtils

Clone_LSMB_Master

Pull_LSMB_Master

SelectVersion

debInstallPackages

#WriteHostsEntries

CPAN_InstallPackages

ManualSteps

