#!/bin/bash

Upstream='https://github.com/ledgersmb/LedgerSMB.git'

Dir=`git rev-parse --show-toplevel`

if ! [[ -d "$Dir" ]]; then
    cat <<-EOF
	usage: $0 directory
	
	Where directory is your local copy of a fork of LedgerSMB
	
EOF
    exit 1;
fi

cd `readlink -f "${Dir}"`


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

CurrentBranch=`git rev-parse --abbrev-ref HEAD`

git checkout master || Error "Checking out Master."

git fetch upstream || Error "Fetching Upstream."

git merge upstream/master || Error "Merging upstream/master with local /master"

git checkout "$CurrentBranch" || Error "Checking out $CurrentBranch."


cat <<EOF

    Don't forget:
      Syncing your fork only updates your local copy of the repository.
      To update your fork on GitHub, you must push your changes.
      using
        git push

    If you are working on a branch then you will also need to do something like
        git merge upstream/master
      or
        git merge upstream/1.4

EOF


