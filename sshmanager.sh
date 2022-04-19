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

function list_connections() # size, ...names, ...address
{
  local function_arguments=($@)

  local size="$1"
  local name=(${function_arguments[@]:1:$size})
  local address=(${function_arguments[@]:1+$size})

  if [ $size = 0 ] ; then
    echo
    echo "There are no servers!" >&2
    exit 1
  else
    for (( i = 0; i < $size; ++i ))
      do
        printf "%s\t%s\n" "${name[i]}" "${address[i]}" | expand -t 30
      done
  fi
}

function add_connection() # size, ...names
{
  local function_arguments=($@)

  local size="$1"
  local names=(${function_arguments[@]:1})

  printf "server name: "
  read -r name
  printf "user: "
  read -r user
  printf "IP address: "
  read -r address

  if [[ " ${names[*]} " =~ " ${name} " ]]; then
      echo
      echo "[ERROR] This name is already used!" >&2
      exit 1
  else
    printf "\n$name $user $address" >> "$HOME/.sshrc"
  fi
}

function remove_connection() # size, ...names, ...users, ...addresses
{
  local function_arguments=($@)

  local size="$1"
  local names=(${function_arguments[@]:1:$size})
  local users=(${function_arguments[@]:1+$size:1+2*$size})
  local addresses=(${function_arguments[@]:1+2*$size})

  printf "server name: "
  read -r name

  if [[ " ${names[*]} " =~ " ${name} " ]]; then
    rm "$HOME/.sshrc"
    touch "$HOME/.sshrc"

    for (( i = 0; i < $size; ++i ))
    do
      if [ "$name" != "${names[i]}" ] ; then
        printf "\n${names[i]} ${users[i]} ${addresses[i]}" >> "$HOME/.sshrc"
      fi
    done

    echo
    echo "Removed ${name}!"
  else
    echo
    echo "[ERROR] There is no server with name ${name}!" >&2
    exit 1
  fi
}

function update_connection() # size, ...names, ...users, ...addresses
{
  local function_arguments=($@)

  local size="$1"
  local names=(${function_arguments[@]:1:$size})
  local users=(${function_arguments[@]:1+$size:1+2*$size})
  local addresses=(${function_arguments[@]:1+2*$size})

  printf "server name: "
  read -r name
  printf "new user: "
  read -r user
  printf "new IP address: "
  read -r address

  if [[ " ${names[*]} " =~ " ${name} " ]]; then
    rm "$HOME/.sshrc"
    touch "$HOME/.sshrc"

    for (( i = 0; i < $size; ++i ))
    do
      if [ "$name" != "${names[i]}" ] ; then
        printf "\n${names[i]} ${users[i]} ${addresses[i]}" >> "$HOME/.sshrc"
      else
        printf "\n$name $user $address" >> "$HOME/.sshrc"
      fi
    done

    echo
    echo "Updated ${name}!"
  else
    echo
    echo "[ERROR] There is no server with name ${name}!" >&2
    exit 1
  fi
}

touch "$HOME/.sshrc"
declare -a name=( $(cut -d " " -f1 $HOME/.sshrc) )
declare -a user=( $(cut -d " " -f2 $HOME/.sshrc) )
declare -a address=( $(cut -d " " -f3 $HOME/.sshrc) )

if [ "$1" = "list" ] ; then
  list_connections "${#name[@]}" "${name[@]}" "${address[@]}"
elif [ "$1" = "add" ] ; then
  add_connection "${#name[@]}" "${name[@]}"
elif [ "$1" = "remove" ] ; then
  remove_connection "${#name[@]}" "${name[@]}" "${user[@]}" "${address[@]}"
elif [ "$1" = "update" ] ; then
  update_connection "${#name[@]}" "${name[@]}" "${user[@]}" "${address[@]}"
elif [ "$#" = 0 ] ; then
  selected_item=0

  run_menu "${#name[@]}" "$selected_item" "${name[@]}" "${address[@]}"
  menu_result="$?"

  echo
  printf "Connecting to ${name[$menu_result]}...\n"
  ssh "${user[$menu_result]}"@"${address[$menu_result]}"
else
  echo
  echo "[ERROR] Wrong arguments!" >&2
  exit 1
fi