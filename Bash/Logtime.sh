#!/bin/bash

#Überprüfe Parametereingabe
if [ $# -eq 2 ]
	then
		echo "2 Parameter vorhanden"
  	else
   		echo "*****Fehler: Parameter fehlt oder wurde nicht gefunden*****"
		exit 65   #Userfehler beginnt ab Rückgabewert 65
fi

#Überprüfen ob Rechner Exestiert.

ping -c 1 $1> /dev/null

if [ $? -eq 0 ]
	then

		echo "*****Eingabe Wahr, Host $1 erreichbar*****"

	else

		echo "*****Fehler Host $1 Exestiert nicht oder nicht erreichbar*****"
		echo  "         Programm beendet!"
        	exit 65
fi

#Überprüfen ob Nutzer Exestiert.
ssh $1 id $2 > /dev/null

if [ $? -eq 0 ]
	then

		echo "***User $2 gefunden***"

	else

 		echo "*****FEHLER User $2 Konnte nicht gefunden werden*****"
 		echo " Programm beendet!"

		exit 65
fi

#Verzeichnis tmp anlegen
TMP=$(mktemp -d wtmp_temp.XXXXXXXX)


if [ $? -eq 0 ]
	then
		echo "Verzeichnis $TMP wurde angelegt um wtmp zu bearbeiten"
	else
  		echo "Verzeichnis $TMP konnte nicht angelegt werden/ exestiert bereits"
fi

#wtmp Daten aus /var/log/ in tmp Ordner Kopieren

echo "Kopiere alle wtmp Daten in $TMP"

scp $1:/var/log/wtmp* $TMP> /dev/null

if [ $? -eq 0 ]
	then
  		echo "wtmp wurden erfolgreich in das Verzeichnis $TMP Kopiert"
	else
  		echo "*****Fehler beim Kopieren*****"
		exit 3
fi

#wtmp daten entpacken
unxz $TMP/*.xz> /dev/null

if [ $? -eq 0 ]
	then
		echo "wtmp* wurden erfolgreich entpackt"
	else
 		echo "*****Fehler beim Entpacken der wtmp* *****"
 		exit 4
fi

# wtmp Daten zusammen schneiden

# wtmp umbenennen da es beim zusammenschneiden sonst zu Fehlern kommt
mv $TMP/wtmp $TMP/wtmp-99999999

cat $TMP/wtmp* >$TMP/wtmp_file

if [ $? -eq 0 ]
	then
		echo "wtmp wurden erfolgreich in wtmp_file zusammengefasst"
	else
 		echo "*****Fehler beim Entpacken der wtmp* *****"
 		exit 4
fi
#ls $TMP/wtmp_file
#wtmp Daten auslesen

#last -F -f $TMP/wtmp_file | grep $2 >$TMP/log_file

last -F -f $TMP/wtmp_file | grep '\<'$2'\>' | grep -v crash | grep -v down | grep -v gone | grep -v still > $TMP/logfile
mv $TMP/logfile $TMP/log_file

ls $TMP/log_file

#Zeilen Lesen und counter setzten
COUNT="0"
RESULT="0"
STARTTIME1="0"
ENDTIME1="0"
#Anzahl der zulesenden Zeilen
COUNT=$(cat $TMP/log_file | wc -l)
echo -e "\n $COUNT Zeilen werden augewertet\n"
cat $TMP/log_file
#Zeiten auswerten
########################################################################################
ueberpruefe()
{
		STARTTIME1=$(head -n $(($COUNT-1)) $TMP/log_file | tail -1 | cut -c 40-63 )
		echo "nächste Startzeit $STARTTIME1"
		STARTTIME1=$(date -d "$STARTTIME1" +%s)
		ENDTIME1=$(head -n $(($COUNT-1)) $TMP/log_file | tail -1 | cut -c 67-90 )
		echo "nächste Endzeit $ENDTIME1"
		ENDTIME1=$(date -d "$ENDTIME1" +%s 2>/dev/null)
		
		
		if [ $COUNT -gt 1 ]
		then
		
		if [ $ENDTIME2 -gt $STARTTIME1 ]
		then
				if [ $ENDTIME2 -lt $ENDTIME1 ]
					then
						ENDTIME2=$ENDTIME1
					fi	
		COUNT=$(( COUNT-1 ))
		ueberpruefe
		fi
		fi
}


while [ $COUNT -gt 0 ]
do
	echo -e "\n$COUNT ter Durchgang"
	#starttime
   
	STARTTIME=$(head -n $COUNT $TMP/log_file | tail -1 | cut -c 40-63 ) #head liest nur die Kopfzeile -n besagt die erste Zeile
					# tail nimmt die letzten Zeilen -1 
	#STARTTIME2 ist die Aktuelle STARTZEIT
	STARTTIME2=$(date -d "$STARTTIME" +%s)
	#echo "starttime2     $STARTTIME2"
      
	#endtime
	
	ENDTIME=$(head -n $COUNT $TMP/log_file | tail -1 | cut -c 67-90 )
	
	#ENDTIME2 ist die Aktuelle ENDTIME
	ENDTIME2=$(date -d "$ENDTIME" +%s 2>/dev/null)
		
	ueberpruefe 			  
	
	#Rechne Zusammen
		#echo "Rechne Zusammen"
		
		
		
		echo "Zwischenergebnis: $RESULT"
		
	TOTAL=$(($ENDTIME2-$STARTTIME2))
	RESULT=$(($RESULT+$TOTAL))
	COUNT=$((COUNT-1))
	
done
    
		#Berechen der zeit
	#tage
		let DAY=$RESULT/86400 2>/dev/null
		let REST_DAY=$RESULT%86400 2>/dev/null
	#stunden
		let HOUR=$REST_DAY/3600 2>/dev/null
		let REST_HOUR=$REST_DAY%3600 2>/dev/null
	#minuten
		let MINUTE=$REST_HOUR/60 2>/dev/null
		let REST_MINUTE=$REST_HOUR%60 2>/dev/null
	#sekunden
		SECONDS=$REST_MINUTE
		
		#Ausgabe
echo "Ergebnis: $RESULT"
echo "$DAY Tage  $HOUR Stunden  $MINUTE Minuten  $SECONDS Sekunden"

		#Angelegten Ordner wieder löschen
trap 'rm -r "$TMP"' 0    #Damit auch nach einen Fehler das File gelöscht wird und kein Datenmüll ensteht

exit 0;
