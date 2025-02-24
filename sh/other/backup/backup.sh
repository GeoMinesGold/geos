#!/usr/bin/env bash
source main
src file

source_dirs=("${HOME}/Documents/bin")
backup_dir=("${HOME}/Documents/bac")

name='Laptop'
backup_name="${backup_dir}/Backup ${name}"
latest_dir="${backup_name}/Latest"

version_file="$(rm_slash "${LOCAL_DIR}/${backup_name##${backup_dir}/}/version")"

chk_fl "${version_file}" || { crt "${version_file}" && echo '0' > "${version_file}"; }
version="$(<"${version_file}")"
((version++))

# Create or update Latest directory
update_latest_symlink() {
    local file="${1}"
    local dest_file="${2}"
    
    # Create the destination directory for the symlink in the Latest folder
    local latest_dest_dir="$(rm_slash "${latest_dir}/$(get_dir "${file}")")"
    mkdir -p "${latest_dest_dir}"
    
    # Create or update the symlink
    ln -sf "${dest_file}" "$(rm_slash "${latest_dest_dir}/$(basename "${file}")")"
}

for dir in "${source_dirs[@]}"; do
    mapfile -t source_files < <(find "${dir}" -type f)

    for file in "${source_files[@]}"; do
        if chk_ex "${file}" "${backup_name}"; then
            continue
        fi

        dest_dir="$(rm_slash "${backup_name}/Version ${version}/$(get_dir "${file}")")"
        mkdir -p "${dest_dir}"
        dest_file="$(rm_slash "${dest_dir}/$(basename "${file}")")"

        cp -Lvir "${file}" "${dest_dir}"
        update_latest_symlink "${file}" "${dest_file}"
    done
done

echo "${version}" > "${version_file}"
