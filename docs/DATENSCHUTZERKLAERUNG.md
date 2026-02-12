# Datenschutzerklärung — iMOPS GastroGrid

**Stand:** Februar 2026
**Verantwortlicher:** Andreas Pelczer (Kontaktdaten siehe [Impressum](IMPRESSUM.md))

> **Hinweis:** Dieses Dokument ist ein Entwurf und muss vor Veröffentlichung durch einen Rechtsanwalt geprüft werden.

---

## 1. Geltungsbereich

Diese Datenschutzerklärung gilt für die iOS-App **iMOPS GastroGrid** (nachfolgend „die App"). Sie informiert über Art, Umfang und Zweck der Verarbeitung personenbezogener Daten innerhalb der App gemäß der Datenschutz-Grundverordnung (DSGVO, EU 2016/679) und dem Bundesdatenschutzgesetz (BDSG).

## 2. Verantwortlicher

Verantwortlicher im Sinne der DSGVO ist:

**Andreas Pelczer**
*(Vollständige Adresse und Kontaktdaten siehe [Impressum](IMPRESSUM.md))*

## 3. Grundsätze der Datenverarbeitung

iMOPS GastroGrid wurde nach dem Prinzip **Privacy by Design** entwickelt:

- **Offline-First:** Alle Daten werden ausschließlich lokal auf dem Gerät gespeichert.
- **Keine Cloud-Übertragung:** Es findet keine Übermittlung personenbezogener Daten an externe Server statt.
- **Kein Tracking:** Die App enthält keine Analyse-, Tracking- oder Werbe-SDKs.
- **Keine Drittanbieter-Dienste:** Es werden keine Daten an Dritte weitergegeben.

## 4. Erhobene Daten

### 4.1 Mitarbeiterdaten (vom Betreiber eingegeben)

| Datum | Zweck | Rechtsgrundlage |
|-------|-------|-----------------|
| Mitarbeitername | Zuordnung von HACCP-Aktionen | Art. 6 Abs. 1 lit. c DSGVO (gesetzliche Pflicht gem. EU VO 852/2004) |
| PIN-Code | Authentifizierung bei HACCP-relevanten Aktionen | Art. 6 Abs. 1 lit. c DSGVO |
| Rolle (Crew/Dispatcher/Director) | Zugriffssteuerung | Art. 6 Abs. 1 lit. f DSGVO (berechtigtes Interesse) |

### 4.2 Automatisch erfasste Daten

| Datum | Zweck | Rechtsgrundlage |
|-------|-------|-----------------|
| Geräte-ID | Zuordnung von Audit-Trail-Einträgen zum Erfassungsgerät | Art. 6 Abs. 1 lit. c DSGVO |
| Zeitstempel | Revisionssichere Dokumentation | Art. 6 Abs. 1 lit. c DSGVO |
| Face-ID-Ergebnis (ja/nein) | Biometrische Mitarbeiter-Authentifizierung | Art. 6 Abs. 1 lit. a DSGVO (Einwilligung) |

**Wichtig:** Biometrische Daten (Face ID) werden ausschließlich durch das iOS-Betriebssystem verarbeitet. Die App erhält lediglich das Ergebnis der Authentifizierung (erfolgreich/fehlgeschlagen), niemals biometrische Rohdaten.

### 4.3 HACCP-Betriebsdaten

| Datum | Zweck | Rechtsgrundlage |
|-------|-------|-----------------|
| Temperaturmessungen | Lebensmittelsicherheit (CCP-Überwachung) | Art. 6 Abs. 1 lit. c DSGVO |
| Reinigungs- und Desinfektionsprotokolle | Hygienenachweis | Art. 6 Abs. 1 lit. c DSGVO |
| Wareneingangskontrollen | Rückverfolgbarkeit | Art. 6 Abs. 1 lit. c DSGVO |
| Korrekturmaßnahmen | Dokumentationspflicht | Art. 6 Abs. 1 lit. c DSGVO |

Diese Daten sind gemäß EU VO 852/2004 gesetzlich vorgeschrieben und werden im Audit-Trail revisionssicher protokolliert.

## 5. Datenspeicherung und -löschung

### 5.1 Speicherort

Alle Daten werden ausschließlich lokal auf dem iOS-Gerät gespeichert (SwiftData / On-Device-Datenbank). Es erfolgt keine Synchronisation mit externen Servern.

### 5.2 Aufbewahrungsfristen

| Datentyp | Standard-Aufbewahrung | Grundlage |
|----------|-----------------------|-----------|
| Audit-Trail | 365 Tage | Revisionssicherheit |
| Journal-Einträge | 90 Tage | Betriebliche Notwendigkeit |
| Betriebsdaten | 180 Tage | HACCP-Dokumentationspflicht |

Die Fristen können vom Betreiber in den App-Einstellungen angepasst werden. Nach Ablauf werden Daten automatisch beim App-Start gelöscht.

### 5.3 Manuelle Löschung

Der Betreiber kann über die App-Einstellungen jederzeit eine manuelle Datenbereinigung durchführen. Durch Deinstallation der App werden sämtliche Daten vollständig vom Gerät entfernt.

## 6. Biometrische Daten (Face ID)

Die App nutzt Face ID ausschließlich zur Mitarbeiter-Authentifizierung bei HACCP-relevanten Aktionen. Die Nutzung ist **optional** und erfordert die ausdrückliche Zustimmung des Nutzers über den iOS-Systemdialog.

- Face ID wird über die Apple LocalAuthentication-API angesprochen.
- Biometrische Daten verlassen niemals die Secure Enclave des Geräts.
- Die App speichert keine biometrischen Daten.

## 7. Datenintegrität und Sicherheit

### 7.1 Technische Maßnahmen

- **SHA-256-Hash-Ketten:** Jeder Audit-Trail-Eintrag ist kryptografisch mit dem vorherigen verkettet (Blockchain-Prinzip). Nachträgliche Änderungen werden erkannt.
- **Append-Only-Journal:** Ereignisse können nur hinzugefügt, nicht verändert oder gelöscht werden.
- **Integritätsprüfung:** Die Hash-Kette kann jederzeit über das HACCP-Dashboard verifiziert werden.
- **Thread-sichere Architektur:** Separate Dispatch-Queues verhindern Datenkorruption bei gleichzeitigen Zugriffen.

### 7.2 Organisatorische Maßnahmen

- Rollenbasierte Zugriffskontrolle (Crew/Dispatcher/Director)
- PIN-Authentifizierung für HACCP-relevante Aktionen
- Optionale Face-ID-Authentifizierung
- Unveränderbarkeit archivierter Datensätze

## 8. Betroffenenrechte

Gemäß DSGVO haben betroffene Personen folgende Rechte:

| Recht | Beschreibung | Umsetzung |
|-------|-------------|-----------|
| **Auskunft** (Art. 15) | Welche Daten über Sie gespeichert sind | Export-Funktion im HACCP-Dashboard (CSV/JSON) |
| **Berichtigung** (Art. 16) | Korrektur unrichtiger Daten | Durch den Betreiber in der App |
| **Löschung** (Art. 17) | Löschung personenbezogener Daten | Mitarbeiter-Löschung mit kaskadierender Bereinigung |
| **Einschränkung** (Art. 18) | Einschränkung der Verarbeitung | Durch den Betreiber konfigurierbar |
| **Datenübertragbarkeit** (Art. 20) | Daten in maschinenlesbarem Format | JSON-Export über HACCP-Dashboard |
| **Widerspruch** (Art. 21) | Widerspruch gegen Verarbeitung | An den Betreiber richten |

**Hinweis:** Aufgrund der gesetzlichen Dokumentationspflicht gemäß EU VO 852/2004 können bestimmte HACCP-Daten während der gesetzlichen Aufbewahrungsfrist nicht gelöscht werden (Art. 17 Abs. 3 lit. b DSGVO).

Zur Ausübung Ihrer Rechte wenden Sie sich bitte an den Betreiber des jeweiligen Gastronomiebetriebs oder an den Verantwortlichen (siehe Abschnitt 2).

## 9. Beschwerderecht

Sie haben das Recht, sich bei einer Datenschutz-Aufsichtsbehörde zu beschweren, wenn Sie der Ansicht sind, dass die Verarbeitung Ihrer Daten gegen die DSGVO verstößt.

## 10. Änderungen dieser Datenschutzerklärung

Wir behalten uns vor, diese Datenschutzerklärung anzupassen, um sie stets den aktuellen rechtlichen Anforderungen anzupassen oder um Änderungen der App umzusetzen. Die aktuelle Version ist stets in der App und auf unserer Webseite abrufbar.

---

*Entwurf — Rechtsanwaltliche Prüfung vor Veröffentlichung erforderlich.*
