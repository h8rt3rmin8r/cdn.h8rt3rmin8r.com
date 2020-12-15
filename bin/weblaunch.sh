#! /usr/bin/env bash
#>------------------------------------------------------------------------------
#>
#> [ weblaunch.sh ]
#>
#>    Launch an indicated URL in Google Chrome using "app mode" settings
#>    Created on 20201109 by h8rt3rmin8r
#>
#> USAGE:
#>
#>    weblaunch.sh <INPUT>
#>    weblaunch.sh <OPTION>
#>
#>    where "INPUT" is a valid Internet URL; and where "OPTION" is one of the
#>    following:
#>
#>                |
#>    -h, --help  | Print this help text to the terminal
#>                |
#>
#>    If no "INPUT" is provided, this script will fallback to launching a new
#>    session on the following URL: https://www.google.com/
#>
#>------------------------------------------------------------------------------

# Declare functions

function _help() {
    cat "${0}" \
        | grep -E '^#[>]' \
        | sed 's/^..//'
    
    return $?
}

function _run() {
    google-chrome --app="${in_url}" --new-window

    return $?
}

# Declare variables

in_url="https://www.google.com/"

# Execute operations

if [[ "${1}" =~ ^[-][hH]$ || "${1}" =~ ^[-]+help$ ]]; then
    _help

    exit $?
fi

if [[ ! "x${1}" == "x" ]]; then
    in_url="${1}"
fi

_run

exit $?
