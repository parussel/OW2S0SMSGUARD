# Release Notes

## 2026-11-15 – erste Community-Veröffentlichung

Diese Version ergänzt das ursprüngliche `00_OW2S0SMSGUARD.pm` um eine
abwärtskompatible Plausibilitätsprüfung für DS18x-Sensoren. Die Funktion ist
standardmäßig deaktiviert und muss je Subdevice mit `plausibilityCheck 1`
eingeschaltet werden.

Neben den konfigurierbaren Prüfparametern stehen persistente Diagnosezähler,
Status-Readings und `resetPlausibility` zur Verfügung. Eine optionale
FHEMWEB-Diagnoseübersicht wird getrennt vom automatischen Modulupdate angeboten.

