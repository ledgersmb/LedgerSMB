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

# using stash create may cause issues if we fail during the other git operations, 
# as when we re-run this script we won't know what the stashID is 
# so won't be able to revert to the original state of the repo
# at least if we use "stash save --all" a manual pop would be enough to restore state
#stash=`git stash create`
unset stash
git stash save --all "automatic stash while running 'sync-fork.sh'"

git checkout master || Error "Checking out Master."

git fetch upstream || Error "Fetching Upstream."

git merge upstream/master || Error "Merging upstream/master with local /master"

git checkout "$CurrentBranch" || Error "Checking out $CurrentBranch."

git stash pop $stash

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


