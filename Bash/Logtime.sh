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

#Loginzeit ausschneiden
		LOGIN=$(cut -c 44-63 $TMP/log_file)
		echo $LOGIN > $TMP/login
#Logoutzeit ausschneiden
		LOGOUT=$(cut -c 71-90 $TMP/log_file)
		echo $LOGOUT > $TMP/logout

for var in $TMP/log_file

	do 
		#ausgeben der der Login, -out Daten des Users
		echo $var
	
		
		
		#Zeilen auswerten und in LITIME speichern
		while read -r line
			do
				LITIME=$(date -d "$line" +%s)
				echo "LITITME = $LITIME"
#auch überprüfen wie unten oder if [ time == "" ] dann überspringe Zeile
# also führe nur solange aus wie if [ time -ne "" ] ungleich not equel
					GLITIME=$((GLITIME+$LITIME))
					echo "GLITIME= $GLITIME"
			done <<< "$LOGIN"
		
		echo "Gesammte Loginzeit: $GLITIME"
		
		#Zeilen auswerten und in LOTIME speichern
		while read -r line2
			do
				LOTIME=$(date -d "$line2" +%s)
				echo "LOTIME = $LOTIME"
#hier überprüfen ob die werte auch zeiten sind bsp if [ LOTIME istgleich ZIFFER bzw Zahl [0-9]* oder \d oder [[:digit:]]
					GLOTIME=$((GLOTIME+$LOTIME))
					echo "GLOTIME = $GLOTIME"
			done <<< "$LOGOUT"
	    	
		echo "Die Gesammte Logoutzeit: $GLOTIME"
		
		#Zeilen Zusammenrechnen
		let TOTAL=$GLOTIME-$GLITIME
		
		echo "total= $TOTAL"
        	#Gesamtergebnis Zusammenrechnen
		RESULT=$((RESULT+$TOTAL))
		TOTAL=""

done 

         echo "Die Loginzeit des USER $2 in Sekunden: $RESULT"
	echo "Die Loginzeit in Minuten: $((RESULT/60))"
	echo "Die Loginzeit in Stunden: $((RESULT/3600))"
        echo "Ihre Gesamt Loginzeit in Stunden: $((RESULT /3600)) std $((RESULT % 3600 /60)) min $((RESULT % 60)) s"
