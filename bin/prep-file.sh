#! /usr/bin/env bash
#>--------------------------------------------------------------------------------
#>
#> [ prep-file.sh ]
#>
#>    Prep an indicated file for uploading to cdn.h8rt3rmin8r.com
#>
#>    Created on 20201214 by h8rt3rmin8r
#>
#> USAGE:
#>
#>    prep-file.sh <INPUT>
#>    prep-file.sh <OPTION>
#>    prep-file.sh <OPTION> <INPUT>
#>
#>    where "INPUT" is a valid file reference; and where "OPTION" is one or more
#>    of the following:
#>
#>                   |
#>    -a, --all      | Process the input file both with compression and without
#>                   | compression (two new files will be added to the CDN)
#>                   |
#>    -c, --compress | Compress the input file while formatting it for upload
#>                   |
#>    -h, --help     | Print this help text to the terminal
#>                   |
#> 
#>--------------------------------------------------------------------------------
#________________________________________________________________________________
# Declare functions

function pf_compress() {

    zip -qq -D -j -8 -X- "dl.zip" "${i_n_path}" 2>/dev/null

    mv "dl.zip" "${out_zip}" 2>/dev/null

    return $?
}

function pf_help() {
    cat "${sh_path}" \
        | grep -E '^#[>]' \
        | sed 's/^..//'
    
    return $?
}

function pf_hash() {
    sha256sum "${i_n_path}" \
        | cut -d ' ' -f1

    return $?
}

function pf_inventory() {
    eval ${sh_inventory} --html "${out_root}" > "${out_inventory_html}"
    eval ${sh_inventory} --json "${out_root}" > "${out_inventory_json}"
    eval ${sh_inventory} --html "${master_root}" > "${master_inventory_html}"
    eval ${sh_inventory} --json "${master_root}" > "${master_inventory_json}"

    return $?
}

function pf_make() {
    mkdir -p "${master_inventory}"
    mkdir -p "${out_dir}"
    mkdir -p "${out_inventory}"

    touch "${master_inventory_html}"
    touch "${master_inventory_json}"
    touch "${out_inventory_html}"
    touch "${out_inventory_json}"

    if [[ ! -f "${out_main}" ]]; then
        cp "${site_main}" "${out_main}"
    fi

    return $?
}

function pf_plain() {
    cp --preserve=all "${i_n_path}" "${out_fil}"

    return $?
}

function pf_vbs() {
    local message="$@"

    echo "$(date '+%s%N')|${sh_name}|${message}" &>/dev/stderr

    return $?
}

#________________________________________________________________________________
# Declare variables

i_n=""
i_n_name=""
i_n_path=""
ops_x="x"
here_now="${PWD}"
rt_year=$(date '+%Y')
rt_month=$(date '+%m')
sh_name="prep-file.sh"
sh_path=$(readlink -f "${0}")
sh_root="${sh_path%\/*}"
sh_parent="${sh_root%\/*}"
sh_inventory="${sh_root}/inventory.sh"
master_root="${sh_parent}/docs"
master_inventory="${master_root}/inventory"
master_inventory_html="${master_inventory}/index.html"
master_inventory_json="${master_inventory}/index.json"
out_root="${master_root}/._./${rt_year}/${rt_month}"
out_inventory="${out_root}/inventory"
out_inventory_html="${out_inventory}/index.html"
out_inventory_json="${out_inventory}/index.json"
out_main="${out_root}/index.html"
site_main="${master_root}/index.html"

#________________________________________________________________________________
# Execute operations

## parse inputs

if [[ "${1}" =~ ^[-][hH]$ || "${1}" =~ ^[-]+help$ ]]; then
    pf_help

    exit $?
fi

while [[ "$#" -ne 0 ]]; do
    cycle_in="${1}"

    case "${cycle_in//[-]}" in
        a|all)
            ops_x="a"
            ;;
        c|compress)
            ops_x="c"
            ;;
        *)
            i_n="${1}"
            i_n_name="${i_n//*\/}"
            i_n_path=$(readlink -f "${i_n}")

            if [[ -d "${i_n_path}" ]]; then
                pf_vbs "ERROR: Input must be a valid FILE (not a directory): ${1}"
                pf_vbs "Use '--help' for more information"

                exit 1
            fi

            if [[ ! -f "${i_n_path}" ]]; then
                pf_vbs "ERROR: Input is NOT a valid file reference: ${1}"
                pf_vbs "Use '--help' for more information"

                exit 1
            fi
            ;;
    esac

    shift 1

done

## check if all requirements are defined at this point

if [[ "x${i_n}" == "x" ]]; then
    pf_vbs "ERROR: Target file UNDEFINED"
    pf_vbs "Use '--help' for more information"

    exit 1
fi

## set final variables

i_n_hash=$(pf_hash)
out_dir="${out_root}/${i_n_hash}"
out_zip="${out_dir}/dl.zip"
out_fil="${out_dir}/${i_n_name}"

## begin processing the input file

pf_make

case "${ops_x}" in
    a)
        pf_compress
        pf_plain

        e_c="$?"

        echo "${out_zip}"
        echo "${out_fil}"
        ;;
    c)
        pf_compress

        e_c="$?"

        echo "${out_zip}"
        ;;
    x)
        pf_plain

        e_c="$?"

        echo "${out_fil}"
        ;;
esac

## update the localized inventory listing

pf_inventory

exit ${e_c}

#________________________________________________________________________________
