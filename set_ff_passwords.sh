#!/bin/bash
profile_home=/var/log/citrix/.mozilla/firefox/
profile_folder=

get_next_login_id() {
  f_logins=$1/logins.json
  if [[ ! -f $f_logins  ]]; then
    touch $f_logins
    chmod 644 $f_logins
    echo -e '{'                                         >> $f_logins
    echo -e '  "nextId": 1,'                            >> $f_logins
    echo -e '  "logins": ['                             >> $f_logins
    echo -e '  ],'                                      >> $f_logins
    echo -e '  "potentiallyVulnerablePasswords": [],'   >> $f_logins
    echo -e '  "dismissedBreachAlertsByLoginGUID": {},' >> $f_logins
    echo -e '  "version": 3'                            >> $f_logins
    echo -e '}'                                         >> $f_logins
  fi
  echo $(jq '.nextId' logins.json)
}

create_login(){
  hostname=$1
  submitForm=$2
  username=$3
  password=$4
  id=$(get_next_login_id $profile_folder)

  login="{
       \"id\": $id,
       \"hostname\": \"$hostname\",
       \"httpRealm\": null,
       \"formSubmitURL\": \"$submitForm\",
       \"usernameField\": \"login\",
       \"passwordField\": \"passwd\",
       \"encryptedUsername\": \"$username\",
       \"encryptedPassword\": \"$password\",
       \"guid\": \"{52732626-3f18-42c0-aa89-c05ddc4e2249}\",
       \"encType\": 0,
       \"timeCreated\": $(date +%s),
       \"timeLastUsed\": $(date +%s),
       \"timePasswordChanged\": $(date +%s),
       \"timesUsed\": 0
    }"

  jq --argjson jq_logins "$login" '.logins += [$jq_logins]' $profile_folder/logins.json | sponge $profile_folder/logins.json

}

get_profile_folder(){
    echo $(iniget.sh $profile_home/profiles.ini Profile0 Path)
}

profile_folder=$(get_profile_folder)
create_login $1 $2 $3 $4
 

