# iMOPS GastroGrid

**Deterministische Produktions- und HACCP-Software für die Gastronomie.**

iMOPS GastroGrid ist eine native iOS-App für professionelle Küchen und Gastronomiebetriebe. Sie unterstützt bei der revisionssicheren HACCP-Dokumentation gemäß EU-Verordnung 852/2004 und dem digitalen Produktionsmanagement.

## Kernfunktionen

- **HACCP-Dokumentation** — Temperaturkontrollen, Reinigungsprotokolle, Wareneingangskontrollen, Korrekturmaßnahmen
- **Revisionssicherer Audit-Trail** — SHA-256-Hash-Ketten (Blockchain-Prinzip), nachträglich nicht veränderbar
- **Event-Sourcing-Architektur** — Append-Only-Journal, vollständige Zustandsrekonstruktion, Crash-Recovery
- **Produktionsmanagement** — Aufgabenverwaltung mit Meier-Score (Kapazitätsindikator), Schichtplanung
- **Rollenbasierte Zugriffskontrolle** — Crew / Dispatcher / Director mit PIN- und Face-ID-Authentifizierung
- **Export** — CSV, JSON und Tagesberichte für behördliche Prüfungen
- **Offline-First** — Vollständig offline lauffähig, keine Cloud-Abhängigkeit
- **Notfall-Modus** — Papier-Formulare und vereinfachte UI bei technischen Störungen

## Architektur

```
Kernel (TheBrain)     → Zentraler In-Memory-State, deterministisch
Event-Sourcing        → Journal, Replayer, RAMState
Security              → AuditTrail (SHA-256), IntegrityVerifier, Auth
Persistence           → SwiftData mit Schema-Versionierung
Export                → HACCPExporter (CSV, JSON, Text)
UI / Terminals        → SwiftUI Views als Query-Terminals
```

## Anforderungen

- iOS 17.0+
- Xcode 26.2+
- Swift 5.0

## Rechtliche Dokumente

| Dokument | Beschreibung |
|----------|-------------|
| [Datenschutzerklärung](docs/DATENSCHUTZERKLAERUNG.md) | DSGVO-konforme Privacy Policy |
| [Nutzungsbedingungen](docs/NUTZUNGSBEDINGUNGEN.md) | Terms of Service |
| [EULA](docs/EULA.md) | Endnutzer-Lizenzvereinbarung |
| [Haftungsausschluss](docs/HAFTUNGSAUSSCHLUSS.md) | Haftungsbeschränkung (EU VO 852/2004) |
| [Impressum](docs/IMPRESSUM.md) | Anbieterkennzeichnung gemäß § 5 TMG |

> **Alle rechtlichen Dokumente sind Entwürfe und müssen vor Veröffentlichung rechtsanwaltlich geprüft werden.**

## Lizenz

Proprietär — Alle Rechte vorbehalten. Siehe [EULA](docs/EULA.md).
