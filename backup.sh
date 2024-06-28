#!/bin/bash
exec 3>&1 1>backup.log 2>&1
set -x

function main(){
  check $@

  if [ "$b" ] && [ "$r" ]; then
	  echo "You can't backup and restore at the same time..." >&3

  elif [ "$b" ]; then
	  backup

  elif [ "$r" ]; then
	  restore

  else
   	  echo "Please enter a flag" >&3

  fi
}

function check(){
  local opt OPTIND
  while getopts ":BRIL:" opt; do
    case $opt in
       L) l=true;line_input="$OPTARG";;
       B) b=true;;
       R) r=true;;
       I) i=true;;
    esac
  done
  shift $((OPTIND -1))
}

function restore(){
  user_ip_dir_regex="([^:]*)(:)(.*)"

  mapfile -t hosts < ~/locations.cfg

  if [[ $l != true ]]; then
    INDEX=0
    for each in "${hosts[@]}"
    do
        [[ $each =~ $user_ip_dir_regex ]]

        user_ip=${BASH_REMATCH[1]}
        destination=${BASH_REMATCH[3]}

        cd ~/backups/"$INDEX"/

        last_dir_num=$(last_dir)

        ssh $user_ip "rm -r $destination; mkdir $destination"
        scp -r $last_dir_num/* ${BASH_REMATCH[0]}
        echo "$last_dir_num/* ${BASH_REMATCH[0]}"
        INDEX=$((INDEX+1))
    done
  fi

  if [[ $l == true ]]; then

      [[ ${hosts[$line_input]} =~ $user_ip_dir_regex ]]

      user_ip=${BASH_REMATCH[1]}
      destination=${BASH_REMATCH[3]}

      cd ~/backups/"$line_input"/

      last_dir_num=$(last_dir)

      ssh $user_ip "rm -r $destination; mkdir $destination"
      scp -r $last_dir_num/* ${BASH_REMATCH[0]}
  fi
}

function last_dir(){
  local largest_num folder_regex
  largest_num=0
  folder_regex="^[0-9]+"

  mapfile -t directories < <(dir -1 | grep -E -o "$folder_regex")

  if [[ $i != true ]]; then
    for each in "${directories[@]}"
    do
      if (( each > largest_file )); then
        largest_num=$each
      fi
    done
  fi

  if [[ $i == true ]]; then

    for each in "${directories[@]}"
    do
      cd "$each"
      phantom_result=$(phantom_test)
      if (( each > largest_file )) && [[ "$phantom_result" == "Clean" ]]
      then
        largest_num=$each
      fi
      cd ..
    done
  fi

  echo $largest_num
}

function backup(){
  #grabs the network information for the eth0 interface
  ip_info=$(ip address show eth0)
  #regex for an ip address
  ip_regex="[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"
  user_ip_dir_regex="([^:]*)(:)(.*)"

  #search the eth0 interface for the first ip address
  ip=$( ip address show eth0 | grep -E -o "$ip_regex" |  head -1)

  mapfile -t hosts < ~/locations.cfg

  if [[ $l != true ]]; then
    INDEX=0
    for each in "${hosts[@]}"
    do
        [[ $each =~ $user_ip_dir_regex ]]

        user_ip=${BASH_REMATCH[1]}
        destination=${BASH_REMATCH[3]}

        cd ~/backups/"$INDEX"
        last_dir_num=$(last_dir)
        new_dir=$((last_dir_num + 1))
        #ssh into target machine to copy files back here
        #ssh "$user_ip" "cd $destination; sha1sum * > $destination/.filehash.sha1; scp -r -i ~/.ssh/wsl $destination frazer@$ip:~/backups/$INDEX/$new_dir/"
        #FOLLOWING 3 LINES IS FOR TESTING CHECKSUM
        ssh "$user_ip" "cd $destination; sha1sum * > $destination/.filehash.sha1"
        sleep 20s
        ssh "$user_ip" "scp -r -i ~/.ssh/wsl $destination frazer@$ip:~/backups/$INDEX/$new_dir/"
        cd ~/backups/"$INDEX"/"$new_dir"
        verify_hash
        INDEX=$((INDEX+1))
    done
  fi

  if [[ $l == true ]]; then
    [[ ${hosts[$line_input]} =~ $user_ip_dir_regex ]]

    user_ip=${BASH_REMATCH[1]}
    destination=${BASH_REMATCH[3]}

    cd ~/backups/"$line_input"

    last_dir_num=$(last_dir)
    new_dir=$((last_dir_num + 1))
    #ssh into target machine to copy files back here
    ssh "$user_ip" "cd $destination; sha1sum * > $destination/.filehash.sha1; scp -r -i ~/.ssh/wsl $destination frazer@$ip:~/backups/$line_input/$new_dir/"
    cd ~/backups/"$line_input"/"$new_dir"
    verify_hash
  fi

}

function verify_hash(){
  hash_check_regex="([^:]*)(: )(.*)"

  mapfile -t files < <(sha1sum -c .filehash.sha1)

  for each in "${files[@]}";
  do
    [[ $each =~ $hash_check_regex ]]

    file=${BASH_REMATCH[1]}
    status=${BASH_REMATCH[3]}

    if [[ $status != "OK" ]]; then
      mv "$file" "$file".phantom
      phantom_hash=$(sha1sum "$file".phantom)
      cd ../"$last_dir_num"
      old_hash=$(sha1sum "$file")
      echo "Phantom Hash: $phantom_hash"
      echo "Old Hash: $old_hash"
      diff -a "$file" ../"$new_dir"/"$file".phantom
    fi
  done
}

function phantom_test(){
  phantom_regex=".phantom"
  file_grep=$(ls | grep "$phantom_regex")
  if [[ "$file_grep" == "" ]]; then
    echo "Clean"
  fi
}


main $@

