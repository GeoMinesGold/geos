#!/usr/bin/env bash
input_pdf="${1}"
output_pdf="${2}"

if [[ -z "${input_pdf}" ]]; then 
    echo "No input PDF, exiting"
    exit 1
fi

if [[ -z "${output_pdf}" ]]; then
    echo "No output PDF, exiting"
    exit 1
fi

clear
while true; do
echo "Input PDF: ${input_pdf}"
echo "y/n?"
read confirm
if [[ "${confirm}" = "y" ]]; then
    confirm=""
    break
elif [[ "${confirm}" = "n" ]]; then
    echo "Exiting"
    exit
else
   echo -e "\nChoose either 'y' or 'n'"
fi
done
clear

temp_dir="/home/geo/Documents/temp/$(pwgen -snc -1 9)/"
mkdir -p ${temp_dir}
temp_pdf="${temp_dir}temp.pdf"

clear
while true; do
echo "Output PDF: ${output_pdf}"
echo "y/n?"
read confirm
if [[ "${confirm}" = "y" ]]; then
    confirm=""
    break
elif [[ "${confirm}" = "n" ]]; then
    echo "Exiting"
    exit
else
   echo -e "\nChoose either 'y' or 'n'"
fi
done
clear

total_pages=$(pdfinfo "${input_pdf}" | grep "Pages:" | awk '{print $2}')
batch_size=8
batch_number=1
blank_pdf='%PDF-1.3
%¿÷¢þ
1 0 obj
<< /Metadata 3 0 R /Pages 4 0 R /Type /Catalog >>
endobj
2 0 obj
<< /Producer (pikepdf 8.15.1) >>
endobj
3 0 obj
<< /Subtype /XML /Type /Metadata /Length 448 >>
stream
<?xpacket begin="ï»¿" id="W5M0MpCehiHzreSzNTczkc9d"?>
<x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="pikepdf">
 <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
 <rdf:Description xmlns:pdf="http://ns.adobe.com/pdf/1.3/" rdf:about="" pdf:Producer="pikepdf 8.15.1"/><rdf:Description xmlns:xmp="http://ns.adobe.com/xap/1.0/" rdf:about="" xmp:MetadataDate="2024-05-25T03:49:08.821246+00:00"/></rdf:RDF>
</x:xmpmeta>

<?xpacket end="w"?>

endstream
endobj
4 0 obj
<< /Count 1 /Kids [ 5 0 R ] /Type /Pages >>
endobj
5 0 obj
<< /Contents 6 0 R /MediaBox [ 0 0 595.275591 841.889764 ] /Parent 4 0 R /Resources << >> /Type /Page >>
endobj
6 0 obj
<< /Filter /FlateDecode /Length 0 >>
stream

endstream
endobj
xref
0 7
0000000000 65535 f 
0000000015 00000 n 
0000000080 00000 n 
0000000128 00000 n 
0000000657 00000 n 
0000000716 00000 n 
0000000836 00000 n 
trailer << /Info 2 0 R /Root 1 0 R /Size 7 /ID [<448d4b98ff55c50cf2225c6c429a22d4><448d4b98ff55c50cf2225c6c429a22d4>] >>
startxref
906
%%EOF'

if (( total_pages % batch_size == 0 )); then
    expanded_size=${total_pages}
else
    expanded_size=$(( (total_pages + batch_size - 1) / batch_size * batch_size ))
fi

mapfile pages < <(seq 1 "${expanded_size}")
num_blank_pages="$((expanded_size - total_pages))"

declare -A sequences

function_reorder() {
    batch=("${@}")
    reordered_batch=()
    total_numbers=$(printf "%.0f" "${#batch[@]}")
    extra_elements=()
    midpoint=$((batch_size / 2))
    even_numbers=()
    odd_numbers=()

    if [[ "${expanded_size}" > "${total_pages}" ]]; then
        for ((i=${total_pages}+1; i<=${expanded_size}; i++)); do
            extra_elements+=("${i}")
        done
    fi

    for ((i=0; i<total_numbers; i++)); do
        position=$((i + 1))
        current_number="${batch[i]}"
        if [[ "${position}" -le "${midpoint}" ]]; then
            reordered_batch+=("${batch[((position - 1) * 2)]}")
        elif [[ "${position}" -gt "${midpoint}" ]]; then
            even_position=$((position - batch_size / 2))
            reordered_batch+=("${batch[((even_position - 1) * 2 + 1)]}")
        fi
    done

    for ((i=0; i<$midpoint; i++)); do
        odd_numbers+=("${reordered_batch[i]}")
    done
    for ((i=$midpoint; i<$total_numbers; i++)); do
        even_numbers+=("${reordered_batch[i]}")
    done

    for ((i=0; i<${#even_numbers[@]}-1; i+=2)); do
        local temp=${even_numbers[$i]}
        even_numbers[$i]=${even_numbers[$((i+1))]}
        even_numbers[$((i+1))]=$temp
    done

    reordered_batch=("${odd_numbers[@]}" "${even_numbers[@]}")

    replace_elements() {
        local -n array_name=${1}
        local replace_value=${2}

        for i in "${!array_name[@]}"; do
            if [[ ${array_name[$i]} == "$replace_value" ]]; then
                array_name[$i]='blank'
            fi
        done
    }

    for extra_element in "${extra_elements[@]}"; do
        replace_elements odd_numbers "$extra_element"
        replace_elements even_numbers "$extra_element"
        replace_elements reordered_batch "$extra_element"
    done

    sequences["seq_${batch_number}"]="${reordered_batch[*]}"
    sequences["odd_seq_${batch_number}"]="${odd_numbers[*]}"
    sequences["even_seq_${batch_number}"]="${even_numbers[*]}"

    ((batch_number++))
}

process_batch() {
    batch=("$@")
    function_reorder "${batch[@]}"
}

while [[ ${#pages[@]} -gt 0 ]]; do
    batch=("${pages[@]:0:$batch_size}")
    pages=("${pages[@]:$batch_size}")
    process_batch "${batch[@]}"
done


normal_sum=""
for ((i=1; i<batch_number; i++)); do
    key="seq_${i}"
    normal_sum+="${sequences[$key]} "
done

odd_sum=""
for ((i=1; i<batch_number; i++)); do
    odd_key="odd_seq_${i}"
    odd_sum+="${sequences[$odd_key]} "
done

even_sum=""
for ((i=1; i<batch_number; i++)); do
    even_key="even_seq_${i}"
    even_sum+="${sequences[$even_key]} "
done

reversed_even_sum=$(echo ${even_sum} | tr ' ' '\n' | tac | xargs)

odd_reversed_even_sum="${odd_sum}${reversed_even_sum}"

clear
while true; do

echo "Choose sum type:"
echo "1) Normal (Odd mixed with even)"
echo "2) Odd only"
echo "3) Even only"
echo "4) Odd + Reversed even"
echo "5) Print batch values and choose again"

read confirm
case "${confirm}" in

    1)
    echo "1) Normal chosen"
    sum="${normal_sum}"
    break
    ;;

    2)
    echo "2) Odd only chosen"
    sum="${odd_sum}"
    break
    ;;

    3)
    echo "3) Even only chosen"
    sum="${even_sum}"
    break
    ;;

    4)
    echo "4) Odd + Reversed Even Sum chosen"
    sum="${odd_reversed_even_sum}"
    break
    ;;

    5)
    clear
    echo "5) Printing batch values"
    for ((i=1; i<=batch_number; i++))
    do
        echo "Batch ${i}: ${sequences["seq_${i}"]}"
    done
    echo "Press enter to go back to selection"
    read
    clear
    ;;
    
    *)
    echo -e "\nChoose a valid sum type from the options"
    ;;
esac
done
clear
confirm=''

total="$(echo "${sum}" | awk -v temp_dir="${temp_dir}" '{ for(i=1; i<=NF; i++) $i = temp_dir $i; print }' | awk '{for(i=1;i<=NF;i++){printf "%s.pdf ", $i}}' | tr ' ' '\n')"

clear
while true; do
echo "Choose display type:"
echo "1) Sum"
echo "2) Sum with commas"
echo "3) Total"
echo "4) Continue without displaying values"

read confirm
case "${confirm}" in

    1)
    echo "1) Displaying Sum"
    echo "${sum}"
    break
    ;;

    2)
    echo "2) Displaying sum with commas"
    sum_comma="$(echo "${sum}" | awk '{$NF=""; sub(/[[:space:]]+$/, "")}1' | sed 's/ /,/g'),$(echo "${sum}" | awk '{print $(NF-0)}')"
    echo "${sum_comma}"
    break
    ;;

    3)
    echo "3) Displaying total"
    echo "${total}"
    break
    ;;
    
    4)
    echo "4) Continuing without displaying values"
    break
    ;;

    *)
    echo -e "\nChoose a valid display type from the options"
    ;;
esac
done
confirm=''

pdftk "${input_pdf}" burst output "${temp_dir}%d.pdf"
[[ ! -f "${temp_dir}blank.pdf" ]] && echo "${blank_pdf}" > "${temp_dir}blank.pdf"
pdftk $(echo ${total}) cat output "${temp_pdf}"
pdfjam "${temp_pdf}" --nup 2x2 -o "${output_pdf}"
