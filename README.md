# ZXXX_R_BACKUP_RECOVER

Funktion: Mit diesem Report kann ein Backup vom kundeneigenen
Quelltext erstellt und auf die lokale Festplatte heruntergeladen
werden. Der Report baut dabei auf den folgenden Programmen auf:
- ZXXX_R_BACKUP_DOWNLOAD (J. Sprengel/A. Vogt, CAS AG)
- ZXXX_R_BACKUP_UPLOAD   (J. Sprengel/A. Vogt, CAS AG)
--------------------------------------------------------------------
Vorgehen:
1) Eingabewerte vom Benutzer abfragen
2) Zu sichernde Pakete ermitteln, Eingabewerte prüfen
3) Transport erstellen, freigeben und aus Import-Queue löschen
4) Dateien K* und R* aus /sap/cofile und /sap/data auf lokale
   Festplatte kopieren
--------------------------------------------------------------------
 Manuelle Sicherung mittels ZXXX_R_BACKUP_DOWNLOAD/UPLOAD:
--------------------------------------------------------------------
Sicherung:
1) Zu zu sichernden Objekten (Pakete, Programme etc.)
   Transporteintrag schreiben und alle Objekte kopieren.
   ACHTUNG: Jedes Unterpaket muss einzeln zum TA hinzugefügt
   werden! Das geht auch über die SE01 -> Objekte hinzufügen.
2) Transportauftrag in der SE01 freigeben, jedoch nicht im Ziel-
    system einspielen!
3) Programm 'ZXXX_R_BACKUP_DOWNLOAD' ausführen, lokalen Sicherungs-
    ordner und TA angeben und CheckBox selektieren -> ausführen.
--------------------------------------------------------------------
Wiederherstellung:
1) Programm 'ZXXX_R_BACKUP_UPLOAD' ausführen, lokalen Sicherungs-
   ordner und TA angeben und CheckBox selektieren -> ausführen.
2) STMS > Importübersicht > eigenes System mit Doppelklick wählen >
   Zusätze > Weitere Aufträge > Anhängen
3) TA und Zielmandant eingeben, "Nochmals importieren" selektieren >
   OK
4) In der SE01 wie gewohnt für das eigene System den TA importieren
--------------------------------------------------------------------
Weitere Hinweise:
- AL11: dir_trans -> data und cofiles enthält herunterzuladende
  Dateien
--------------------------------------------------------------------
