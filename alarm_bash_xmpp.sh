#!/bin/sh

#Resultatsdatei: in dieser Datei stehen Zeile für Zeile die Fehlermeldung der unterschiedlichen Skripte
#das bedeutet: die Ausgaben der Skripte auf stdout
RESULTFILE=/tmp/monitoring_results.txt
#Spielraum: Wenn der Zeitstempel in $RESULTFILE älter ist als der hier angegebene wert (in Sekunden)
#wird trotzdem ein Fehler gemeldet, da offenbar das Monitoring-Skript nicht mehr ausgeführt wird.
ALLOWEDLAG=300

#Server des Kontos, das zum Versenden der Monitoring-Nachrichten verwendet werden soll
JABBERSERVER=jabber.de
#Username des Kontos, das zum Versenden der Monitoring-Nachrichten verwendet werden soll
SENDERUSER=<user>
#Passwort des Kontos, das zum Versenden der Monitoring-Nachrichten verwendet werden soll
SENDERTOKEN=<password>
#ID des Empfängers der Alarmmeldungen
RECEIVER=<receiver>

lastResult=`cat $RESULTFILE|sed 's/_/ /g'`

#echo $lastResult >&2

lastPersistentDate=`date --date="$lastResult" +"%F %T"`

#echo $lastPersistentDate >&2

if [ $? -ne 0 ]; then
	echo "error condition detected" >&2
	echo -n "$lastResult"|sendxmpp -j ${JABBERSERVER} -u ${SENDERUSER} -p ${SENDERTOKEN} -t --tls-ca-path="/etc/ssl/certs" ${RECEIVER}
else
	ts=`date --date="$lastPersistentDate" +%s`
	now=`date +%s`
#	echo $ts $now >&2
	diffSec=$((now-ts))
#	echo $diffSec >&2
	if [ $diffSec -lt $ALLOWEDLAG ]; then 
		echo "no error condition detected" >&2
	else 
		echo "timestamp too old!" >&2
		echo -n "timestamp too old (${lastResult})!"|sendxmpp -j ${JABBERSERVER} -u ${SENDERUSER} -p ${SENDERTOKEN} -t --tls-ca-path="/etc/ssl/certs" ${RECEIVER}
	fi
fi
