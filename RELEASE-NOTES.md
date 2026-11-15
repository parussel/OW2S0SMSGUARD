# Release Notes

## 2026-11-16 00:27 CET – Reload-Korrektur

Beim Neuladen des Moduls wird jetzt der Client-Cache der vorhandenen
OW2S0SMSGUARD-Master verworfen. FHEM baut dadurch die aktuelle
Client-/MatchRe-Zuordnung neu auf; die Sensorwerte laufen nach einem Reload
weiter. Andere Gerätetypen und ihre Caches bleiben unberührt.

AutoCreate erzeugt weiterhin bewusst `event-on-change-reading` und
`timestamp-on-change-reading`. Bei einer nachgelagerten, zeitstempelbasierten
Ausfallüberwachung muss geprüft werden, ob dieses Verhalten zum gewählten
Timeout passt. Das betrifft beispielsweise PID20; siehe hierzu die
[PID20 Community Edition und die Hilfe zu `pidSensorTimeout`](https://github.com/parussel/PID20).

## 2026-11-15 – erste Community-Veröffentlichung

Diese Version ergänzt das ursprüngliche `00_OW2S0SMSGUARD.pm` um eine
abwärtskompatible Plausibilitätsprüfung für DS18x-Sensoren. Die Funktion ist
standardmäßig deaktiviert und muss je Subdevice mit `plausibilityCheck 1`
eingeschaltet werden.

Neben den konfigurierbaren Prüfparametern stehen persistente Diagnosezähler,
Status-Readings und `resetPlausibility` zur Verfügung. Eine optionale
FHEMWEB-Diagnoseübersicht wird getrennt vom automatischen Modulupdate angeboten.

