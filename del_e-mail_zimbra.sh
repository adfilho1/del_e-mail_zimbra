#!/bin/bash
#
# del_e-mail_zimbra.sh - Utilizado para remover mensagens das caixas dos usuários.
#
# Website:       https://br.linkedin.com/in/adfilho1
# Author:        Adalberto Ramos Filho
# Maintenance:   Adalberto Ramos Filho
#
# ------------------------------------------------------------------------ #
# WHAT IT DOES?
# This script can be called by the normal way using "./" or scheduled to execute through Cron.
# You have to change the variables to point to your External Device.
#
# CONFIGURATION?
# I recommend you to create a softlink to folder that is available on $PATH variable.
# $ ln -s /srv/scripts/del_e-mail_zimbra.sh /usr/local/bin/del_e-mail_zimbra.sh
#
# HOW TO USE IT?
# Examples:
# $ ./del_e-mail_zimbra.sh file.csv
#
# or
#
# 30 21 * * * zimbra del_e-mail_zimbra.sh file.csv 1> /dev/null 2>&1
# ------------------------------------------------------------------------ #
# Changelog:
#
#   v1.0 24/09/2020, Adalberto Ramos Filho:
#     BR - Primeira versão e comentários!
#     US - First version with comments!
#   v2.0 09/10/2020, Adalberto Ramos Filho:
#     BR - Obtem os dados de remetente, destinatários, data e assunto através de arquivo csv
#     BR - Inclusão dos aliases de contas e listas na checagem
#     US - Obtaining the data of sender, recipients, date and subject through csv file
#     US - Inclusion of account and list aliases in the check
#
# ------------------------------------------------------------------------ #
# Tested on:
#   bash 4.2.37(1)-release (x86_64-pc-linux-gnu)
# ------------------------------------------------------------------------ #

# -------------------------------VARIABLES----------------------------------------- #
# You may change
FILECSV=$1
REMETENTE=""
DESTINATARIOS=""
DATE=""
SUBJECT=""
TESTE=""

LOG="/srv/backup/zimbra/tmp/remocao-contas-$(date +%Y%m%d%H%M)"
ZMPROV="/opt/zimbra/bin/zmprov"
ZMMAILBOX="/opt/zimbra/bin/zmmailbox"
ZMACCTS="/opt/zimbra/bin/zmaccts"
ZMACCTS_FILE="/srv/backup/zimbra/tmp/remocao-contas-$(date +%Y%m%d%H%M)-zmaccts"
ZMALIASES_FILE="/srv/backup/zimbra/tmp/accountAliases"
ZMGADL_FILE="/srv/backup/zimbra/tmp/remocao-contas-$(date +%Y%m%d%H%M)-zmgadl"


# -------------------------------TESTS------------------------------------ #
# Is zimbra?
[ "$UID" != "500" ] && {
  echo "---------- You must be zimbra ----------"
  echo "saindo!"
  echo "---------- You must be zimbra ----------" >> $LOG
  exit 1
}
# ------------------------------------------------------------------------ #

# -------------------------------FUNCTIONS-------------------------------- #
preparelogfile () {
  # Insert a simple header to the log file with the timestamp
  echo "----------[ $(date) ]----------" >> $LOG
}

prepara_arquivos () {
# Obtem a lista atual de contas
$ZMACCTS > $ZMACCTS_FILE
# Obtem a lista atual de aliases das contas
$ZMPROV -l gaa -v | grep -e zimbraMailAlias  | awk '{print $2}' > $ZMALIASES_FILE
# Adiciona a relacao de aliases das contas
cat $ZMALIASES_FILE >> $ZMACCTS_FILE
# Obtem a lista atual de listas e seus aliases
$ZMPROV -l gadl -v | grep -e zimbraMailAlias | awk '{print $2}' | sort -h | uniq > $ZMGADL_FILE

}

obtem_dados () {

cat $FILECSV | egrep -v "Timestamp" | while read LINE ;
do
  DIA=$(echo $LINE | cut -d',' -f1 | sed -s 's/\;/\n/g' | sort -h | uniq | cut -d \" -f2 | awk '{print $1}')
  if [ $DIA -lt 10 ] ; then DIA=$(echo 0$DIA) ; fi
  MES=$(echo $LINE | cut -d',' -f1 | sed -s 's/\;/\n/g' | sort -h | uniq | cut -d \" -f2 | awk '{print $3}')
  case $MES in
    Janeiro)    MES="01" ;;
    Fevereiro)  MES="02" ;;
    Março)      MES="03" ;;
    Abril)      MES="04" ;;
    Maio)       MES="05" ;;
    Junho)      MES="06" ;;
    Julho)      MES="07" ;;
    Agosto)     MES="08" ;;
    Setembro)   MES="09" ;;
    Outubro)    MES="10" ;;
    Novembro)   MES="11" ;;
    Dezembro)   MES="12" ;;
    *)                   ;;
  esac
  ANO=$(echo $LINE | cut -d',' -f1 | sed -s 's/\;/\n/g' | sort -h | uniq | cut -d \" -f2 | awk '{print $5}')
  DATE=$(echo "${DIA}/${MES}/${ANO}")
  REMETENTE=$(echo $LINE | cut -d',' -f2 | sed -s 's/\;/\n/g' | sort -h | uniq)
  SUBJECT=$(echo $LINE | cut -d',' -f4 | sed -s 's/\;/\n/g' | sort -h | uniq | cut -d \" -f2)
  echo $LINE | cut -d',' -f3 | sed -s 's/\;/\n/g' | sort -h | uniq | while read CONTA ;
  do
    testa_conta $CONTA
  done
done

}

tipo_exec () {

echo "Executar em modo teste Sim ou Não?"
read RESPONSE1
if [[ "$RESPONSE1" =~ ^(sim|s|SIM|Sim|S)$ ]] ; then
  TESTE="1"
else
  TESTE="0"
fi

}

apaga () {

$ZMMAILBOX -z -m $1 s -t message -l 1000 "from:$REMETENTE subject:\"${SUBJECT}\" date:${DATE}" | egrep "mess" | awk '{print $2}' | while read ID_MESS
  do
  if [ "$TESTE" -eq "0" ] ; then
    echo "zmmailbox -z -m $1 deleteMessage $ID_MESS" >> $LOG
    $ZMMAILBOX -z -m $1 deleteMessage $ID_MESS
  else
    echo "zmmailbox -z -m $1 deleteMessage $ID_MESS" >> $LOG
  fi
done

}

testa_conta () {

# Verifica se é uma conta
RETURN1=$(grep -wi "^$1" $ZMACCTS_FILE)
# Verifica se é uma lista
RETURN2=$(grep -wi "^$1" $ZMGADL_FILE)

if [ ! -z "$RETURN1" ] ; then
  # Se for uma conta executa remoção passando a conta como parametro
  apaga "$1"
else
  echo "$1 não é uma conta" >> $LOG
  if [ ! -z "$RETURN2" ] ; then
    # Se for uma lista obtem a relação de membros e executa remoção em cada um deles
    $ZMPROV -l gdl $1 members | egrep -v "distributionList|members|^$" | while read MEMBRO
    do
      testa_conta "$MEMBRO"
    done
  else
    echo "$1 não é uma lista" >> $LOG
  fi
fi

}

main () {

preparelogfile
tipo_exec
prepara_arquivos
obtem_dados

echo "Relatório de remoção salvo em: $LOG"

}

# Execução do script
main
