#!/bin/bash
#shamelessly stolen from https://stackoverflow.com/a/54597545
function iniget() {
  if [[ $# -lt 2 || ! -f $1 ]]; then
    echo "usage: iniget <file> [--list|<section> [key]]"
    return 1
  fi
  local inifile=$1

  if [ "$2" == "--list" ]; then
    for section in $(cat $inifile | grep "\[" | sed -e "s#\[##g" | sed -e "s#\]##g"); do
      echo $section
    done
    return 0
  fi

  local section=$2
  local key
  [ $# -eq 3 ] && key=$3

  # https://stackoverflow.com/questions/49399984/parsing-ini-file-in-bash
  # This awk line turns ini sections => [section-name]key=value
  local lines=$(awk '/\[/{prefix=$0; next} $1{print prefix $0}' $inifile)
  for line in $lines; do
    if [[ "$line" = \[$section\]* ]]; then
      local keyval=$(echo $line | sed -e "s/^\[$section\]//")
      if [[ -z "$key" ]]; then
        echo $keyval
      else
        if [[ "$keyval" = $key=* ]]; then
          echo $(echo $keyval | sed -e "s/^$key=//")
        fi
      fi
    fi
  done
}

iniget $1 $2 $3
