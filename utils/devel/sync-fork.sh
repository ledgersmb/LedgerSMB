#!/bin/bash

Upstream='https://github.com/ledgersmb/LedgerSMB.git'

if ! [[ -d $1 ]]; then
    cat <<-EOF
	usage: $0 directory
	
	Where directory is your local copy of a fork of LedgerSMB
	
EOF
    exit 1;
fi

cd `readlink -f ${1}`


Error() {
    cat <<-EOF
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%% ERROR %% ERROR %% ERROR %% ERROR %% ERROR %% ERROR %%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%                                                    %%$(printf "\r%% %s" "$1")
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EOF
    exit 1
}

if ! [[ -r LedgerSMB.pm ]] && ! [[ -r lib/LedgerSMB.pm ]] ; then
    Error "Not a LedgerSMB repository"
fi

AvailableRemotes=`git remote -v`
if ! [[ $AvailableRemotes =~ $Upstream ]]; then
    if  [[ $AvailableRemotes =~ upstream ]]; then
        echo -e "$AvailableRemotes\n\n"
        printf "Can't Add Upstream Remote\n\t%s\n" "$Upstream"
        Error "Another Upstream already exists."
    fi

    printf "Adding Upstream Remote\n\t%s\n\n" "$Upstream"
    git remote add upstream "$Upstream"
fi

git fetch upstream || Error "Fetching Upstream."


git checkout master || Error "Checking out Master."


git merge upstream/master || Error "Merging upstream/master with local /master"



cat <<EOF

    Don't forget:
      Syncing your fork only updates your local copy of the repository.
      To update your fork on GitHub, you must push your changes.
      using
        git push

    If you are working on a branch that is not master then you will also need to do something like
        git checkout 1.4
        git merge upstream/1.4

EOF


