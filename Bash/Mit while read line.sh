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

		echo "*****Fehler $1 Exestiert nicht oder wurde nicht Gefunden*****"
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

#wtmp umbenennen
mv $TMP/wtmp $TMP/wtmp-99999999

#datei zusammenfügen
cat $TMP/wtmp* >$TMP/wtmp_file

#wtmp daten auslesen

echo "wtmp Daten auslesen"

#Fehler beseitigen
last -F -f $TMP/wtmp_file | grep $2 | grep \(*\) >$TMP/log_file

ueberhang()
{
        
        if [ $COUNT -gt 1 ]
        then
                if [ $LOGOUT2 -gt $LOGIN ]
                then
                            if [ $LOGOUT2 -lt $LOGOUT ]
                            then
                                LOGIN=$(($LOGOUT2-LOGIN))
                            fi
                    let COUNT=$COUNT-1
                    
                fi
        else
                if [ $LOGOUT2 -lt $LOGOUT ]
                then
                        LOGIN=$(($LOGOUT2-LOGIN))
                fi
        fi
}
 
COUNT=$(cat $TMP/log_file | wc -l) 
		#Zeilen auswerten und in LITIME speichern
		
		while read -r line
			do
					#Kann diesen Befehl nicht finden 
					LOGOUT_TIME=$( $line | cut -c 67-90)
					echo "LOGOUT=$LOGOUT"
					
					
					#kann diesen Befehl nicht finden
					LOGIN_TIME=$( $line | cut -c 40-63)
					echo "LOGIN=$LOGIN"
					
					LOGOUT=$(date -d "$LOGOUT_TIME" +%s)
					LOGIN=$(date -d "$LOGIN_TIME" +%s)
					echo $LOGIN_TIME
					
					ueberhang
					
					
					LOGIN2=$LOGIN
					echo "LOGIN2=$LOGIN2"
					LOGOUT2=$LOGOUT
					echo "LOGOUT2=$LOGOUT2"
					
					TOTAL=$(($LOGOUT-$LOGIN))
					RESULT=$((RESULT+$TOTAL))
			done < "$TMP/log_file"
		
		#echo "Gesammte Loginzeit: $RESULT"
		
		#Zeilen auswerten und in LOTIME speichern
		
		
		#Zeilen Zusammenrechnen
		#let TOTAL=$GLOTIME-$GLITIME
		
	#	echo "total= $TOTAL"
        	#Gesamtergebnis Zusammenrechnen
		#RESULT=$((RESULT+$TOTAL))
		#TOTAL=""



         echo "Die Loginzeit des USER $2 in Sekunden: $RESULT"
	echo "Die Loginzeit in Minuten: $((RESULT/60))"
	echo "Die Loginzeit in Stunden: $((RESULT/3600))"
        echo "Ihre Gesamt Loginzeit in Stunden: $((RESULT /3600)) std $((RESULT % 3600 /60)) min $((RESULT % 60)) s"
