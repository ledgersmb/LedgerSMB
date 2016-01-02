#!/bin/bash

############
##
## A script to assist with Releasing LedgerSMB
##      Copyright (c) 20015 SB Tech Services info@sbts.com.au
##
## Exclusively Licensed for use in the LedgerSMB Project
## Use in whole or part outside of the LedgerSMB Project is Not Permitted
##
## This script Updates the Topic for irc #ledgersmb
##
## It requires 2 or 3 commandline arguments and a config file.
##
##      $1 = Type of Release:  stable | preview | both
##      $2 = New version number:  if $1=stable or both then $2 is stable version number;  if $1=preview then $2 is preview version number
##      $3 = New version number for preview IF $1 = both
##
##
## Two override arguments can be supplied (as the first 2 arguments) 
##   they are removed from the arg list before normal argument processing.
##
##      --aq true|false    # override AutoQuit config setting
##      --at true|false    # override auto_TOPIC_change config setting
##   These are intended mainly for testing rather than normal use.
##
############

ConfigFile=~/.lsmb-release

libFile=` readlink -f ./bash-functions.sh`
[[ -f $libFile ]] && { [[ -r $libFile ]] && source $libFile; } || {
    printf "\n\n\n";
    printf "=====================================================================\n";
    printf "=====================================================================\n";
    printf "====  Essential Library not readable:                            ====\n";
    printf "====        %-51s  ====\n" $libFile;
    printf "=====================================================================\n";
    printf "=====================================================================\n";
    printf "Exiting Now....\n\n\n";
    exit 1;
}

REQUIRE_bin "envsubst"

i=0;
while (( i++ < 30 )); do # check for --aq + --at. do it in a loop so order doesn't matter. break the loop at first non matching argument.
    if [[ $1 == '--aq' ]]; then
        if [[ $2 == 'true' ]] || [[ $2 == 'false' ]]; then
            AutoQuitOverride=$2;
            shift;
        else
            break;
        fi
        shift;
    elif [[ $1 == '--at' ]]; then
        if [[ $2 == 'true' ]] || [[ $2 == 'false' ]]; then
            AutoTopicOverride=$2;
            shift;
        else
            break;
        fi
        shift;
    else
        break;
    fi
done

############
#  Test Config to make sure we have everything we need
############
    while true; do
        TestConfigInit;
        TestConfig4Key 'irc' 'Server'             'chat.freenode.net'
        TestConfig4Key 'irc' 'Port'               '6667'
        TestConfig4Key 'irc' 'User'               'Your_IRC_Username'
        TestConfig4Key 'irc' 'Nick'               'YourNick'
        TestConfig4Key 'irc' 'Password'           'Password'
        TestConfig4Key 'irc' 'Channel'            '#ledgersmb'
        TestConfig4Key 'irc' 'auto_TOPIC_change'  'true'
        TestConfig4Key 'irc' 'TOPIC_template'     'http://www.ledgersmb.org/ | LedgerSMB Development and discussion | latest stable: $Version_Stable | latest preview: $Version_Preview'
        TestConfig4Key 'irc' 'TOPIC_suffix'       '| http://ledgersmb.org/news/fundraising-multi-currency-after-thought-core-feature'
        TestConfig4Key 'irc' 'TOPIC_regex_stable'  ''
        TestConfig4Key 'irc' 'TOPIC_regex_preview' ''
        TestConfig4Key 'irc' 'QuitMessage'        'Our Work Here is Done'
        TestConfig4Key 'irc' 'ChanServ'           ':ChanServ!ChanServ@services.'
        TestConfig4Key 'irc' 'NickServ'           ':NickServ!NickServ@services.'
        TestConfig4Key 'irc' 'Log'                '/tmp/irc.log'
        TestConfig4Key 'irc' 'LogOverwrite'       'true'
        TestConfig4Key 'irc' 'AutoQuit'           'true'
        TestConfig4Key 'irc' 'ReadlineHistory'    '/tmp/irc.history'
        if TestConfigAsk "IRC Topic Update"; then break; fi
    done

#Server='orwell.freenode.net'
#Server='kornbluth.freenode.net'
             Server="${cfgValue[irc_Server]}";
               Port="${cfgValue[irc_Port]}";
               Name="${cfgValue[irc_User]}";
               Nick="${cfgValue[irc_Nick]}";
######  ConnectPass="${cfgValue[irc_Password]}"; # don't set this, we use ${cfgValue[irc_Password]} directly and overwrite it after loggin in
            Channel="${cfgValue[irc_Channel]}";
  auto_TOPIC_change="${cfgValue[irc_auto_TOPIC_change]}";
     TOPIC_template="${cfgValue[irc_TOPIC_template]} ${cfgValue[irc_TOPIC_suffix]}";
 TOPIC_regex_stable="${cfgValue[irc_TOPIC_regex_stable]}";
TOPIC_regex_preview="${cfgValue[irc_TOPIC_regex_preview]}";
        QuitMessage="${cfgValue[irc_QuitMessage]}";
           ChanServ="${cfgValue[irc_ChanServ]}";
           NickServ="${cfgValue[irc_NickServ]}";
                Log="${cfgValue[irc_Log]}";
       LogOverwrite="${cfgValue[irc_LogOverwrite]}";
          auto_Quit="${cfgValue[irc_AutoQuit]}";
        historyFile="${cfgValue[irc_ReadlineHistory]}";

unset Version_Stable;
unset Version_Preview;

if [[ "$1" =~ 'stable' ]]; then
    Version_Stable="$2";
elif [[ "$1" =~ 'preview' ]]; then
    Version_Preview="$2";
elif  [[ "$1" =~ 'both' ]]; then
    [[ -n "$2" ]] && Version_Stable="$2";
    [[ -n "$3" ]] && Version_Preview="$3";
fi

if [[ -n $AutoTopicOverride ]]; then auto_TOPIC_change=$AutoTopicOverride; fi
if [[ -n $AutoQuitOverride ]]; then auto_Quit=$AutoQuitOverride; fi

export TOPIC_template
export Version_Stable
export Version_Preview

# export random in case we want to use it somewhere
export RANDOM

declare -i uMode_w=4;
declare -i uMode_i=8;
declare -i uMode=0;
(( uMode += uMode_i ))
(( uMode += uMode_w ))

$LogOverwrite && rm -f "$Log" 2>/dev/null
printf "\n\n\n" >> "$Log"
printf "==================================================\n" >> "$Log"
printf "==== Starting %-31s ====\n" "$0" >> "$Log"
printf "==================================================\n" >> "$Log"

send() {
    printf "%s\r\n" "$*" >&3 && \
        printf ">>  %s\r\n" "$*" >> "$Log";
}

# User Modes
# a - user is flagged as away;
# i - marks a users as invisible;
# w - user receives wallops;
# r - restricted user connection;
# o - operator flag;
# O - local operator flag;
# s - marks a user for receipt of server notices.
# In the USER connect string if MODE bit 2 is set enable mode w  receive wallops
# In the USER connect string if MODE bit 3 is set enable mode i  user is invisible

LOGON() {
    [[ -n ${cfgValue[irc_Password]} ]] && send "PASS ${cfgValue[irc_Password]}"
    # now wipe the password for security. It's already been in memory for way to long. since we loaded the config!!!
    cfgValue[irc_Password]="$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM"
    send "NICK $Nick"
    send "USER $Nick $uMode bot :$Name"
}
JOIN() {
    send "JOIN $Channel"
}
                                    
HELP() {
    local aT=$( $auto_TOPIC_change && echo 'yes' || echo 'no '; );
    local aQ=$(          $auto_Quit && echo 'yes' || echo 'no '; );
    local Lr=$(      $LogOverwrite && echo 'yes' || echo 'no '; );
    local _N=$( printf "%-16s ====" "$Nick" );
    local _Log=$( printf "%-34s ====" "${Log}" );
    cat <<-EOF
	    =================================================
	    =================================================
	    ====           Some Helpfull Hints           ====
	    =================================================
	    ====                                         ====
	    ====  I should automatically login and join  ====
	    ====    Once I have OPS (+o) if there is     ====
	    ====    a new TOPIC configured I will try    ====
	    ====    to change the TOPIC and report       ====
	    ====    the new TOPIC                        ====
	    ====                                         ====
	    ====  Once you are happy with the change     ====
	    ====    Quit with /q or ;q                   ====
	    ====                                         ====
	    ====  Good luck and please report            ====
	    ====    any bugs to                          ====
	    ====    lsmbdev@sbts.com.au                  ====
	    ====                                         ====
	    ====  COMMAND prefix = /                     ====
	    ====    Any IRC command may be sent          ====
	    ====    but only those listed here           ====
	    ====    have any local processing            ====
	    ====    All others need you to manually      ====
	    ====    provide their required arguments     ====
	    ====    Also you probably wont see any       ====
	    ====    response here, you will need to      ====
	    ====    check the log file                   ====
	    ====                                         ====
	    ====    Start one of these beforehand        ====
	    ====    to see realtime logs                 ====
	    ====      eg: tail -n100 -f /tmp/irc.log     ====
	    ====            you will want at least       ====
	    ====            205 columns in your          ====
	    ====            terminal to use tail.        ====
	    ====      eg: less -S +F /tmp/irc.log        ====
	    ====                                         ====
	    ====                                         ====
	    ====   COMMANDS that are treated specially   ====
	    ====        WHO    - appends your Nick       ====
	    ====        TOPIC  - requires the channel    ====
	    ====                 so we add it for you    ====
	    ====                                         ====
	    ====  Shortcuts:                             ====
	    ====    /q         - Quit                    ====
	    ====    /t         - Get TOPIC               ====
	    ====    /T         - Set TOPIC from template ====
	    ====    /w         - do WHO on yourself      ====
	    ====    ;t         - Edit current TOPIC      ====
	    ====    ;T         - Set TOPIC from RegEx    ====
	    ====    ;w NICK    - do WHO $_N
	    ====                                         ====
	    ====  The following options are enabled      ====
	    ====                                         ====
	    ====  Log $_Log
	    ====  Auto Topic Change : $aT                ====
	    ====        Log Replace : $Lr                ====
	    ====          Auto Quit : $aQ                ====
	    ====                                         ====
	    ====                                         ====
	    ====                                         ====
	    =================================================
	    =================================================
EOF
}

QUIT() {
    send "PART #sbts"
    send "QUIT :$QuitMessage"
    printf "<>QUIT\n" | tee -a "$Log";
}

TALK() {
    local _RequiresNick='WHO';
    local _RequiresChannel='TOPIC';
    local _TOPIC_current='';
    EnableHistory "$historyFile";
    until [[ ${Tx:-99} == QUIT ]]; do
        read -e Tx 2>&1
        AddHistory "$Tx";
        if [[ ${Tx:0:1} == '/' ]]; then
            if (( ${#Tx} == 2 )); then
                case ${Tx:1:1} in
                    q ) QUIT;;
                    t ) send "TOPIC $Channel";;
                    T ) printf "<>Set Topic from Template\n" | tee -a "$Log";
                        changeTOPIC;;
                    w ) send "WHO $Nick";;
                esac
            else
                echo "<>Manual Command $Tx" | tee -a "$Log";
                local _cmd=${Tx%% *};
                _cmd=${_cmd:1};
                _cmd=${_cmd^^}; # force _cmd to be uppercase
                Tx="${Tx#* }";
                if [[ "${_cmd}" =~ $_RequiresChannel ]]; then _cmd+=" $Channel"; fi
                if [[ "${_cmd}" =~ $_RequiresNick ]]; then _cmd+=" $Nick"; fi
                send "${_cmd} :$Tx";
            fi
        elif [[ ${Tx:0:1} == ';' ]]; then
            case ${Tx:1:1} in
                q ) QUIT;;
                q ) return;;
                t ) printf "<>Edit Topic\n" >> "$Log";
                    read -t1 _TOPIC_current </tmp/irc.topic 2>&1;
                    read -r -e -p '<>Edit Topic: ' -i "$_TOPIC_current" _TOPIC_current 2>&1;
                    changeTOPIC "${_TOPIC_current:- }";;
                T ) printf "<>Set Topic from RegEx\n" | tee -a "$Log";
                    read -t1 _TOPIC_current </tmp/irc.topic 2>&1;
                    changeTOPIC "${_TOPIC_current:- }";;
                w ) send "WHO ${Tx#* }";;
            esac
        else
            send "PRIVMSG $Channel :$Tx";
        fi
    done
}

rxLOG() { # $_MOTD $_IDENT $_Server $_Seq $_Nick $_Chan $_Line;
    local M I J
    if $_MOTD;  then M='M'; else M='m'; fi
    if $_IDENT; then I='I'; else I='i'; fi
    if $_JOIN;  then J='J'; else J='j'; fi
    if $_OPS;   then O='O'; else O='o'; fi
    if $_TOPIC; then T='T'; else T='t'; fi
    if $_TOPIC_change_rq; then TcR='n'; else TcR='.'; fi
    if $_TOPIC_changed; then TcR='N'; fi

    printf "<  <%s:%s:%s:%s:%s%s> <%-40s> <%-10s> <%-15s> <%-30s> %s\n" $M  $I $J $O $T $TcR "$_Server" "$_Type" "$_Nick" "$_Chan" "${_Line:0:80}" >> "$Log";
    i=1;
    while (( ${#_Line} >(80*i) )); do
        printf "%123s%-80s\n" "" "${_Line:$((80*i++)):80}" >> "$Log";
    done
}


#BASH_REMATCH
#    An array variable whose members are assigned by the =~ binary operator to the [[ conditional command.  The element with index 0 is the portion of the string matching the entire regular
#    expression.  The element with index n is the portion of the string matching the nth parenthesized subexpression.  This variable is read-only.

changeTOPIC() { # $*=Current TOPIC    the regex to extract the two version numbers is in $TOPIC_regex
    local _TOPIC
    if [[ -n $1 ]] && [[ -n $TOPIC_regex_stable ]] && [[ -n $TOPIC_regex_preview ]]; then # if we have a Current TOPIC passed in and the 2 regex
        _TOPIC="$*";
        local _Prefix
        local _Postfix
        if [[ -n $Version_Stable ]]; then
            _Prefix=${_TOPIC%${TOPIC_regex_stable}*}${TOPIC_regex_stable//\[*([^]])*(])/ };
            _Postfix=${_TOPIC##*${TOPIC_regex_stable}*([^[:space:]])*( )};
            _TOPIC="$_Prefix$Version_Stable $_Postfix";
        fi
        if [[ -n $Version_Preview ]]; then
            _Prefix=${_TOPIC%${TOPIC_regex_preview}*}${TOPIC_regex_preview//\[*([^]])*(])/ };
            _Postfix=${_TOPIC##*${TOPIC_regex_preview}*([^[:space:]])*( )};
            _TOPIC="$_Prefix$Version_Preview $_Postfix";
        fi
    else # use the default template
        local _v='';
        read -p 'Enter Stable Version: ' _v 2>&1;
        : ${Version_Stable:=${_v:-$RANDOM}};   # set a temporary default
        _v='';
        read -p 'Enter Preview Version: ' _v 2>&1;
        : ${Version_Preview:=${_v:-$RANDOM}};  # set a temporary default
        _TOPIC="$(envsubst '$Version_Stable:$Version_Preview' <<<$TOPIC_template)"
    fi
    send "TOPIC $Channel :$_TOPIC"
}

LISTEN() { # :roddenberry.freenode.net 376 dcg_test :End of /MOTD command.
    local _Server="" _Type="" _Nick="" _Chan="" _Line="" _MOTD=false _IDENT=false _JOIN=false _TOPIC=false _OPS=false
    local TOPIC_current='';
    local _cmdWithChannel='396|332|333|366';
    local _cmdNoDisplay='375|372|376|332|333|366';
    local _cmdWitWithoutNick='JOIN|MODE'; # a test for leading hash is done to decide if there is a nick or just a channel
    local _TOPIC_change_rq=false;
    local _TOPIC_changed=false;
    printf '' > /tmp/irc.topic

    while read -u3 _Server _Type _Nick _Line; do
        _Chan=''; # make sure _Chan is cleared, otherwise we can end up with stale data
        _Type="${_Type//[[:cntrl:]]/}"; # a little dumb, but just delete any control chars in contents
        _Nick="${_Nick//[[:cntrl:]]/}"; # a little dumb, but just delete any control chars in contents
        _Line="${_Line//[[:cntrl:]]/}"; # a little dumb, but just delete any control chars in contents
        if  [[ "$_Type" =~ $_cmdWithChannel ]]; then # break out the _Chan field if the command (_Type) uses it
                _Chan="${_Line%% *}";
                _Line="${_Line#* }";
        fi
        if  [[ "$_Type" =~ $_cmdWithWithoutNick ]]; then
            if [[ "$_Nick" =~ ^# ]]; then  # yes even though the syntax highlighting is screwed for the rest of the line the # doesn't need to be quoted.
                _Chan="${_Nick}";
                _Nick="";
            fi
        fi
        if [[ "$_Type" == "376" ]]; then # end of MOTD
                printf "<>MOTD\n" | tee -a "$Log";
                _MOTD=true;
        fi
        if  [[ "$_Server" =~ "${NickServ}" ]] && \
            [[ "$_Type" == "NOTICE" ]] && \
            [[ "$_Nick" == "$Nick" ]] && \
            [[ "$_Line" =~ ':You are now identified for' ]]; then
                printf "<>IDENT\n" | tee -a "$Log";
                _IDENT=true; 
                JOIN;
        fi
        if ! $_JOIN && $_IDENT; then # we have Ident, but have not joined.
            if  [[ "$_Type" == "JOIN" ]] && \
                [[ "$_Chan" == "$Channel" ]]; then
                    printf "<>JOIN %s as %s\n" "$_Chan" "$Nick" | tee -a "$Log";
                    _JOIN=true; 
            fi
        fi
        if  [[ "$_Type" =~ 332|TOPIC ]] && \
            [[ "$_Chan" == "$Channel" ]]; then  # Yay we have just received the channels TOPIC
                TOPIC_current="${_Line:1}"; # strip the leading : from the topic as it is part of the protocol.
                _TOPIC=true;
                printf "%s\n" "$TOPIC_current" > /tmp/irc.topic  # store the topic so main process can use it.
                if $_TOPIC_change_rq && ! $_TOPIC_changed; then
                    printf "<>TOPIC_changed=%s\n" "$TOPIC_current" | tee -a "$Log";
                    _TOPIC_changed=true;
                else
                    printf "<>TOPIC=%s\n" "$TOPIC_current" | tee -a "$Log";
                fi
        fi
        if  $_JOIN && \
            [[ "$_Type" == "MODE" ]] && \
            [[ "$_Chan" == "$Channel" ]] && \
            [[ "${_Line%% *}" =~ '+o' ]] && \
            [[ "$_Line" =~ $Nick ]]; then
                printf "<>OPS\n" | tee -a "$Log";
                _OPS=true; 
                if ${auto_TOPIC_change:-false}; then
                    changeTOPIC "$TOPIC_current";
                    _TOPIC_change_rq=true;
                fi
        fi
        if $auto_Quit && $_TOPIC_changed; then
            QUIT;
        fi

        rxLOG $_MOTD $_IDENT $_JOIN _Server _Type _Nick _Chan _Line;
        if [[ $_Server == 'ERROR' ]] && [[ $_Type == ':Closing' ]]; then
            kill $ParentPid;
            exit;
        fi
        if [[ "$_Type" =~ $_cmdNoDisplay ]]; then continue; fi # Suppress MOTD
        if [[ $_Server == PING ]]; then send "PONG $Nick $_Type"; continue; fi
        if ! $_MOTD; then continue; fi                      # filter on End of MOTD
        if [[ ! $_Chan == $Channel ]] || [[ $_Type == 352 ]]; then continue; fi    # filter on $Channel but allow response to /WHO (352)
        if [[ ! $_Nick == $Nick ]]; then continue; fi       # filter on $Nick

        $_IDENT && printf "+%s\n" "$_Line";
    done
}

clear;

HELP;

ParentPid=$BASHPID; export ParentPid;

# redirect stderr to a file so we can get /dev/tcp errors after connection
exec 2>/tmp/irc.tcpconnection.log

echo "**==** CONNECTING to SERVER $Server:$Port"
echo "         this can take >2minutes to timeout if it fails."
exec 3<> /dev/tcp/$Server/$Port
_Result=$? # store the result so we can test it and report it in the error window

if (( $_Result != 0 )); then
    cat <<-EOF  | tee -a "$Log";
	    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	    %%%%                                         %%%%
	    %%%%  **** !!!! Connection ERROR !!!! ****   %%%%
	    %%%%                                         %%%%
	    %%%%  Connection to server failed: error $(printf "%-3s %%%%%%%%" "$_Result"; )
	    %%%%  $(printf "%25s:%-7s      %%%%%%%%" "$Server" "$Port"; )
	    %%%%                                         %%%%
	    %%%%                                         %%%%
	    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EOF
cat /tmp/irc.tcpconnection.log
    exit 1;
fi
echo "**==** tcp CONNECTON established"

# redirect stderr to /dev/null, hides some terminal spam
exec 2>/dev/null


echo "**==** LOGGING IN"
LOGON
echo "**==** Starting LISTENER"
LISTEN & ChildPid=$!;

echo "**==** User Input Enabled"
TALK

echo "**==** CLOSING connection to server"

wait
exec 3>&- ; exec 3<&- ;

echo "**==** EXIT";

exit;
