#!/bin/bash -e
pkgname="$1"

function getinfo() {
    local pkgname="$1"
    curl -G "https://aur.archlinux.org/rpc/" --data-urlencode "v=5" --data-urlencode "type=info" --data-urlencode "arg[]=$pkgname"
}

function getmyinfo() {
    local pkgname="$1"
    curl -Gv "https://aur.tedyin.com/rpc/" --data-urlencode "v=5" --data-urlencode "type=info" --data-urlencode "arg[]=$pkgname"
}

function isnull() {
    [[ $(echo "$1" | jq '.results[0]' --raw-output) == null ]]
}

function getbase() {
    echo "$1" | jq '.results[0].PackageBase' --raw-output
}


function rver() {
    echo "$1" | sed 's/\([-@._+a-zA-Z0-9]*\).*/\1/g'
}

function getdeps() {
    for p in $(echo "$1" | jq '.results[0].Depends[]' --raw-output 2> /dev/null); do
        rver "$p"
    done
}

function getmakedeps() {
    for p in $(echo "$1" | jq '.results[0].MakeDepends[]' --raw-output 2> /dev/null); do
        rver "$p"
    done
}

function getcheckdeps() {
    for p in $(echo "$1" | jq '.results[0].MakeDepends[]' --raw-output 2> /dev/null); do
        rver "$p"
    done
}

function getpkg() {
    local pkgbase="$1"
    [[ -d "$1" ]] && {
        echo "$pkgbase already exists."
        cd "$pkgbase"; git pull upstream master; git push origin master; cd ..
        return 0
    }
    echo "$pkgbase: fetching..."
    git clone "ssh://aur@tedyin.com:2334/$pkgbase.git"
    cd "$pkgbase"
    git remote add upstream "https://aur.archlinux.org/$pkgbase.git"
    git pull upstream master
    git push origin master -u
    cd ..
}

function _getallpkg() {
    local deps=($1)
    {
        OIFS="$IFS"
        IFS=$' '
        echo "$pkgname $2 => ${deps[@]}"
        IFS="$OIFS"
    }
    for p in "${deps[@]}"; do
        pacman -Ss "^${p//+/\\+}$" > /dev/null 2>&1 && {
            echo "$p is already in ABS"
            continue
        }
        echo "$p is in AUR"
        getallpkg "$p"
    done
}

function getallpkg() {
    local pkgname="$1"
    local info="$(getinfo $pkgname)"
    local replicate=1
    if isnull "$info"; then
        echo "$pkgname not found in the official AUR, trying Ted's AUR..."
        info="$(getmyinfo $pkgname)"
        replicate=0
        if isnull "$info"; then
            echo "failed to locate the package"
            exit 1
        fi
    fi
    local pkgbase=$(getbase "$info")
    echo "$pkgname: $pkgbase"
    [[ $replicate == 1 ]] && { getpkg "$pkgbase" || return; }
    _getallpkg "$(getdeps "$info")" Depends
    _getallpkg "$(getmakedeps "$info")" MakeDepends
    _getallpkg "$(getcheckdeps "$info")" CheckDepends
}

getallpkg $pkgname
