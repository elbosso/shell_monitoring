#!/bin/sh
# shellcheck disable=SC2003,SC2039,SC2061,SC2006
#Aufruf wie folgt: namen der ausgeführten Scripts werden in /tmp/debug.log hinterlegt
#./run-parts.sh 2> /tmp/debug.log

#entscheidet, ob bereits der erste Fehler zum Abbruch des Skripts führt (FAILONERROR=1)
#oder alle Tests durchgeführt werden, auch wenn einige davon fehlschlagen (FAILONERROR=0)
#im letztgenannten Fall ist der Returncode dieses Scripts gleichbedeutend mit der Anzahl fehlgeschlagener Tests
FAILONERROR=1
#Verzeichnis, in dem die einzelnen Testscripts stehen
#wichtig dabei ist, dass es möglich ist, ein Script erst dann einen Alarm auslösen zu lassen,
#wenn es n mal hintereinander einen Fehler geliefert hat: Dazu muss
#der Anwender eine Datei gleichen Namens in $SCRIPTDIR/leniency  ablegen:
#wird also eine Datei $SCRIPTDIR/leniency/01mem.sh mit dem Inhalt 3 erzeugt,
#bedeutet das, dass ein Alarm durch das Script
#$SCRIPTDIR/01mem.sh erst dann ausgelöst wird,
#wenn es dreimal aufeinanderfolgend fehlschlägt
SCRIPTDIR=/home/elbosso/work/scripts/monitoring/rp_scripts
#Rufgruppen:
#Verzeichnisse, die in $SCRIPTDIR stehen und deren Namen mit dem Präfix "cg_" beginnen,
#haben dasselbe Layout, wie $SCRIPTDIR (auch in Bezug auf leniency).
#Sie haben die Eigenart, dass der Name des Verzeichnisses (ohne cg_) vor eventuelle
#Fehlermeldungen platziert wird, Damit kann man Rufgruppen einteilen. Beispiel: Fehler aus einem
#Skript in cg_A erhalten ein "A|" vorangestellt. Das bedeutet bei der Auswertung,
#das über diesen Fehlermeldungen alle Mitglieder der
#Rufgruppe A informiert werden sollen.
#Die Skripts für spezifsche Rufgruppen werden immer zuerst abgearbeitet,
#Arbeitsverzeichnis - in dieses Verzeichnis wird gewechselt, bevor die Testskripts
#ausgeführt werden. Ist das Verzeichnis noch nicht da, wird es angelegt.
#Musste es angelegt werden, wird es am Schluss dieses Skriptes wieder gelöscht
WORKINGDIR=/tmp/wd
#Resultatsdatei: in dieser Datei stehen Zeile für Zeile die Fehlermeldung der unterschiedlichen Skripte
#das bedeutet: die Ausgaben der Skripte auf stdout
RESULTFILE=/tmp/monitoring_results.txt
#entscheidet, ob die Umgebung über die oben stehenden Variablen gesteuert werden (USECMDLINE=1)
#oder über Kommandozeilenparameter (USECMDLINE=0)
USECMDLINE=0
workOnDir ()
{
  echo "$1" "$2"
  data=$(ls "$1"/*.sh 2>/dev/null)
  for script in $data ;
  do
  #echo "found $script"
  #Falls gefundenes Script ausführbar ist
      if [ -x "$script" ]; then
  #echo "executable $script"
  #Script ausführen
  		b=$(basename "$script")
      	RESULTS="$RESULTS""$2"`$script`'\n'
          errorCode="$?"
  	if [ "$errorCode" -ne 0 ]; then
  #echo "tata " $SCRIPTDIR/leniency
  	    if [ -e "$1"/leniency ]; then
  #echo "huhu "$b
  			if [ -e "$1"/leniency/"$b" ]; then
  #echo "zzt "$SCRIPTDIR/leniency/${b}_m
  				c=0
  				if [ -e "$1"/leniency/"$b"_m ]; then
  					a=$(cat "$1"/leniency/"$b"_m)
  #echo "cat "$a
  					c=$(expr "$a" + 1)
  				fi
  				echo -n "$c" >"$1"/leniency/"$b"_m
  				l=$(cat "$1"/leniency/"$b")
  #echo "comparing "$c" and "$l
  				if [ "$c" -lt "$l" ]; then
  #echo "all good"
  					errorCode=0
            RESULTS=""
  				else
  					echo -n 0 >"$1"/leniency/"$b"_m
  				fi
  			fi
  		fi
  	fi
  	if [ "$errorCode" -ne 0 ]; then
  		if [ "$FAILONERROR" -eq 1 ]; then
  			echo -n "$RESULTS" > "$RESULTFILE"
  			#Wieder in ursprüngliches Verzeichnis zurückwechseln
  			cd "$PWD" || return
  			#Falls working dir extra angelegt wurde - Spuren verwischen!
  			if [ "$WDEXISTS" -eq 0 ]; then
  				rmdir "$WORKINGDIR"
  			fi
  			exit 1
  		else
  			FAILED=$(( "$FAILED"+1 ))
  		fi
  	else
  		if [ -x "$1"/leniency/"$b"_m ]; then
  			rm "$1"/leniency/"$b"_m
  		fi
  	fi
      fi
  done ;
}
displayHelp ()
{
        echo "$0 <script dir> <working dir> <fail on error (0|1)> <result file>"
}
if [ $USECMDLINE -eq 1 ]; then
	if [ "$#" -lt 4 ]; then
		echo "not enough parameters!"
		displayHelp
		exit 13
	elif [ ! -e "$1" ]; then
		echo "$1 does not exist!"
		displayHelp
		exit 14
	elif [ ! -d "$1" ]; then
		echo "$1 is not a directory!"
		displayHelp
		exit 15
	else
		SCRIPTDIR="$1"
		WORKINGDIR="$2"
		FAILONERROR="$3"
	fi
fi
#altes Verzeichnis merken
PWD=$(pwd)
#check, ob working dir existiert
if [ -e "$WORKINGDIR" ]; then
	WDEXISTS=1;
else
	WDEXISTS=0;
fi
#falls working dir nicht existiert - anlegen!
if [ "$WDEXISTS" -eq 0 ]; then
	mkdir -p "$WORKINGDIR"
fi
#ins working dir wechseln
cd "$WORKINGDIR" || return
#initialisierug
FAILED=0
RESULTS=""
#Scripts suchen
dirs=$(find "$SCRIPTDIR"/* -maxdepth 0 -type d -name cg_*)
for dir in $dirs ;
do
  dname=$(basename "$dir")
  echo "$dname"
  CALLGROUP=$(echo -n "$dname"| cut -d _ -f 2)
  workOnDir "$dir" "$CALLGROUP"
  echo "$FAILED"
  echo "$RESULTS"
done;
echo "--"
CALLGROUP=""
workOnDir "$SCRIPTDIR" "$CALLGROUP"
echo "$FAILED"
echo "$RESULTS"
if [ "$FAILED" -ne 0 ]; then
	echo -n "$RESULTS" > "$RESULTFILE"
else
	date +%F_%T > "$RESULTFILE"
fi
#Wieder in ursprüngliches Verzeichnis zurückwechseln
cd "$PWD" || return
#Falls working dir extra angelegt wurde - Spuren verwischen!
if [ "$WDEXISTS" -eq 0 ]; then
	rmdir "$WORKINGDIR"
fi
exit "$FAILED"
