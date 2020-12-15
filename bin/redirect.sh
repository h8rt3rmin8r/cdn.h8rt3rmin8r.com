#! /usr/bin/env bash
#>--------------------------------------------------------------------------------
#>
#> [ redirect.sh ]
#>
#>    Generate HTML redirection pages
#>
#>    Created on 20201214 by h8rt3rmin8r
#>
#> USAGE:
#>
#>    redirect.sh <INPUT>
#>    redirect.sh <OPTION>
#>
#>    where "INPUT" is an optional Internet URL; and where "OPTION" is one of the
#>    following:
#>
#>                |
#>    -h, --help  | Print this help text to the terminal
#>                |
#>
#>--------------------------------------------------------------------------------
#________________________________________________________________________________
# Declare functions

function rdr_acheck() {
    local a_file="${sh_root}/analytics.html"

    if [[ -f "${a_file}" ]]; then
        echo "0"

        return 0
    else
        echo "1"

        return 1
    fi
}

function rdr_apath() {
    local a_file="${sh_root}/analytics.html"

    echo "${a_file}"

    return $?
}

function rdr_back() {
    rdr_write_dat "A1"

    if [[ "${has_analytics}" -eq 0 ]]; then
        rdr_write_ana
    fi

    rdr_write_dat "A2"

    echo ""

    return $?
}

function rdr_help() {
    cat "${sh_path}" \
        | grep -E '^#[>]' \
        | sed 's/^..//'
    
    return $?
}

function rdr_random() {
    cat /dev/urandom \
        | tr -dc 'a-zA-Z0-9' \
        | fold -w ${1} \
        | head -n 1

    return $?
}

function rdr_redirect() {
    local i_n="${1}"

    rdr_write_dat "B1"

    if [[ "${has_analytics}" -eq 0 ]]; then
        rdr_write_ana
    fi

    rdr_write_dat "B2"

    echo -n "${i_n}"

    rdr_write_dat "B3"

    echo ""

    return $?
}

function rdr_write_ana() {
    cat "${analytics_file}" 2>/dev/null \
        | tr -s '\t' ' ' \
        | tr -d '\n' \
        | tr -s ' ' ' '
    
    return $?
}

function rdr_write_dat() {
    local i_n="${1}"

    cat "${sh_path}" \
        | grep -E "^#${i_n}#" \
        | sed 's/^....//' \
        | tr -d '\n'

    return $?
}

#________________________________________________________________________________
# Declare variables

_ak=$'\u002A'
_at=$'\u0040'
_bs=$'\u005C'
_cm=$'\u002C'
_co=$'\u003A'
_ds=$'\u002D'
_eq=$'\u003D'
_fs=$'\u002F'
_gt=$'\u003E'
_hs=$'\u0023'
_lt=$'\u003C'
_or=$'\u007C'
_pa=$'\u0028'
_pb=$'\u0029'
_pc=$'\u0025'
_pe=$'\u002E'
_q1=$'\u0027'
_q2=$'\u0022'
_qm=$'\u003F'
_sc=$'\u003B'
_sp=$'\u0020'
_up=$'\u005E'
_us=$'\u005F'
_and=$'\u0026'
_cba=$'\u007B'
_cbb=$'\u007D'
_exc=$'\u0021'
_plu=$'\u002B'
_sba=$'\u005B'
_sbb=$'\u005D'
_tik=$'\u0060'
_til=$'\u007E'
_usd=$'\u0024'

sh_name="redirect"
sh_path=$(readlink -f "${0}")
sh_root="${sh_path%\/*}"
runtime="$(date '+%s%N')"
nonce="${RANDOM:0:1}${RANDOM: -1}${RANDOM: -1}${RANDOM: -1}"
tmpf="/tmp/${sh_name}_${runtime}-${nonce}"
has_analytics=$(rdr_acheck)
analytics_file=""

if [[ "${has_analytics}" -eq 0 ]]; then
    analytics_file=$(rdr_apath)
fi

#________________________________________________________________________________
# Execute operations

## catch help text requests
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    rdr_help
    
    exit $?
fi

if [[ "x${1}" == "x" ]]; then
    rdr_back > "${tmpf}"
else
    rdr_redirect "${1}" > "${tmpf}"
fi

e_c="$?"

cat "${tmpf}" 2>/dev/null
rm "${tmpf}" 2>/dev/null

exit $?

#A1#<!DOCTYPE html><html lang="en"><head>
#A2#<meta http-equiv="Content-Type" content="text/html; charset=utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><meta http-equiv="X-UA-Compatible" content="IE=edge"><title>GO BACK</title></head><body onload="goBack()"><br><pre>¯\_(ツ)_/¯</pre><br><script>function goBack() {window.history.back();}</script></body></html>
#B1#<!DOCTYPE html><html lang="en"><head>
#B2#<meta http-equiv="Content-Type" content="text/html; charset=utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><meta http-equiv="X-UA-Compatible" content="IE=edge"><meta http-equiv="refresh" content="0; URL=
#B3#" /><title>GO</title></head><body><br><pre>¯\_(ツ)_/¯</pre></body></html>
