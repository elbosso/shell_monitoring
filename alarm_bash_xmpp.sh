#!/bin/sh
# shellcheck disable=SC2181,SC2002,SC2039
###################################################################################
#Copyright (c) 2012-2018.
#
#Juergen Key. Alle Rechte vorbehalten.
#
#Weiterverbreitung und Verwendung in nichtkompilierter oder kompilierter Form,
#mit oder ohne Veraenderung, sind unter den folgenden Bedingungen zulaessig:
#
#   1. Weiterverbreitete nichtkompilierte Exemplare muessen das obige Copyright,
#die Liste der Bedingungen und den folgenden Haftungsausschluss im Quelltext
#enthalten.
#   2. Weiterverbreitete kompilierte Exemplare muessen das obige Copyright,
#die Liste der Bedingungen und den folgenden Haftungsausschluss in der
#Dokumentation und/oder anderen Materialien, die mit dem Exemplar verbreitet
#werden, enthalten.
#   3. Weder der Name des Autors noch die Namen der Beitragsleistenden
#duerfen zum Kennzeichnen oder Bewerben von Produkten, die von dieser Software
#abgeleitet wurden, ohne spezielle vorherige schriftliche Genehmigung verwendet
#werden.
#
#DIESE SOFTWARE WIRD VOM AUTOR UND DEN BEITRAGSLEISTENDEN OHNE
#JEGLICHE SPEZIELLE ODER IMPLIZIERTE GARANTIEN ZUR VERFUEGUNG GESTELLT, DIE
#UNTER ANDEREM EINSCHLIESSEN: DIE IMPLIZIERTE GARANTIE DER VERWENDBARKEIT DER
#SOFTWARE FUER EINEN BESTIMMTEN ZWECK. AUF KEINEN FALL IST DER AUTOR
#ODER DIE BEITRAGSLEISTENDEN FUER IRGENDWELCHE DIREKTEN, INDIREKTEN,
#ZUFAELLIGEN, SPEZIELLEN, BEISPIELHAFTEN ODER FOLGENDEN SCHAEDEN (UNTER ANDEREM
#VERSCHAFFEN VON ERSATZGUETERN ODER -DIENSTLEISTUNGEN; EINSCHRAENKUNG DER
#NUTZUNGSFAEHIGKEIT; VERLUST VON NUTZUNGSFAEHIGKEIT; DATEN; PROFIT ODER
#GESCHAEFTSUNTERBRECHUNG), WIE AUCH IMMER VERURSACHT UND UNTER WELCHER
#VERPFLICHTUNG AUCH IMMER, OB IN VERTRAG, STRIKTER VERPFLICHTUNG ODER
#UNERLAUBTE HANDLUNG (INKLUSIVE FAHRLAESSIGKEIT) VERANTWORTLICH, AUF WELCHEM
#WEG SIE AUCH IMMER DURCH DIE BENUTZUNG DIESER SOFTWARE ENTSTANDEN SIND, SOGAR,
#WENN SIE AUF DIE MOEGLICHKEIT EINES SOLCHEN SCHADENS HINGEWIESEN WORDEN SIND.
###################################################################################
#Resultatsdatei: in dieser Datei stehen Zeile für Zeile die Fehlermeldung der unterschiedlichen Skripte
#das bedeutet: die Ausgaben der Skripte auf stdout
RESULTFILE=/tmp/monitoring_results.txt
#Spielraum: Wenn der Zeitstempel in $RESULTFILE älter ist als der hier angegebene wert (in Sekunden)
#wird trotzdem ein Fehler gemeldet, da offenbar das Monitoring-Skript nicht mehr ausgeführt wird.
ALLOWEDLAG=300

#Server des Kontos, das zum Versenden der Monitoring-Nachrichten verwendet werden soll
JABBERSERVER=jabber.de
#Username des Kontos, das zum Versenden der Monitoring-Nachrichten verwendet werden soll
SENDERUSER=user
#Passwort des Kontos, das zum Versenden der Monitoring-Nachrichten verwendet werden soll
SENDERTOKEN=password
#ID des Empfängers der Alarmmeldungen
RECEIVER=receiver

lastResult=$(cat $RESULTFILE|sed 's/_/ /g')

#echo $lastResult >&2

lastPersistentDate=$(date --date="$lastResult" +"%F %T")

#echo $lastPersistentDate >&2

if [ $? -ne 0 ]; then
	echo "error condition detected" >&2
	echo -n "$lastResult"|sendxmpp -j ${JABBERSERVER} -u ${SENDERUSER} -p ${SENDERTOKEN} -t --tls-ca-path="/etc/ssl/certs" ${RECEIVER}
else
	ts=$(date --date="$lastPersistentDate" +%s)
	now=$(date +%s)
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
