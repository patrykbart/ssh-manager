#!/bin/bash

function print_menu()  # size, selected_item, ...name, ...address
{
	local function_arguments=($@)

	local size="$1"
  local selected_item="$2"
  local name=(${function_arguments[@]:2:$size})
  local address=(${function_arguments[@]:2+$size})

	for (( i = 0; i < $size; ++i ))
	do
		if [ "$i" = "$selected_item" ]
		then
			printf "[X] %s\t%s\n" "${name[i]}" "${address[i]}" | expand -t 30
		else
			printf "[ ] %s\t%s\n" "${name[i]}" "${address[i]}" | expand -t 30
		fi
	done
}

function run_menu()  # size, selected_item, ...name, ...address
{
	local function_arguments=($@)

  local size="$1"
	local selected_item="$2"
	local name=(${function_arguments[@]:2:$size})
	local address=(${function_arguments[@]:2+$size})
	local menu_limit=$((size - 1))

	clear
	print_menu "${#name[@]}" "$selected_item" "${name[@]}" "${address[@]}"
	
	while read -rsn1 input
	do
		case "$input"
		in
			$'\x1B')  # ESC ASCII code
				read -rsn1 -t 0.1 input
				if [ "$input" = "[" ]
				then
					read -rsn1 -t 0.1 input
					case "$input"
					in
						A)  # Up Arrow
							if [ "$selected_item" -ge 1 ]
							then
								selected_item=$((selected_item - 1))
								clear
								print_menu "${#name[@]}" "$selected_item" "${name[@]}" "${address[@]}"
							fi
							;;
						B)  # Down Arrow
							if [ "$selected_item" -lt "$menu_limit" ]
							then
								selected_item=$((selected_item + 1))
								clear
								print_menu "${#name[@]}" "$selected_item" "${name[@]}" "${address[@]}"
							fi
							;;
					esac
				fi
				read -rsn5 -t 0.1  # flushing stdin
				;;
			"")  # Enter key
				return "$selected_item"
				;;
		esac
	done
}

selected_item=0
declare -a name=( $(cut -d " " -f1 $HOME/.sshrc) )
declare -a user=( $(cut -d " " -f2 $HOME/.sshrc) )
declare -a address=( $(cut -d " " -f3 $HOME/.sshrc) )

run_menu "${#name[@]}" "$selected_item" "${name[@]}" "${address[@]}"
menu_result="$?"

printf "Connecting to ${name[$menu_result]}...\n"
ssh "${user[$menu_result]}"@"${address[$menu_result]}"