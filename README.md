# OW2S0SMSGUARD – Community-Erweiterung für FHEM

Eine kompatible und eigenständig installierbare Erweiterung des ursprünglichen
FHEM-Moduls `00_OW2S0SMSGUARD.pm` von Wzut für den 1-Wire-USB-Master mit zwei
S0-Schnittstellen von SMS-Guard.

Die Erweiterung wurde notwendig, weil die vorhandene CRC-Prüfung zwar Fehler
bei der Datenübertragung erkennt, aber keine formal korrekt übertragenen und
dennoch falschen Sensorwerte innerhalb des zulässigen Temperaturbereichs.
Auch eine reine Prüfung auf feste Mindest- und Höchstwerte konnte solche
plausibel erscheinenden Fehlmessungen nicht erkennen. Die zunächst verwendete
Lösung über `userReadings` musste außerdem an jedem einzelnen Sensor gepflegt
werden und wurde mit mehr als 60 Sensoren unnötig aufwendig und unübersichtlich.

> **Status:** Erste öffentliche 153er-netz.de-Version. Dies ist kein offizieller
> Bestandteil von FHEM. Vor der Installation eine Sicherung anlegen und die
> Sensorwerte nach der Umstellung beobachten. Einsatz in eigener Verantwortung.

Die ursprünglichen Autoren-, Lizenz- und Herkunftshinweise bleiben in der
Moduldatei erhalten. Die Community-Erweiterung vom 15.11.2026 wird von
Frank Parussel / [153er-netz.de](https://153er-netz.de/seiten/entwicklung/fhem.html)
gepflegt.

## Hintergrund

Der Bedarf entstand aus einer Diskussion mit Wzut im FHEM-Forum:

- [ursprünglicher Modul-Thread](https://forum.fhem.de/index.php?topic=28447.0)
- [Frage zur Plausibilitätsprüfung](https://forum.fhem.de/index.php?topic=45440.msg1290316#msg1290316)
- [Antwort von Wzut](https://forum.fhem.de/index.php?topic=45440.msg1290608#msg1290608)

Die dort vorgeschlagene Bereichsprüfung wurde zu einer optionalen,
abwärtskompatiblen Bestätigungslogik erweitert.

## Was wurde erweitert?

- Der ungefilterte Eingangswert bleibt als `temperatureRaw` sichtbar.
- Werte außerhalb eines konfigurierbaren absoluten Bereichs werden verworfen.
- Große Sprünge gegenüber dem letzten gültigen Wert werden zunächst
  zurückgehalten.
- Mehrere untereinander stimmige Messungen können einen realen Sprung
  bestätigen; anschließend wird der neue Wert freigegeben.
- Während der Bestätigung bleibt der letzte plausible Temperaturwert erhalten.
- Diagnosezähler und die letzte Auffälligkeit bleiben pro Sensor sichtbar.
- Nach einem Sensortausch lassen sich die Diagnosewerte gezielt zurücksetzen.

Die Erweiterung ist standardmäßig ausgeschaltet. Ohne
`attr <Sensor> plausibilityCheck 1` verhält sich das Modul wie bisher.

## Neue Attribute

| Attribut | Standard | Bedeutung |
|---|---:|---|
| `plausibilityCheck` | `0` | `1` aktiviert die Plausibilitätsprüfung |
| `plausibilityMin` | `-50` | kleinster absolut zulässiger Wert in °C |
| `plausibilityMax` | `100` | größter absolut zulässiger Wert in °C |
| `plausibilityMaxDelta` | `20` | sofort zulässige Änderung zum letzten gültigen Wert in °C |
| `plausibilityConfirmations` | `3` | erforderliche, untereinander stimmige Bestätigungsmessungen |
| `plausibilityConfirmTolerance` | `1` | zulässige Abweichung der Bestätigungsmessungen in °C |

Beispiel:

```text
attr EG_Bad_RL plausibilityCheck 1
```

## Neue Diagnose-Readings

| Reading | Bedeutung |
|---|---|
| `temperatureRaw` | ungefilterter Eingangswert |
| `plausibilityStatus` | `ok`, `confirming` oder `fault` |
| `plausibilityPendingCount` | bisher gesammelte Bestätigungsmessungen |
| `plausibilityRejectedCount` | Gesamtzahl zurückgehaltener oder verworfener Messungen |
| `plausibilityLastRejected` | letzter zurückgehaltener Rohwert |
| `plausibilityAnomalyCount` | persistenter Zähler erkannter Fehlerereignisse |
| `plausibilityLastAnomaly` | Zeitpunkt und Wert der letzten Anomalie |

Nach einem Sensortausch:

```text
set <Sensor> resetPlausibility
```

Der freigegebene Temperaturwert bleibt dabei erhalten.

## Installation und automatische Updates

Die folgenden Befehle einzeln im FHEM-Kommandoeingabefeld ausführen und jede
Rückmeldung kontrollieren.

### 1. Offizielles Modul gezielt vom Update ausschließen

Zuerst den vorhandenen Wert ansehen:

```text
{ 'WERT: '.AttrVal('global','exclude_from_update','NICHT_GESETZT') }
```

Nur wenn die folgende Regel noch nicht enthalten ist, zusätzlich anhängen:

```text
attr -a global exclude_from_update fhem\.de.*:FHEM/00_OW2S0SMSGUARD\.pm
```

```text
save
```

Damit wird nur die gleichnamige Datei aus der offiziellen FHEM-Quelle
ausgeschlossen. Andere Updatequellen und vorhandene Ausschlussregeln bleiben
unverändert.

### 2. Community-Quelle registrieren und installieren

```text
update add https://raw.githubusercontent.com/parussel/OW2S0SMSGUARD/main/controls_ow2s0smsguard.txt
```

```text
update check https://raw.githubusercontent.com/parussel/OW2S0SMSGUARD/main/controls_ow2s0smsguard.txt
```

Die Vorschau darf ausschließlich folgende Datei nennen:

```text
FHEM/00_OW2S0SMSGUARD.pm
```

Danach installieren und FHEM neu starten:

```text
update all https://raw.githubusercontent.com/parussel/OW2S0SMSGUARD/main/controls_ow2s0smsguard.txt
```

```text
shutdown restart
```

`update list` zeigt die registrierte Quelle. Nach `update add` wird sie bei
einem normalen `update` mit berücksichtigt.

## Abwärtskompatibilität

Die Steuerdatei verteilt ausschließlich `FHEM/00_OW2S0SMSGUARD.pm`. Sie
verändert weder `fhem.cfg` noch `fhem.save`, Definitionen, bestehende Attribute
oder persönliche Messdaten. Die neue Prüfung ist standardmäßig deaktiviert.

Die bisherige CRC- und Protokollprüfung bleibt bestehen. Die neue Logik ergänzt
diese Prüfung und ersetzt sie nicht.

## Rückkehr zum offiziellen FHEM-Modul

Community-Quelle entfernen:

```text
update delete https://raw.githubusercontent.com/parussel/OW2S0SMSGUARD/main/controls_ow2s0smsguard.txt
```

Nur die zuvor hinzugefügte Ausschlussregel entfernen:

```text
attr -r global exclude_from_update fhem\.de.*:FHEM/00_OW2S0SMSGUARD\.pm
```

```text
save
```

Offizielles Modul wiederherstellen und FHEM neu starten:

```text
update 00_OW2S0SMSGUARD.pm https://fhem.de/fhemupdate/controls_fhem.txt
```

```text
shutdown restart
```

Vor dem Rückwechsel eigene Automationen prüfen, die neue Attribute, Readings
oder `resetPlausibility` verwenden. Diese stehen im offiziellen Modul nicht zur
Verfügung.

## Optionale OneWire-Sensordiagnose

Im Verzeichnis [`examples`](examples/README.md) liegt eine dynamische
Diagnoseübersicht für den FHEM-Raum `Diagnose`. Sie ermittelt alle
`OW2S0SMSGUARD`-Subdevices automatisch und zeigt Status, Anomalien,
Bestätigungsmessungen, verworfene Werte und die letzte Anomalie farbig an.
Dadurch lassen sich Sensoren mit ungewöhnlich vielen Auffälligkeiten schnell
erkennen. Ein im Vergleich zu den übrigen Sensoren zunehmend hoher Zähler kann
ein früher Hinweis auf Alterung, einen Kontaktfehler oder einen beginnenden
Sensordefekt sein und ermöglicht eine gezielte Kontrolle beziehungsweise einen
rechtzeitigen Austausch.

Die Anzeige gehört bewusst nicht zum automatischen Modulupdate, da sie eine
persönliche FHEMWEB-Oberfläche ergänzt. Installation und Entfernung sind in
[`examples/README.md`](examples/README.md) beschrieben.

## Prüfung und Herkunft

Die veröffentlichte Datei wurde mit Syntax-/Ladetests, Regressionstests der
Plausibilitätslogik und auf einer laufenden FHEM-Installation mit mehr als
60 OneWire-Sensoren geprüft. `SHA256SUMS.txt` enthält die Prüfsummen der
verteilten Dateien.

Das Modul baut auf dem ursprünglichen FHEM-Modul von Wzut auf. Die vollständige
Zuordnung steht in [NOTICE.md](NOTICE.md). Lizenz: GNU General Public License,
Version 2 oder nach eigener Wahl eine spätere Version (`GPL-2.0-or-later`).

Initiator und Bearbeiter dieser Community-Erweiterung: Frank Parussel.
Implementierung, Tests und Dokumentation entstanden mit KI-Unterstützung.

