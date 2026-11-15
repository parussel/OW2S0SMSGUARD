# OneWire-Sensordiagnose für FHEM

Die optionale Anzeige listet alle vorhandenen `OW2S0SMSGUARD`-Subdevices
dynamisch auf. Der Master wird nicht als Sensorzeile dargestellt.

Die gemeinsame Übersicht macht Sensoren mit ungewöhnlich vielen Anomalien oder
verworfenen Messwerten unmittelbar sichtbar. Steigen diese Zähler bei einem
einzelnen Sensor im Vergleich zu den übrigen Sensoren auffällig an, kann das
ein Hinweis auf Alterung, Kontaktprobleme oder einen beginnenden Hardwaredefekt
sein. Die Anzeige schaltet den Sensor nicht ab, sondern liefert die Grundlage
für eine gezielte Prüfung und die Entscheidung über einen Austausch.

Angezeigt werden:

- Sensorname und Alias;
- `plausibilityStatus`;
- `plausibilityAnomalyCount`;
- `plausibilityPendingCount`;
- `plausibilityRejectedCount`;
- `plausibilityLastAnomaly`.

Nullwerte erscheinen als kompakte graue Plakette. Historische Auffälligkeiten
werden gelb, eine laufende Bestätigung orange und aktuelle Fehler beziehungsweise
verworfene Messungen rot markiert.

## Installation

Auf dem FHEM-Rechner eine Sicherung anlegen und anschließend beispielsweise per
SSH ausführen:

```sh
wget -O /tmp/onewire_sensordiagnose.pl https://raw.githubusercontent.com/parussel/OW2S0SMSGUARD/main/examples/onewire_sensordiagnose.pl
sudo install -o fhem -g dialout -m 0644 /tmp/onewire_sensordiagnose.pl /opt/fhem/mycfg/onewire_sensordiagnose.pl
```

Danach die folgenden Befehle einzeln in FHEM ausführen:

```text
{ do q{/opt/fhem/mycfg/onewire_sensordiagnose.pl} }
```

```text
define 05.OneWireSensordiagnose weblink htmlCode { (require q{/opt/fhem/mycfg/onewire_sensordiagnose.pl}) && OneWireSensordiagnose_Html() }
```

```text
attr 05.OneWireSensordiagnose alias 05 OneWire-Sensordiagnose
```

```text
attr 05.OneWireSensordiagnose group 05 - OneWire-Sensordiagnose
```

```text
attr 05.OneWireSensordiagnose nodetaillink 1
```

```text
attr 05.OneWireSensordiagnose room Diagnose
```

```text
attr 05.OneWireSensordiagnose sortby 05
```

```text
save
```

Nummer, Alias, Gruppe und Raum dürfen an die eigene Oberfläche angepasst
werden. Die mitgelieferte Formatierung verwendet eine responsive Breite von
1000 Pixeln und enthält zusätzlich die in der Referenzanlage verwendeten
Gruppennamen 01 bis 06. Nicht vorhandene Gruppen werden dadurch nicht erzeugt.

## Aktualisierung

Die aktuelle Datei erneut herunterladen, über die vorhandene Datei installieren
und danach in FHEM neu einlesen:

```text
{ do q{/opt/fhem/mycfg/onewire_sensordiagnose.pl} }
```

## Entfernung

In FHEM:

```text
delete 05.OneWireSensordiagnose
```

```text
save
```

Anschließend kann `/opt/fhem/mycfg/onewire_sensordiagnose.pl` auf Betriebssystem-
ebene gelöscht werden. Das Entfernen der Anzeige verändert weder Sensoren noch
Plausibilitätszähler oder Heizungsregelungen.

