#! /usr/bin/env bash
#>--------------------------------------------------------------------------------
#>
#> [ prepfile.sh ]
#>
#>    Prep an indicated file for uploading to cdn.h8rt3rmin8r.com
#>
#>    Created on 20201214 by h8rt3rmin8r
#>
#> USAGE:
#>
#>    prepfile.sh <INPUT>
#>    prepfile.sh <OPTION>
#>    prepfile.sh <OPTION> <INPUT>
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

    zip -qq -D -j -9 -X- "dl.zip" "${i_n_path}" 2>/dev/null

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

function pf_info() {
    local i_n="${i_n_path}"
    local stt_bytes=$(wc -c "${i_n}" | cut -d ' ' -f1)
    local stt_chars=$(wc -m "${i_n}" | cut -d ' ' -f1)
    local stt_lines=$(wc -l "${i_n}" | cut -d ' ' -f1)
    local stt_lline=$(wc -L "${i_n}" | cut -d ' ' -f1)
    local stt_words=$(wc -w "${i_n}" | cut -d ' ' -f1)
    local x_open="${_sba}${_cba}"
    local x_close="${_cbb}${_sbb}"
    local x_runtime="${_q2}runtime${_q2}:${_q2}${runtime}${_q2}"
    local x_sha256="${_q2}sha256sum${_q2}:${_q2}${i_n_hash}${_q2}"
    local x_fname="${_q2}fileName${_q2}:${_q2}${i_n_name}${_q2}"
    local x_hasfile="${_q2}hasFile${_q2}:${has_plain}"
    local x_haszip="${_q2}hasZip${_q2}:${has_zip}"
    local x_sourcefile="${_q2}sourceFile${_q2}:${_q2}${out_ref_fil}${_q2}"
    local x_sourcezip="${_q2}sourceZip${_q2}:${_q2}${out_ref_zip}${_q2}"
    local x_sourcemain="${_q2}sourceMain${_q2}:${_q2}${out_ref_main}${_q2}"
    local x_sharelink="${_q2}shareLink${_q2}:${_q2}${shr_ref}${_q2}"
    local i_n_system="${x_runtime},${x_sha256},${x_fname},${x_hasfile},${x_haszip},${x_sourcefile},${x_sourcezip},${x_sourcemain},${x_sharelink}"
    local stx_bytes="${_q2}byteCount${_q2}:${_q2}${stt_bytes}${_q2}"
    local stx_chars="${_q2}characterCount${_q2}:${_q2}${stt_chars}${_q2}"
    local stx_lines="${_q2}lineCount${_q2}:${_q2}${stt_lines}${_q2}"
    local stx_lline="${_q2}longestLine${_q2}:${_q2}${stt_lline}${_q2}"
    local stx_words="${_q2}wordCount${_q2}:${_q2}${stt_words}${_q2}"
    local i_n_stats="${stx_bytes},${stx_chars},${stx_lines},${stx_lline},${stx_words}"
    local output="${x_open}${i_n_system},${i_n_stats}${x_close}"

    echo "${output}" \
        | jq -c '.' 2>/dev/null
    
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
    mkdir -p "${shr_root}"

    touch "${master_inventory_html}"
    touch "${master_inventory_json}"
    touch "${out_inventory_html}"
    touch "${out_inventory_json}"
    touch "${shr_fil}"

    if [[ ! -f "${out_main}" ]]; then
        cp "${site_main}" "${out_main}"
    fi

    eval "${sh_redirect}" "/" > "${out_rdr_a}"
    eval "${sh_redirect}" "/" > "${out_rdr_b}"
    eval "${sh_redirect}" "/" > "${out_rdr_c}"
    eval "${sh_redirect}" "${out_ref_main}" > "${shr_fil}"

    pf_info > "${out_info}"

    return $?
}

function pf_plain() {
    cp --preserve=all "${i_n_path}" "${out_fil}"

    return $?
}

function pf_random() {
        tr -dc 'a-zA-Z0-9' <"/dev/urandom" \
        | fold -w 9 \
        | head -n 1

    return $?
}

function pf_vbs() {
    local message="$@"

    echo "$(date '+%s%N')|${sh_name}|${message}" &>/dev/stderr

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

i_n=""
i_n_name=""
i_n_path=""
ops_x="x"
here_now="${PWD}"
runtime="$(date '+%s%N')"
rt_year=$(date '+%Y')
rt_month=$(date '+%m')
sh_name="prepfile.sh"
sh_path=$(readlink -f "${0}")
sh_root="${sh_path%\/*}"
sh_parent="${sh_root%\/*}"
sh_inventory="${sh_root}/inventory.sh"
sh_redirect="${sh_root}/redirect.sh"
master_root="${sh_parent}/docs"
master_inventory="${master_root}/inventory"
master_inventory_html="${master_inventory}/index.html"
master_inventory_json="${master_inventory}/index.json"
out_root="${master_root}/._./${rt_year}/${rt_month}"
out_rdr_a="${master_root}/._./index.html"
out_rdr_b="${master_root}/._./${rt_year}/index.html"
out_rdr_c=""
shr_str="$(pf_random)"
shr_ref="/.-./${shr_str}"
shr_root="${master_root}/.-./${shr_str}"
shr_fil="${shr_root}/index.html"
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
out_info="${out_root}/${i_n_hash}/info.json"
out_dir="${out_root}/${i_n_hash}"
out_zip="${out_dir}/dl.zip"
out_fil="${out_dir}/${i_n_name}"
out_ref_base="/._./${rt_year}/${rt_month}/${i_n_hash}"
out_ref_fil="${out_ref_base}/${i_n_name}"
out_ref_zip="${out_ref_base}/dl.zip"
out_rdr_c="${out_dir}/index.html"

## begin processing the input file

case "${ops_x}" in
    a)
        out_ref_main="${out_ref_fil}"
        has_plain="true"
        has_zip="true"

        pf_make
        pf_compress
        pf_plain

        e_c="$?"

        echo "${out_zip}"
        echo "${out_fil}"
        ;;
    c)
        out_ref_main="${out_ref_zip}"
        has_plain="false"
        has_zip="true"
        
        pf_make
        pf_compress

        e_c="$?"

        echo "${out_zip}"
        ;;
    x)
        out_ref_main="${out_ref_fil}"
        has_plain="true"
        has_zip="false"
        
        pf_make
        pf_plain

        e_c="$?"

        echo "${out_fil}"
        ;;
esac

## update the localized inventory listing

pf_inventory

exit ${e_c}

#________________________________________________________________________________
