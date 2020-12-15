#! /usr/bin/env bash
#>________________________________________________________________________________
#>
#> [ inventory.sh ]
#>
#> ABOUT:
#>
#>    Generate an index of files and directories
#>
#>    Unless otherwise indicated, all outputs are printed directly to STDOUT; if
#>    no inputs are detected, inventory will default to printing a JSON directory
#>    tree of the files within the current working directry.
#>
#>    Created on 20201214 by h8rt3rmin8r
#>
#> USAGE:
#>
#>    inventory.sh <OPTION> (<INPUT>)
#>
#>    where "INPUT" is determined by "OPTION"; and where "OPTION" is one of
#>    the following:
#>
#>                 |
#>    -h, --help   | Print this help text to the terminal
#>                 |
#>    --html <X>   | Generate an HTML directory tree of all files located in
#>                 | the directory "X"; where "X" is an optional directory
#>                 | reference
#>                 |
#>                 | If no directory reference is passed, this operation will
#>                 | execute within the current working directory
#>                 |
#>    --json <X>   | Generate a JSON directory tree of all files located in
#>                 | the directory "X"; where "X" is an optional directory
#>                 | reference
#>                 |
#>                 | If no directory reference is passed, this operation will
#>                 | execute within the current working directory
#>                 |
#>
#> REFERENCE:
#>
#>    tree (user manual)
#>    https://linux.die.net/man/1/tree
#>
#>    Guide to Linux jq Command for JSON Processing
#>    https://www.baeldung.com/linux/jq-command-json
#>
#>________________________________________________________________________________
#________________________________________________________________________________
# Declare functions

function tc_f() {
    # Text color formatting for verbosity messages
    #------------------------------------------------------------------------------
    # Assign core variables
    ##
    ## The final output string is the concatenation of the following:
    ##    ${s_dt}${s_na}${s_ty}${s_ms}
    ##
    ## Each variable (with the exception of $s_ms) must end with a "pipe" symbol (|)
    ## Segments are thereby removed by simply declaring them as an empty variable
    ##
    local s_dt=""
    local s_na=""
    local s_ty=""
    local s_ms=""

    # Derive the remaining variables base on user inputs and environment conditions
    local n_a=( $(echo ${FUNCNAME[*]}) )
    local s_n=${n_a[-1]}  ##==> the final $s_na is declared later

    ## process all input parameters and build the output based on what parameters are found
    while [[ "${1}" =~ ^[-]+ ]]; do
        local p_x="${1//[-]}"

        case "${p_x}" in
            ## date prepending
            d|date)
                local s_dt="$(date '+%s.%N')|"

                shift 1
                ;;
            ## alternative date formatting
            D)
                local s_dt="$(date '+%s%N')|"

                shift 1
                ;;
            ## verbosity type assignment
            e|E|eb|ex|i|I|ib|ix|r|R|rb|rx|s|S|sb|sx|w|W|wb|wx)
                case "${p_x}" in
                    e)
                        ## ERROR - standard output
                        local s_na=$(printf "\e[38;5;196m${s_n}\e[0m"'|')
                        local s_ty=$(echo -en '\e[38;5;196merror\e[0m__|')
                        ;;
                    E)
                        ## ERROR - colorless output
                        local s_na=$(printf "\e[0m${s_n}"'|')
                        local s_ty=$(echo -en '\e[0merror__|')
                        ;;
                    i)
                        ## INFO - standard output
                        local s_na=$(printf "\e[38;5;25m${s_n}\e[0m"'|')
                        local s_ty=$(echo -en '\e[38;5;25minfo\e[0m___|')
                        ;;
                    I)
                        ## INFO - colorless output
                        local s_na=$(printf "\e[0m${s_n}"'|')
                        local s_ty=$(echo -en '\e[0minfo___|')
                        ;;
                    r)
                        ## REQUEST - standard output
                        local s_na=$(printf "\e[0;49;35m${s_n}\e[0m"'|')
                        local s_ty=$(echo -en '\e[0;49;35mrequest\e[0m|')
                        ;;
                    R)
                        ## REQUEST - colorless output
                        local s_na=$(printf "\e[0m${s_n}"'|')
                        local s_ty=$(echo -en '\e[0mrequest|')
                        ;;
                    s)
                        ## SUCCESS - standard output
                        local s_na=$(printf "\e[38;5;82m${s_n}\e[0m"'|')
                        local s_ty=$(echo -en '\e[38;5;82msuccess\e[0m|')
                        ;;
                    S)
                        ## SUCCESS - colorless output
                        local s_na=$(printf "\e[0m${s_n}"'|')
                        local s_ty=$(echo -en '\e[0msuccess|')
                        ;;
                    w)
                        ## WARNING - standard output
                        local s_na=$(printf "\e[33m${s_n}\e[0m"'|')
                        local s_ty=$(echo -en '\e[33mwarning\e[0m|')
                        ;;
                    W)
                        ## WARNING - colorless output
                        local s_na=$(printf "\e[0m${s_n}"'|')
                        local s_ty=$(echo -en '\e[0mwarning|')
                        ;;
                    eb)
                        ## ERROR - blinking output
                        local s_na=$(printf "\e[5m\e[38;5;196m${s_n}\e[0m"'|')
                        local s_ty=$(echo -en '\e[5m\e[38;5;196merror\e[0m__|')
                        ;;
                    ib)
                        ## INFO - blinking output
                        local s_na=$(printf "\e[5m\e[38;5;25m${s_n}\e[0m"'|')
                        local s_ty=$(echo -en '\e[5m\e[38;5;25minfo\e[0m___|')
                        ;;
                    rb)
                        ## REQUEST - blinking output
                        local s_na=$(printf "\e[5;49;35m${s_n}\e[0m"'|')
                        local s_ty=$(echo -en '\e[5;49;35mrequest\e[0m|')
                        ;;
                    sb)
                        ## SUCCESS - blinking output
                        local s_na=$(printf "\e[5m\e[38;5;82m${s_n}\e[0m"'|')
                        local s_ty=$(echo -en '\e[5m\e[38;5;82msuccess\e[0m|')
                        ;;
                    wb)
                        ## WARNING - blinking output
                        local s_na=$(printf "\e[5m\e[33m${s_n}\e[0m"'|')
                        local s_ty=$(echo -en '\e[5m\e[33mwarning\e[0m|')
                        ;;
                    ex)
                        ## ERROR - grey output
                        local s_na=$(printf "\e[1;92m${s_n}\e[0m"'|')
                        local s_ty=$(echo -en '\e[1;92merror\e[0m__|')
                        ;;
                    ix)
                        ## INFO - grey output
                        local s_na=$(printf "\e[1;92m${s_n}\e[0m"'|')
                        local s_ty=$(echo -en '\e[1;92minfo\e[0m___|')
                        ;;
                    rx)
                        ## REQUEST - grey output
                        local s_na=$(printf "\e[1;92m${s_n}\e[0m"'|')
                        local s_ty=$(echo -en '\e[1;92mrequest\e[0m|')
                        ;;
                    sx)
                        ## SUCCESS - grey output
                        local s_na=$(printf "\e[1;92m${s_n}\e[0m"'|')
                        local s_ty=$(echo -en '\e[1;92msuccess\e[0m|')
                        ;;
                    wx)
                        ## WARNING - grey output
                        local s_na=$(printf "\e[1;92m${s_n}\e[0m"'|')
                        local s_ty=$(echo -en '\e[1;92mwarning\e[0m|')
                        ;;
                esac

                shift 1
                ;;
        esac
    done

    ## build the verbosity message from all remaining inputs that weren't used
    ## by the previous case operation
    local s_ms="$@"

    ## if the $s_na variable is still empty, build it with default colors
    if [[ "x${s_na}" == "x" ]]; then
        local s_na="${s_n}|"
    fi

    ## if the $s_ty variable is still empty, build a null field
    if [[ "x${s_ty}" == "x" ]]; then
        local s_ty='_______|'
    fi

    echo "${s_dt}${s_na}${s_ty}${s_ms}" &>/dev/stderr

    return $?
}

function inventory_acheck() {
    local path_base="${sh_path%\/*}"
    local a_file="${path_base}/analytics.html"

    if [[ -f "${a_file}" ]]; then
        echo "0"

        return 0
    else
        echo "1"

        return 1
    fi
}

function inventory_apath() {
    local path_base="${sh_path%\/*}"
    local a_file="${path_base}/analytics.html"

    echo "${a_file}"

    return $?
}

function inventory_bcheck() {
    local path_base="${sh_path%\/*}"
    local b_file="${path_base}/brand.html"

    if [[ -f "${b_file}" ]]; then
        echo "0"

        return 0
    else
        echo "1"

        return 1
    fi
}

function inventory_bpath() {
    local path_base="${sh_path%\/*}"
    local b_file="${path_base}/brand.html"

    echo "${b_file}"

    return $?
}

function inventory_depends() {
    ## Check for the presence of required software packages
    declare -a a_depends=( "jq" "tree" )

    local chk_str=""

    for i in "${a_depends[@]}"; do
        local cycle_check=$(which "${i}" &>/dev/null; echo $?)
        local chk_str="${chk_str}${cycle_check}"
    done

    if [[ "${chk_str}" =~ 1 ]]; then
        tc_f -d -e "Missing one or more required software packages: ${a_depends[@]}"

        return 1
    else
        return 0
    fi
}

function inventory_html() {
    # Print a directory tree in HTML format and modify all links to be relative
    local mod_a="${t_dir//\//\\\/}\/"
    local mod_b="${t_dir//\//\\\/}"

    inventory_writectl > "${tmpf}"

    cd "${t_dir}"

    tree -x -D -h --dirsfirst --noreport --charset unicode -a -L 3 -H "${t_dir}" 2>/dev/null \
        | dos2unix \
        | tr '\n' '█' \
        | sed "s/${mod_a}/\//g;s/${mod_b}//g" \
        | tr '█' '\n' \
        | tr '\t' ' ' \
        | tail -n +30 \
        | head -n -12 >> "${tmpf}"
    
    echo '</div><p>&nbsp;</p></body></html>' >> "${tmpf}"

    cd "${here_now}"

    cat "${tmpf}"

    rm "${tmpf}" &>/dev/null

    return $?
}

function inventory_json() {
    # Print a directory tree in JSON format
    tree -J -a -s "${t_dir}" 2>/dev/null > ${tmpf}
    jq -c '.' ${tmpf} 2>/dev/null

    if [[ "$?" -eq 0 ]]; then
        rm ${tmpf} &>/dev/null

        return 0
    else

        ##
        ## If jq failed but tree completed successfully, there could be files with
        ## strange names that are causing a syntax error in JSON (this happens when
        ## building a tree with files named using the Microsoft back-slashing syntax)
        ##
        ## Check for the presence of required software but attempt to output the raw
        ## output file from 'tree' if such an output exists
        ##

        inventory_depends

        if [[ "$?" -ne 0 ]]; then
            return 1
        fi

        ##
        ## By this point, we now know both tree and jq are installed. Therefore, the
        ## output of tree contains syntax errors.
        ##

        cat ${tmpf}
        rm ${tmpf} &>/dev/null

        return 2
    fi
}

function inventory_help() {
    cat "${0}" \
        | grep -E '^#[>]' \
        | sed 's/^..//'
    
    return $?
}

function inventory_write_analytics() {
    cat "${analytics_file}" 2>/dev/null \
        | tr -s '\t' ' ' \
        | tr -d '\n' \
        | tr -s ' ' ' '

    return $?
}

function inventory_write_brand() {
    cat "${brand_file}" 2>/dev/null \
        | tr -s '\t' ' ' \
        | tr -d '\n' \
        | tr -s ' ' ' '
    
    return $?
}

function inventory_write_css() {
    echo -n '<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.0-beta1/dist/css/bootstrap.min.css" rel="stylesheet">'

    return $?
}

function inventory_write_head_a() {
    echo -n '<!DOCTYPE html><html lang="en"><head>'
    
    return $?
}

function inventory_write_head_b() {
    echo -n '<meta http-equiv="Content-Type" content="text/html; charset=utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><meta http-equiv="X-UA-Compatible" content="IE=edge"><title>Site Inventory</title><meta name="description" content="inventory"><meta name="keywords" content="161803398, site inventory, inventory.sh">'

    return $?
}

function inventory_write_head_c() {
    echo -n '<style type="text/css">BODY { font-family : ariel, monospace, sans-serif; }P { font-weight: normal; font-family : ariel, monospace, sans-serif; color: black; background-color: transparent;}B { font-weight: normal; color: black; background-color: transparent;}A:visited { font-weight : normal; text-decoration : none; background-color : transparent; margin : 0px 0px 0px 0px; padding : 0px 0px 0px 0px; display: inline; }A:link    { font-weight : normal; text-decoration : none; margin : 0px 0px 0px 0px; padding : 0px 0px 0px 0px; display: inline; }A:hover   { color : #000000; font-weight : normal; text-decoration : underline; background-color : yellow; margin : 0px 0px 0px 0px; padding : 0px 0px 0px 0px; display: inline; }A:active  { color : #000000; font-weight: normal; background-color : transparent; margin : 0px 0px 0px 0px; padding : 0px 0px 0px 0px; display: inline; }.VERSION { font-size: small; font-family : arial, sans-serif; }.NORM  { color: black;  background-color: transparent;}.FIFO  { color: purple; background-color: transparent;}.CHAR  { color: yellow; background-color: transparent;}.DIR   { color: blue;   background-color: transparent;}.BLOCK { color: yellow; background-color: transparent;}.LINK  { color: aqua;   background-color: transparent;}.SOCK  { color: fuchsia;background-color: transparent;}.EXEC  { color: green;  background-color: transparent;}</style>'
    
    return $?
}

function inventory_write_head_d() {
    echo '</head><body><p>&nbsp;</p><div class="container">'
    
    return $?
}

function inventory_write_js() {
    echo -n '<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.0-beta1/dist/js/bootstrap.bundle.min.js"></script>'

    return $?
}

function inventory_writectl() {
    inventory_write_head_a

    if [[ "${has_analytics}" -eq 0 ]]; then
        inventory_write_analytics
    fi

    inventory_write_head_b

    if [[ "${has_brand}" -eq 0 ]]; then
        inventory_write_brand
    fi

    inventory_write_css
    inventory_write_head_c
    inventory_write_js
    inventory_write_head_d

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

here_now="${PWD}"
sh_name="inventory.sh"
sh_path=$(readlink -f "${0}")
nonce="${RANDOM:0:1}${RANDOM: -1}${RANDOM: -1}${RANDOM: -1}"
runtime="$(date '+%s%N')"
tmpf="/tmp/${sh_name}_${runtime}-${nonce}"
has_analytics=$(inventory_acheck)
has_brand=$(inventory_bcheck)
analytics_file=""
brand_file=""

if [[ "${has_analytics}" -eq 0 ]]; then
    analytics_file=$(inventory_apath)
fi

if [[ "${has_brand}" -eq 0 ]]; then
    brand_file=$(inventory_bpath)
fi

#________________________________________________________________________________
# Process inputs and execute operations

## catch help text requests
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    inventory_help
    
    exit $?
fi

## if no inputs are detected, execute the default operation (JSON tree output)
if [[ "$#" -eq 0 ]]; then
    t_dir=$(readlink -f "${PWD}")

    inventory_json

    exit $?
fi

## detect desired operation type
case "${1//[-]}" in
    html)
        if [[ "x${2}" == "x" ]]; then
            t_dir=$(readlink -f "${PWD}")
        else
            t_dir=$(readlink -f "${2}")
        fi

        inventory_html

        exit $?
        ;;
    json)
        if [[ "x${2}" == "x" ]]; then
            t_dir=$(readlink -f "${PWD}")
        else
            t_dir=$(readlink -f "${2}")
        fi

        inventory_json

        exit $?
        ;;
    *)
        tc_f -d -e "Unknown input parameter detected: ${1}"
        tc_f -d -i "Use '--help' for more information"

        exit 1
        ;;
esac

#________________________________________________________________________________
