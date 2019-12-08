#!/bin/bash

#Überprüfe Parametereingabe
if [ $# == 2 ]
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

		echo "*****Eingabe Wahr, $1 Existiert*****"

	else

		echo "*****Fehler Rechner $1 Exestiert nicht oder wurde nicht Gefunden*****"
		echo  "         Programm beendet!"
        	exit 1
fi

#Überprüfen ob Nutzer Exestiert.
ssh $1 finger $2> /dev/null

if [ $? -eq 0 ]
	then

		echo "***User $2 gefunden***"

	else

 		echo "*****FEHLER User $2 Konnte nicht gefunden werden*****"
 		echo " Programm beendet!"

		exit 2
fi

#Verzeichnis tmp anlegen
TMP=$(mktemp -d)

trap 'rm -r "$TMP"' 0    #Damit auch nach einen Fehler das File gelöscht wird und kein Datenmüll ensteht

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
mv $TMP/wtmp $TMP/wmtp-99999999

cat $TMP/wtmp* >$TMP/wtmp_file

#wtmp Daten auslesen

last -F -f $TMP/wtmp_file | grep $2 | grep \(*\) >$TMP/log_file


#Zeilen Lesen und counter setzten
COUNT="0"
RESULT="0"
STARTTIME1="0"
ENDTIME1="0"

#Anzahl der zulesenden Zeilen
COUNT=$(cat $TMP/log_file | wc -l)
echo -e "\nDer counter ist bei $COUNT"

#Zeiten auswerten
########################################################################################
while [ $COUNT -gt 0 ]
do
	echo -e "\n$COUNT ter Durchgang"
	#starttime
   
	STARTTIME=$(head -n $COUNT $TMP/log_file | tail -1 | cut -c 40-63 ) #head liest nur die Kopfzeile -n besagt die erste Zeile
	echo "Startzeit      $STARTTIME"				# tail nimmt die letzten Zeilen -1 
	#STARTTIME2 ist die Aktuelle STARTZEIT
	STARTTIME2=$(date -d "$STARTTIME" +%s)
	echo "starttime2     $STARTTIME2"
      
	#endtime
	
	ENDTIME=$(head -n $COUNT $TMP/log_file | tail -1 | cut -c 67-90 )
	echo "Endezeit      $ENDTIME"
	#ENDTIME2 ist die Aktuelle ENDTIME
	ENDTIME2=$(date -d "$ENDTIME" +%s 2>/dev/null)
		
	echo "gesichterte Startzeit $STARTTIME_SAVE"
	
      #Zeiten Überlappen?  

		 
                if [ $ENDTIME1 -gt $STARTTIME2 ]
                then
                            if [ $ENDTIME2 -lt $ENDTIME1 ]
                            then
                                STARTTIME2=$(($ENDTIME1-$STARTTIME2))
                            fi
                    let COUNT=$COUNT-1
                    
                fi
        
                if [ $ENDTIME1 -lt $ENDTIME2 ]
                then
                        STARTTIME2=$(($ENDTIME1-$STARTTIME2))
                fi
        
	#Rechne Zusammen
		echo "Rechne Zusammen"
		TOTAL=$(($ENDTIME2-$STARTTIME2))
		RESULT=$((RESULT+$TOTAL))
		
		
		echo "Zwischenergebnis: $RESULT"
		
	#Sichere Logout
	ENDTIME_SAVE=$ENDTIME
	echo "gesichtere Endzeit $ENDTIME_SAVE"
	
	#Die Aktuelle ENDTIME wird zu der davor
	ENDTIME1=$ENDTIME2
	echo "gesichterte Endzeit $ENDTIME1"
	
	#Sichere Login
	STARTTIME_SAVE=$STARTTIME
	echo "gesichterte Startzeit $STARTTIME_SAVE"
	#Die Aktuelle STARTTIME wird zu der davor
	STARTTIME1=$STARTTIME2
	echo "gesicherte Startzeit  $STARTTIME1"
	
	COUNT=$((COUNT-1))
	
done

echo -e "\nDie Loginzeit des USER $2 in Sekunden: $RESULT"
	echo "Die Loginzeit in Minuten: $((RESULT/60))"
	echo "Die Loginzeit in Stunden: $((RESULT/3600))"
        echo "Ihre Gesamt Loginzeit in Stunden: $((RESULT /3600)) std $((RESULT % 3600 /60)) min $((RESULT % 60)) s"

		#Berechen der zeit
	#tage
		let tage=$RESULT/86400 2>/dev/null
		let rest_tage=$RESULT%86400 2>/dev/null
	#stunden
		let stunden=$rest_tage/3600 2>/dev/null
		let rest_stunden=$rest_tage%3600 2>/dev/null
	#minuten
		let minuten=$rest_stunden/60 2>/dev/null
		let rest_minuten=$rest_stunden%60 2>/dev/null
	#sekunden
		sekunden=$rest_minuten
		
		#Ausgabe
echo $tage "Tage"
echo $stunden " Stunden"
echo $minuten " Minuten"
echo $sekunden " Sekunden"
		
trap 'rm -r "$TMP"' 0    #Damit auch nach einen Fehler das File gelöscht wird und kein Datenmüll ensteht
