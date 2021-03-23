#!/bin/bash
TMPFILE="/root/tmp.json"
V2RAYFILE="/etc/v2ray/config.json"
_banner () {
  echo "==================================="
  echo "=      CREATED BY @CHUDOBARA      ="
  echo "==================================="
}
display_uuid () {
  printf "\033[1;32mSU/S UUID ACTIVOS:\033[0m\n"
  x=0
  for i in $(jq -r ".inbounds[].settings.clients[].id" $V2RAYFILE)
  do
    printf "[\033[1;32m${x}\033[0m]\033[1;36m ${i}\033[0m\n"
    x=$((x+1))
  done
  printf "\n\n"
}
ask_end () {
  read -r -p "$(printf '\033[1;32mSEGURO QUE DESEA CONTINUAR? \033[1;33m\033[1;32m[s/n] \033[1;33m\n')" CONFEXIT
  case $CONFEXIT in  
    s|S) clear
    start_run ;; 
    n|N) printf '\033[1;32mOKAY exiting... \033[1;33m\n'
      sleep 2
      exit
      ;; 
    *) printf "\033[1;31mRESPUESTA INVALIDA. ELIJA s/n\033[0m\n"
      sleep 2
      clear
      start_run
      ;; 
  esac

}
display_menu () {
  printf "\033[1;32m-- MENU --\033[0m\n"
  printf "[\033[1;32m1\033[0m]\033[1;36m AGREGAR USUARIO\033[0m\n"
  printf "[\033[1;32m2\033[0m]\033[1;36m ELIMINIAR USUARIO\033[0m\n"
  printf "[\033[1;32m2\033[0m]\033[1;36m MOSTRAR VMESS\033[0m\n"
  printf "[\033[1;32m3\033[0m]\033[1;36m SALIR\033[0m\n"
}
DoDelete_uuid () {
  jq 'del(.inbounds[].settings.clients['"$1"'])' $V2RAYFILE >> $TMPFILE
  cat $TMPFILE > $V2RAYFILE
  rm $TMPFILE
  printf "\033[1;32mECHO\033[0m\n"
  systemctl restart v2ray &>/dev/null
  sleep 2
  if [[ "$ASKCONTINUE" == "true" ]]
  then
    ask_end
  fi
}
delete_uuid () {
  _banner
  display_uuid
  read -r -p "$(printf '\033[1;32mSEGURO QUE QUIERE ELIMINAR? \033[1;33m\n')" DELINPUT
  re='^[0-9]+$'
  if ! [[ $DELINPUT =~ $re ]] ; then
    printf "\033[1;31mELECCION INVALIDA. SOLO COLOQUE NUMEROS\033[0m\n"
    sleep 2
    clear
    delete_uuid
  fi
  if [[ $(jq -r ".inbounds[].settings.clients[$DELINPUT].id" $V2RAYFILE) == null ]]
  then
    printf "\033[1;31mELECCION INVALIDA\033[0m\n"
    sleep 2
    clear
    delete_uuid
  else
    printf "\033[1;32mESTA SEGURO DE ELIMINAR ESTE UUID ? \033[1;36m"$(jq -r ".inbounds[].settings.clients[$DELINPUT].id" $V2RAYFILE) "\033[1;33m\n"
    read -r -p "$(printf '\033[1;32m[s/n] \033[1;33m\n')" DELCONFINPUT
    case $DELCONFINPUT in  
      s|S) DoDelete_uuid "$DELINPUT" ;; 
      n|N) printf '\033[1;32mOKAY \033[1;33m\n'
        sleep 2
        clear
        start_run
        ;; 
      *) printf "\033[1;31mRESPUESTA INVALIDA. ELIJA s/n\033[0m\n"
        sleep 2
        clear
        delete_uuid
        ;; 
    esac
  fi  
}
set_exp_date () {
  result=$(get_exp_date "${OPTEXP}")
  croncmd="phcv2raymanager -d -u ${1} && ( crontab -l | grep -v -F 'phcv2raymanager -d -u ${1}') | crontab -"
  cronjob="${result} * $croncmd"
  ( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -
}
DoUUIDAdd (){
  jq '.inbounds[].settings.clients[.inbounds[].settings.clients| length] |= . + {"id": "'"${1}"'","level": 1,"alterId": 64}' $V2RAYFILE >> $TMPFILE
  cat $TMPFILE > $V2RAYFILE
  rm $TMPFILE
  systemctl restart v2ray &>/dev/null
  if [[ "$OPTEXPA" == "true" ]]
  then
    set_exp_date "${1}"
  fi
  sleep 2
  if [[ "$ASKCONTINUE" == "true" ]]
  then
    ask_end
  fi
}
add_existing_uuid () {
  read -r -p "$(printf '\033[1;32mINGRESE UUID \033[1;33m\n')" UUIDINP
  read -r -p "$(printf '\033[1;32mQUIERE AGREGAR FECHA DE EXPIRACION? [s/n]\033[1;33m\n')" ASKFOREXPDATE
  case $ASKFOREXPDATE in

    s|S)
      read -r -p "$(printf '\033[1;32mCUANTOS DIAS?\033[1;33m\n')" INPEXPDATE
      if [[ -n ${input//[0-9]/} ]]; then
        printf "\033[1;31mINVALID CHOICE\033[0m\n"
        sleep 2
        clear
        add_existing_uuid
      else
        OPTEXPA="true"
        OPTEXP=$INPEXPDATE
        DoUUIDAdd "$UUIDINP"
      fi  
      ;;

    n|N)
      DoUUIDAdd "$UUIDINP"
      ;;

    *)
      printf "\033[1;31mELECCION INVALIDA\033[0m\n"
      sleep 2
      clear
      add_existing_uuid
      ;;
  esac
}
add_generated_uuid () {
  TheUUID=$(curl -skL -w "\n" https://www.uuidgenerator.net/api/version4)
  printf "\033[1;33mYour UUID Code:\033[1;36m $TheUUID\033[0m\n"
  read -r -p "$(printf '\033[1;32mQUIERE AGREGAR FECHA DE EXPIRACION? [s/n]\033[1;33m\n')" ASKFOREXPDATE
  case $ASKFOREXPDATE in

    s|S)
      read -r -p "$(printf '\033[1;32mCUANTOS DIAS? \033[1;33m\n')" INPEXPDATE
      if [[ -n ${input//[0-9]/} ]]; then
        printf "\033[1;31mELECCION INVALIDA\033[0m\n"
        sleep 2
        clear
        add_generated_uuid
      else
        OPTEXPA="true"
        OPTEXP=$INPEXPDATE
        DoUUIDAdd "$TheUUID"
      fi  
      ;;

    n|N)
      DoUUIDAdd "$TheUUID"
      ;;

    *)
      printf "\033[1;31mELECCION INVALIDA\033[0m\n"
      sleep 2
      clear
      add_generated_uuid
      ;;
  esac
}
add_uuid () {
  clear
  _banner
  printf "\033[1;32m-- MENU --\033[0m\n"
  printf "[\033[1;32m1\033[0m]\033[1;36m AGREAGAR UUID EXISTENTE\033[0m\n"
  printf "[\033[1;32m2\033[0m]\033[1;36m GENERAR NUEVO\033[0m\n"
    read -r -p "$(printf '\033[1;32mque quieres hacer? \033[1;33m\n')" ADDINPUT


  case $ADDINPUT in

    1)
      add_existing_uuid
      ;;

    2)
      add_generated_uuid
      ;;

    *)
      printf "\033[1;31mELLECION INVALIDA\033[0m\n"
      sleep 2
      clear
      add_uuid
      ;;
  esac
}
start_run(){
  _banner
  display_uuid
  display_menu
  read -r -p "$(printf '\033[1;32mque quieres hacer? \033[1;33m\n')" INPUT


  case $INPUT in

    1)
      printf '\033[1;32mOKAY \033[1;33m\n'
      add_uuid
      ;;

    2)
      printf '\033[1;32mOKAY \033[1;33m\n'
      sleep 2
      clear
      delete_uuid
      ;;
    3)  cat v2ray_info.inf
      ;;
    4)
      printf '\033[1;32mOKAY \033[1;33m\n'
      sleep 2
      exit
      ;;

    *)
      printf "\033[1;31mELECCION INVALIDA\033[0m\n"
      sleep 2
      clear
      _banner
      start_run
      ;;
  esac
}

delete_uuid_by_id () {
  x=0
  for i in $(jq '.inbounds[].settings.clients[].id' $V2RAYFILE)
  do 
    if [[ "$i" == '"'$1'"' ]]
    then
      break
    else
      x=$((x+1))
    fi
  done
  DoDelete_uuid $x
}
get_exp_date () {
  NEW_expration_DATE=$(date -d "+${1} days" +'%d:%m')
  exp=(${NEW_expration_DATE//:/ })
  mm=${exp[1]}
  dd=${exp[0]}
  if [[ "${dd:0:1}" == 0 ]]
  then
    dd=${dd/0/''}
  fi
  if [[ "${mm:0:1}" == 0 ]]
  then
    mm=${mm/0/''}
  fi
  echo "0 0 ${dd} ${mm}"
}
print_help () {
  clear
  echo "===================================="
  echo "-a = Add UUID  - flag only"
  echo "-d = Delete UUID - flag only"
  echo "-u = UUID  - need string after the flag"
  echo "-r = Random  - flag only"
  echo "-h = Help - flag only"
  echo "-n = Number - need int after the flag"
  echo "===================================="
  echo "when -a is raise -u or -r required"
  echo "when -d is raise -n or -u required"
  echo "when -h is raise -a and -d must not active"
  echo "===================================="
}
while getopts "a d r h n:u:e:" opt; do
  case "${opt}" in
    a) OPTADD="true" ;;
    d) OPTDEL="true" ;;
    u) 
      OPTUUIDA="true"
      OPTUUID=$OPTARG ;;
    r) OPTRAND="true" ;;
    h) OPTHELP="true" ;;
    n) 
      OPTNA="true"
      OPTN=$OPTARG ;;
    e) 
      OPTEXPA="true"
      OPTEXP=$OPTARG ;;
  esac
done

ASKCONTINUE="false"
if [[ "$OPTADD" == "true" ]] && [[ "$OPTDEL" == "true" ]] && [[ "$OPTHELP" == "true" ]]
then
  echo "-a and -d -h cannot raise at the same time"
elif [[ "$OPTADD" == "true" ]] && [[ "$OPTDEL" == "true" ]]
then
  print_help
elif [[ "$OPTADD" == "true" ]] && [[ "$OPTHELP" == "true" ]]
then
  print_help
elif [[ "$OPTHELP" == "true" ]] && [[ "$OPTDEL" == "true" ]]
then
  print_help
elif [[ "$OPTADD" == "true" ]]
then
  if [[ "$OPTRAND" == "true" ]] && [[ "$OPTUUIDA" == "true" ]]
  then
    echo "-r and -u cannot raise at the same time"
  elif [[ "$OPTRAND" == "true" ]]
  then
    add_generated_uuid
  elif [[ "$OPTUUIDA" == "true" ]]
  then
    DoUUIDAdd "$OPTUUID"
  else
    print_help
  fi
elif [[ "$OPTDEL" == "true" ]]
then
  if [[ "$OPTNA" == "true" ]]
  then
    DoDelete_uuid "$OPTN"
  elif [[ "$OPTUUIDA" == "true" ]]
  then
    delete_uuid_by_id "$OPTUUID"
  else
    print_help
  fi
elif [[ "$OPTHELP" == "true" ]]
then
  print_help
else
  ASKCONTINUE="true"
  start_run
fi
