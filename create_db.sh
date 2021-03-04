#!/usr/bin/env  bash

# shell options
#set -x
#set -v
set -e
set -u
set -f

# magic variables
declare -r OPTS="htsp"
declare -a TIMESTAMPS
declare -a OPTIONS=(false false false)
declare -r -a DATABASES=(test_db support_db pipeline_db)
declare -r -a TESTER=(Tina Robert)
declare -r -a SUPPORTER=(Jennifer Mary Tom)
declare -r -a STAGES=(S1 S2 S3)
declare -r -a BUILD=(SUCCESS FAILURE ABORTED)
declare -r -i SUCCESS=0
declare -r -i BAD_ARGS=85
declare -r -i NO_ARGS=86

# functions
function usage() {
  local count
  local file_name=$(basename "$0")

  printf "Usage: %s [options...]\n" "$file_name"
  for (( count=1; count<${#OPTS}; count++ )); do
    printf "%s\tcreate %s and content\n" "-${OPTS:$count:1}" "${DATABASES[$count - 1]}"
  done
  exit "$SUCCESS"
}

function bad_args() {
  printf "Error: Wrong arguments supplied\n"
  usage
  exit "$BAD_ARGS"
}

function no_args() {
  printf "Error: No options were passed\n"
  usage
  exit "$NO_ARGS"
}

function create_timestamp_array() {
  local counter=1
  local timestamp

  while [ "$counter" -le 30 ]; do
    timestamp=$(date -v -"$counter"d +"%s")
    TIMESTAMPS+=("$timestamp")
    ((counter++))
  done
}

function curl_post() {
  local url=$(printf 'http://10.0.1.4:8086/write?db=%s&precision=s' "$2")

  curl -i -X POST "$url" --data-binary "$1"
}

function create_test_results() {
  local passed
  local failed
  local skipped
  local count
  local str

  for count in "${TESTER[@]}"; do
    passed=$((RANDOM % 30 + 20))
    failed=$((RANDOM % passed))
    skipped=$((passed - failed))
    str=$(printf 'suite,app=demo,qa=%s passed=%i,failed=%i,skipped=%i %i' "$count" "$passed" "$failed" "$skipped" "$1")
    echo "$2: $str"
    curl_post "$str" "$2"
  done
}

function create_support_results() {
  local items=(1 2 none)
  local in
  local out
  local str
  local count

  for count in "${SUPPORTER[@]}"; do
    in=$((RANDOM % 25))
    out=$((RANDOM % 25))
    str=$(printf 'tickets,support=%s in=%i,out=%i %i' "$count" "$in" "$out" "$1")
    echo "$2: $str"
    curl_post "$str" "$2"
  done
}

function create_pipeline_results() {
  local status
  local duration
  local str
  local count

  for count in "${STAGES[@]}"; do
    status=${BUILD[$RANDOM % ${#BUILD[@]} ]}
    duration=$(( 3+RANDOM%(3-17) )).$(( RANDOM%999 ))
    str=$(printf 'pipeline,stage=%s status="%s",duration=%s %i' "$count" "$status" "$duration" "$1")
    echo "$2: $str"
    curl_post "$str" "$2"
  done
}

function main() {
  local repeat=$(printf '=%.0s' {1..80})

  create_timestamp_array

  for ((i = 0; i < ${#OPTIONS[@]}; ++i)); do
    if [[ "${OPTIONS[$i]}" == "true" ]]; then
      printf "Create database: %s\n" "${DATABASES[$i]}"
      printf "%s\n" "$repeat"
      curl -i -X POST http://10.0.1.4:8086/query --data-urlencode "q=CREATE DATABASE ${DATABASES[$i]}"
      printf "Generate content of database: %s\n" "${DATABASES[$i]}"
      printf "%s\n" "$repeat"
      for item in "${TIMESTAMPS[@]}"; do
        if [[ "${DATABASES[$i]}" == "${DATABASES[0]}" ]]; then
          create_test_results "$item" "${DATABASES[$i]}"
        fi
        if [[ "${DATABASES[$i]}" == "${DATABASES[1]}" ]]; then
          create_support_results "$item" "${DATABASES[$i]}"
        fi
        if [[ "${DATABASES[$i]}" == "${DATABASES[2]}" ]]; then
          create_pipeline_results "$item" "${DATABASES[$i]}"
        fi
      done
    fi
  done
}

# script arguments
while getopts "$OPTS" OPTION; do
  case "$OPTION" in
    h)
        usage;;
    t)
        OPTIONS[0]="true";;
    s)
        OPTIONS[1]="true";;
    p)
        OPTIONS[2]="true";;
    *)
        bad_args;;
  esac
done

if [ $OPTIND -eq 1 ]; then
  no_args
fi

# main function
main

# exit
exit "$SUCCESS"