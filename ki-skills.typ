#import "@preview/charged-ieee:0.1.4": ieee

#show: ieee.with(
  title: [Agent Skills in der professionellen Softwareentwicklung: Entwurf, Einsatz und Absicherung von KI-Skills in großen Projekten],
  abstract: [
    KI-Coding-Agenten scheitern in großen Codebasen selten an fehlender Sprachkompetenz, sondern an fehlendem Projektwissen: Architekturregeln, Konventionen, Qualitätsmaßstäbe und Prüfwerkzeuge. _Agent Skills_ – Ordner mit einer `SKILL.md`, optionalen Referenzen und Skripten, die ein Agent bei Bedarf lädt – sind seit Ende 2025 ein offener, werkzeugübergreifender Standard für genau dieses Wissen. Diese Arbeit fasst die aktuelle empirische Evidenz zu Wirksamkeit, Aktivierung, Kontextkosten, Rückkopplungsschleifen und Sicherheit von Skills zusammen und leitet daraus einen praxisnahen Leitfaden ab. Kuratierte Skills erhöhen die Erfolgsrate von Agenten im Mittel um 16,2 Prozentpunkte, selbstgenerierte Skills dagegen nicht; ein Skill wird jedoch in bis zu 56 % der passenden Fälle gar nicht aufgerufen, lange Regeldateien senken die Erfolgsrate und erhöhen die Kosten um über 20 %, und 26,1 % öffentlich verfügbarer Skills enthalten Sicherheitsschwachstellen. Eine Fallstudie an einer C++-Spiel-Engine mit rund 676.000 Codezeilen zeigt, wie sich diese Befunde in eine Architektur aus kurzem Immer-Kontext, fokussiertem Skill, deterministischen Prüfskripten und einem automatischen Hook übersetzen lassen; eine Vergleichsmessung ergab 20 von 20 erfüllten Prüfkriterien mit Skill gegenüber 17 von 20 ohne, bei 23 % höherem Tokenverbrauch. Abschließend bietet die Arbeit einen direkt übernehmbaren Leitfaden mit Entscheidungshilfe, Verzeichnisstruktur, Vorlage, Regeln für Skripte, Anti-Mustern und Freigabe-Checkliste.
  ],
  authors: (
    (
      name: "Lucas Tuscher",
      department: [Student]
    ),
  ),
  index-terms: ("Agent Skills", "KI-Coding-Agenten", "Context Engineering", "Software-Qualität", "Large Language Models"),
  bibliography: bibliography("ki-skills.bib"),
  figure-supplement: [Abb.],
)

// Fallback, damit Code-Listings auch ohne TeX Gyre Cursor monospaced bleiben.
#show raw: set text(font: ("TeX Gyre Cursor", "Consolas", "Courier New", "DejaVu Sans Mono"))
#show raw.where(block: true): set text(size: 7pt)

= Einleitung
Der Nutzen KI-gestützter Softwareentwicklung ist empirisch widersprüchlich. Kontrollierte Experimente berichten von 55,8 % schnellerer Bearbeitung einer abgegrenzten Aufgabe @peng2023copilot, rund 21 % Zeitersparnis in einem unternehmensinternen Experiment bei Google @paradis2025google und 26 % mehr abgeschlossenen Aufgaben in drei Feldexperimenten mit fast 5.000 Entwickler:innen @cui2025fieldexperiments. Demgegenüber benötigten erfahrene Open-Source-Entwickler:innen in einer randomisierten Studie mit KI-Werkzeugen 19 % _mehr_ Zeit für Aufgaben in ihren eigenen, ausgereiften Projekten – obwohl sie selbst eine Beschleunigung von 20 % wahrnahmen @becker2025metr. Der DORA-Bericht 2025 beschreibt KI daher als _Verstärker_: Sie vergrößert die Stärken guter Organisationen ebenso wie die Schwächen schlechter und erhöht weiterhin die Instabilität von Auslieferungen @dora2025. Auf Code-Ebene beobachtet GitClear seit der Verbreitung von KI-Assistenten eine stark wachsende Menge duplizierten Codes bei gleichzeitig sinkendem Anteil an Refactoring @gitclear2025.

Ein gemeinsamer Nenner dieser Befunde ist der Kontext: Generische Modelle kennen die Regeln, Abstraktionen und Fallstricke eines großen Projekts nicht. Genau hier setzen _Agent Skills_ an. Sie verpacken prozedurales Projektwissen so, dass ein Agent es erst dann lädt, wenn eine Aufgabe es erfordert @anthropic2025skills. Diese Arbeit beantwortet vier Fragen:

- *RQ1:* Wie funktionieren Agent Skills technisch, und wie grenzen sie sich von Regeldateien, Hooks und Werkzeugen ab?
- *RQ2:* Was sagt die empirische Evidenz über ihre Wirksamkeit und ihre Grenzen?
- *RQ3:* Welche Entwurfsprinzipien folgen daraus für Skills in großen Projekten?
- *RQ4:* Wie setzt man Skills in Unternehmen verlässlich, kosteneffizient und sicher ein?

Der Beitrag besteht aus drei Teilen: einer Synthese aktueller Studien (2023–2026), einer Fallstudie an einer C++-Spiel-Engine einschließlich einer kleinen Vergleichsmessung mit und ohne Skill und einem praxisnahen Leitfaden (@sec-leitfaden), der als interne Richtlinie für Teams dienen kann. Wer Skills nur bauen will, kann direkt mit dem Leitfaden beginnen; die vorangehenden Abschnitte begründen seine Regeln.

= Grundlagen

== Aufbau eines Skills
Ein Skill ist ein Verzeichnis mit einer Datei `SKILL.md`. Sie beginnt mit einem YAML-Kopf, der mindestens `name` (höchstens 64 Zeichen, Kleinbuchstaben, Ziffern und Bindestriche, identisch mit dem Verzeichnisnamen) und `description` (höchstens 1.024 Zeichen) enthält; darunter folgen die Anweisungen in Markdown @agentskillsspec. Optional kommen `scripts/` (ausführbarer Code), `references/` (Nachschlagewissen) und `assets/` (Vorlagen, Daten) hinzu. Das Format wurde von Anthropic entwickelt, als offener Standard veröffentlicht und bis Anfang 2026 von über 25 Produkten übernommen, darunter Claude Code, OpenAI Codex, Cursor, GitHub Copilot und Gemini CLI. Werkzeugübergreifend hat sich das Verzeichnis `.agents/skills/` etabliert, Claude Code liest `.claude/skills/`.

== Progressive Offenlegung
Skills werden in drei Stufen geladen @anthropic2025skills @agentskillsspec:
+ *Metadaten* (ca. 100 Token je Skill): Name und Beschreibung aller Skills stehen dauerhaft im Kontext. Sie sind die einzige Grundlage, auf der der Agent entscheidet, ob er einen Skill öffnet.
+ *Anweisungen* (empfohlen unter 5.000 Token bzw. 500 Zeilen): Der Rumpf der `SKILL.md` wird geladen, wenn die Aufgabe passt.
+ *Ressourcen* (unbegrenzt): Referenzdateien werden nur bei Bedarf gelesen; Skripte werden ausgeführt, ohne dass ihr Quelltext den Kontext belastet – nur ihre Ausgabe kostet Token.

Damit kann ein Skill beliebig viel Wissen bündeln, ohne jede Anfrage zu verteuern.

== Abgrenzung zu verwandten Mechanismen
@tab-mechanismen ordnet Skills in das Umfeld der Agentenkonfiguration ein. Entscheidend ist der Unterschied zwischen _immer geladenem_ Kontext (Regeldateien), _bei Bedarf geladenem_ Wissen (Skills) und _deterministisch ausgeführten_ Prüfungen (Hooks, Skripte).

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    align: left,
    table.header([*Mechanismus*], [*Ladeverhalten*], [*Geeignet für*]),
    [`CLAUDE.md` / `AGENTS.md`], [immer, jede Anfrage], [wenige Regeln, die jede Aufgabe betreffen],
    [Skill], [bei passender Aufgabe], [Abläufe, Fachwissen, Prüfskripte],
    [Hook], [bei Ereignis, deterministisch], [Pflichtprüfungen, die nie vergessen werden dürfen],
    [MCP-Werkzeug], [Beschreibung immer, Aufruf bei Bedarf], [Zugriff auf externe Systeme],
    [Subagent], [eigener Kontext], [breite Suche, Isolation langer Ausgaben],
  ),
  caption: [Mechanismen zur Steuerung von Coding-Agenten],
) <tab-mechanismen>

= Methodik
Die Arbeit folgt einem _Rapid Review_: Gesucht wurde im Oktober 2026 in arXiv, Konferenzbänden (ICLR, NeurIPS, ICSE, IEEE S&P) sowie in technischen Berichten von Werkzeugherstellern und Branchenstudien. Eingeschlossen wurden Arbeiten ab 2023 mit messbaren Aussagen zu Skills, Kontextdateien, Werkzeugauswahl, Kontextlänge, Rückkopplungsschleifen, Produktivität oder Sicherheit von Coding-Agenten. Da das Forschungsfeld sehr jung ist, sind viele Quellen Preprints oder Herstellerberichte; ihre Evidenzstärke wird im Text jeweils benannt. Ergänzend wurde eine Fallstudie an einer proprietären C++-Spiel-Engine (ZadeEngine) durchgeführt, deren Methodik in @sec-fallstudie beschrieben ist.

= Ergebnisse der Literaturanalyse

== Wirksamkeit von Skills
Die bislang umfangreichste Messung, _SkillsBench_, prüft 84 Aufgaben aus 11 Domänen in je drei Varianten (ohne Skill, mit kuratiertem Skill, mit selbstgeneriertem Skill) über 7.308 Durchläufe @li2026skillsbench. Kuratierte Skills erhöhen die Erfolgsrate im Mittel um 16,2 Prozentpunkte. Die Spannweite ist jedoch groß: +4,5 Prozentpunkte in der Softwareentwicklung, +51,9 in der Medizin, und 16 der 84 Aufgaben werden _schlechter_. Drei Befunde sind für die Praxis zentral: (1) Selbstgenerierte Skills bringen im Mittel keinen Nutzen – Modelle können das Wissen, von dem sie profitieren, nicht zuverlässig selbst verfassen. (2) Fokussierte Skills mit zwei bis drei Modulen schlagen umfassende Dokumentation. (3) Kleinere Modelle mit Skills erreichen größere Modelle ohne Skills.

Shaposhnikov et al. werten 500 reale Skills mit 1.000 abgeleiteten Aufgaben über 19 Agent-Modell-Konfigurationen aus und zeigen, dass ein Skill das Verhalten deutlich verändert, Modelle sich aber stark darin unterscheiden, wie treu sie seinen Anweisungen folgen @shaposhnikov2026framework. Jiang et al. analysieren 8.135 Durchläufe und finden, dass Skills vor allem als _prozedurale Anker_ wirken (65,7 % der erfolgreichen Fälle), während reine Wissensinjektion nur 4,5 % ausmacht @jiang2026demystifying. Ein Skill hilft also weniger als Lexikon denn als verlässlicher Arbeitsablauf.

== Aktivierung: das unterschätzte Problem
Ein Skill wirkt nur, wenn er geladen wird. In Vercels Evaluierung zu Next.js-16-APIs wurde der Skill in 56 % der Fälle nie aufgerufen; ein komprimierter Dokumentationsindex von 8 KB direkt in `AGENTS.md` erreichte 100 % Erfolg, der Skill höchstens 79 % @vercel2026agentsmd. Die Auswahl verschlechtert sich zudem mit der Zahl der Alternativen: Bei Jiang et al. fällt die Trefferquote der Skill-Auswahl von 29,6 % bei 5 Skills auf 3,3 % bei 100 Skills @jiang2026demystifying. Ein ähnliches Muster zeigt sich bei Werkzeugen: Wenn nur die relevanten MCP-Werkzeuge per Retrieval vorausgewählt werden, steigt die Auswahlgenauigkeit von 13,62 % auf 43,13 % bei halbierten Prompt-Token @gan2025ragmcp.

Daraus folgt: Die Beschreibung ist die wichtigste Zeile eines Skills; sie muss konkrete Auslöser nennen. Pflichtwissen, das bei _jeder_ Aufgabe gilt, gehört zusätzlich als kurzer Verweis in den immer geladenen Kontext.

== Kontextbudget und Regeldateien
Mehr Kontext ist nicht automatisch besser. Gloaguen et al. zeigen an 138 realen Aufgaben, dass Kontextdateien wie `AGENTS.md` die Erfolgsrate von Coding-Agenten _senken_ und die Inferenzkosten um über 20 % erhöhen; Agenten befolgen die Zusatzanweisungen gewissenhaft und explorieren dadurch mehr als nötig @gloaguen2026agentsmd. Die Autoren empfehlen, nur minimale Anforderungen aufzuschreiben. Das deckt sich mit Messungen zur Befolgung vieler gleichzeitiger Anweisungen: Selbst die besten Modelle befolgen bei 500 Anweisungen nur 68 %, mit einer Tendenz zugunsten früher genannter Anweisungen @jaroslawicz2025ifscale. Unabhängig davon sinkt die Leistung mit wachsender Eingabelänge bereits bei einfachen Aufgaben (_Context Rot_) @hong2025contextrot, und Informationen in der Mitte langer Kontexte werden schlechter genutzt als am Anfang oder Ende @liu2024lost.

Für Skills bedeutet das: Wichtigstes zuerst, keine Erklärungen dessen, was das Modell ohnehin weiß, und Detailwissen in Referenzdateien auslagern, die nur bei Bedarf gelesen werden @anthropic2026bestpractices.

== Rückkopplungsschleifen schlagen Anweisungen
Anweisungen allein garantieren keine Qualität; Prüfwerkzeuge mit Rückmeldung an das Modell wirken stärker. Blyth et al. lassen GPT-4o Code iterativ anhand statischer Analyse (Bandit, Pylint) verbessern: Sicherheitsprobleme sinken von über 40 % auf 13 %, Lesbarkeitsverstöße von über 80 % auf 11 % und Zuverlässigkeitswarnungen von über 50 % auf 11 % @blyth2025static. Für C++ zeigen Tran et al. an 3,52 Millionen produktiven Code-Änderungen, dass KI-generierter Code überdurchschnittlich viele Kopier- und Allokationskosten, Kopplungsprobleme und handgeschriebene Schleifen statt Standardalgorithmen enthält, was 5–8 % mehr Rechenressourcen kostet; gezieltes, taxonomiebasiertes Feedback senkte die betroffenen Warnungen um 11,1 % @tran2026cpp. Allgemeiner belegen _Self-Refine_ @madaan2023selfrefine und _Reflexion_ @shinn2023reflexion, dass Modelle mit Rückmeldung über mehrere Runden deutlich bessere Ergebnisse erzielen. Wie stark die Gestaltung der Schnittstelle zwischen Agent und Umgebung zählt, zeigt SWE-agent: Speziell entworfene Befehle mit kompakter Ausgabe verbessern die Lösungsrate realer GitHub-Issues erheblich @yang2024sweagent.

Ein Skill sollte daher nicht nur beschreiben, wie guter Code aussieht, sondern Skripte mitliefern, die Abweichungen _messen_, und eine Schleife vorschreiben: prüfen, korrigieren, erneut prüfen.

== Token-Ökonomie und Subagenten
In Anthropics Multi-Agenten-Recherchesystem erklärt die Menge verbrauchter Token allein 80 % der Leistungsunterschiede; das System übertrifft einen Einzelagenten um 90,2 %, benötigt aber etwa das 15-Fache an Token einer normalen Unterhaltung @anthropic2025multiagent. Subagenten lohnen sich daher für breite, parallelisierbare Erkundung, deren Zwischenergebnisse im eigenen Kontext bleiben – nicht für Aufgaben, die mit wenigen gezielten Suchen lösbar sind. Weil bei jedem Gesprächsschritt der gesamte Verlauf erneut verarbeitet wird, sparen gezielte Suche statt Volltextlesen, Teil-Lesen großer Dateien, Skriptausgaben mit Begrenzung und kurze Berichte direkt Kosten.

== Sicherheit
Skills führen Anweisungen und Code mit dem Vertrauen des Agenten aus. Liu et al. untersuchen 31.132 Skills aus zwei öffentlichen Marktplätzen: 26,1 % enthalten mindestens eine Schwachstelle (Prompt Injection, Datenabfluss, Rechteausweitung, Lieferkettenrisiken), 5,2 % zeigen Muster, die auf Absicht schließen lassen, und Skills mit Skripten sind 2,12-mal häufiger betroffen als reine Anweisungs-Skills @liu2026skillsecurity. Hinzu kommen die bekannten Risiken generierten Codes selbst: Rund 40 % der von Copilot erzeugten Programme in sicherheitsrelevanten Szenarien waren verwundbar @pearce2022asleep, und Coding-Agenten erzeugen messbare „Security Debt“ @kozak2025.

= Fallstudie: ZadeEngine <sec-fallstudie>

== Ausgangslage
ZadeEngine ist eine proprietäre C++20-Spiel-Engine (2.688 C++-Dateien, rund 676.000 Zeilen ohne Drittanbieter-Code) mit strikter Modulschichtung (Runtime, Developer, Editor, Programs) und einer bereits vorhandenen Regeldatei `CLAUDE.md` mit 133 Zeilen. Ziel war, dass beliebige KI-Agenten Code auf dem Niveau erfahrener Engine-Entwickler:innen schreiben: performant in heißen Pfaden, sauber geschichtet, modern und mit stetigem Rückbau von Altlasten.

== Architektur der Lösung
Die Befunde aus Abschnitt 4 wurden in vier Ebenen übersetzt (@tab-architektur):

#figure(
  table(
    columns: (auto, 1fr),
    align: left,
    table.header([*Ebene*], [*Umsetzung*]),
    [Immer-Kontext], [3 zusätzliche Zeilen in `CLAUDE.md`, kurzer Verweis in `AGENTS.md` für andere Werkzeuge],
    [Skill], [`aaa-engine-engineering`: 172 Zeilen mit Senior-Maßstab, Ablauf, Prüfschleife, Gotcha-Tabelle und Format für Strukturwarnungen; 6 Referenzdateien],
    [Skripte], [Strukturscan (Größe, Hot-Path-Kosten, Kopien, Legacy-Idiome, Duplikate, Schichtverletzungen) und kuratierter clang-tidy-Lauf mit 51 Prüfregeln],
    [Hooks], [`UserPromptSubmit` gibt bei passenden Anfragen einen kurzen Skill-Verweis; `PostToolUse` prüft nach C++-Änderungen die geänderten Zeilen],
  ),
  caption: [Ebenen der Skill-Architektur in der Fallstudie],
) <tab-architektur>

Die Gotcha-Tabelle des Skills übernimmt die von Tran et al. gemessenen Schwächen (Kopien, Allokationen, handgeschriebene Schleifen, Kopplung) direkt als Prüfliste @tran2026cpp. Ein zweiter, kleiner Skill `token-efficient-workflow` (78 Zeilen) beschreibt sparsames Arbeiten in großen Repositories. Beide liegen einmalig unter `.agents/skills/` und sind per Verzeichnisverknüpfung für Claude Code sichtbar, sodass es nur eine Quelle gibt.

== Messwerte der Werkzeuge
Der Strukturscan analysiert die gesamte Engine in 11 s und meldete unter anderem 136 duplizierte Codeblöcke, darunter eine doppelt implementierte Material-Texturladelogik in Editor und Runtime, 57 mutmaßliche Pro-Frame-Kosten und 35 teure Parameterkopien. Erste Versionen erzeugten Fehlalarme (Prosa-Kommentare als „toter Code“, eingebettete Drittanbieter-Header); sie wurden durch Stichproben am Quelltext gefunden und behoben – ein Prüfskript ist selbst Code, der Tests braucht. Der Hook läuft in 0,15 s je Änderung. Die Kompilierdatenbank des Build-Systems wurde bei jedem Build überschrieben und enthielt nur 187 Einträge; nach einer Korrektur mit Selbsttest führt sie Einträge zusammen und umfasst 1.014 Übersetzungseinheiten. Erst dadurch kann clang-tidy die Kernmodule prüfen (drei Übersetzungseinheiten in 10,8 s, 15 Funde). Ein Fund – `sizeof` auf einen Zeiger – erwies sich bei Durchsicht als beabsichtigt: Statische Analyse liefert Hinweise, keine Urteile.

== Vergleichsmessung mit und ohne Skill
Vier typische Aufgaben wurden je einmal mit und ohne Skill von unabhängigen Agenteninstanzen desselben Modells (Claude Opus 5.5) bearbeitet: eine Partikel-Optimierung, das Aufräumen einer 2.800-Zeilen-Datei mit zwei parallelen `switch`-Blöcken, eine Funktion, die eine Schichtverletzung (Runtime ruft Editor) provoziert, und ein Präfix-Filter, der jeden Frame läuft. Je Aufgabe wurden fünf vorab festgelegte, per Skript geprüfte Kriterien bewertet (@tab-eval).

#figure(
  table(
    columns: (1fr, auto, auto),
    align: (left, center, center),
    table.header([*Aufgabe*], [*mit Skill*], [*ohne Skill*]),
    [Partikel-System (SoA)], [5/5], [5/5],
    [`RenderSettings` aufräumen], [5/5], [4/5],
    [Runtime/Editor-Schichtung], [5/5], [4/5],
    [HUD-Präfixfilter], [5/5], [4/5],
    [*Summe*], [*20/20*], [*17/20*],
    [Token je Lauf (Mittel)], [64.048], [52.025],
    [Dauer je Lauf (Mittel)], [123 s], [80 s],
    [Antwortlänge (Wörter, Mittel)], [633], [528],
  ),
  caption: [Erfüllte Prüfkriterien und Kosten je Konfiguration],
) <tab-eval>

Beide Konfigurationen lösten die Kernprobleme; das Basismodell erkannte etwa die Schichtverletzung auch ohne Skill. Die Unterschiede lagen dort, wo Projektwissen nötig ist: Mit Skill verwiesen die Agenten auf die bestehende Einstellungstabelle des Projekts statt eine zweite anzulegen, entdeckten das vorhandene Partikelmodul und meldeten die drohende Doppelimplementierung als Strukturwarnung, nutzten die echte Job-System-API und schrieben Tests im Testformat des Projekts. Der Preis: rund 23 % mehr Token, 54 % mehr Laufzeit und 20 % längere Antworten. Das entspricht dem kleinen, aber positiven Effekt, den SkillsBench für die Softwareentwicklung misst @li2026skillsbench, und führte unmittelbar zu einer Nachschärfung des Skills (Längenbegrenzung der Berichte).

Die Messung ist bewusst als Fallbeispiel zu lesen: ein Lauf je Zelle, ein Modell, Kriterien vom Autor festgelegt. Zudem war der Hook während der Messung aktiv und gab auch einem Basislauf eine Rückmeldung, und die Regeldatei des Projekts kann in den Kontext beider Konfigurationen gelangt sein; beides verringert den gemessenen Unterschied eher.

== Aktivierung und bedingtes Routing
Die Wirksamkeitsmessung setzt einen geladenen Skill voraus; sie belegt nicht, dass ein Agent ihn selbstständig auswählt. Deshalb wurden für beide Projekt-Skills die Beschreibungen um konkrete deutsche und englische Auslöser sowie Abgrenzungen ergänzt. Die Regeldateien verlangen das Laden vor dem Planen passender Aufgaben. Ein zusätzlicher `UserPromptSubmit`-Hook liefert bei passenden Anfragen einen kurzen Hinweis, bleibt bei Dokumentarbeit, kurzen Begriffsfragen und reinen Build-Aufträgen jedoch still. Reine Suche oder Lektüre löst den Engineering-Skill nicht aus; große Dateien, mehrere Module oder Kostenfragen können den Workflow-Skill auslösen. Die Hook-Schnittstelle fügt diesen Hinweis als Kontext hinzu @claudecode2026hooks; das tatsächliche Laden bleibt eine Entscheidung des Agenten.

Die lokale Routingprüfung umfasst 16 ursprüngliche Anfragen und 18 ergänzende Grenzfälle. Alle 34 wurden wie erwartet zugeordnet; darunter sind Anfragen ohne Skill und Aufgaben, die beide Skills benötigen. Neun automatisierte Regressionstests prüfen außerdem die Hook-Ausgabe und die Auswertungslogik. Diese Zahlen beschreiben die deterministische Zuordnung im kuratierten Testsatz, keine Aktivierungsrate eines Modells und keine unabhängige Schätzung für neue Anfragen.

Der überarbeitete Modelltest beobachtet höchstens drei Agentenrunden mit lesenden Werkzeugen. Er zählt nur einen erfolgreichen `Skill`-Aufruf oder eine vollständige Lektüre der `SKILL.md` mit erfolgreicher Werkzeugantwort. Namensnennungen, fehlgeschlagene Aufrufe, nicht sichtbare Skills, Zeitüberschreitungen und API-Fehler dürfen die Aktivierungsrate nicht verfälschen. Eine neue Claude-Code-Sitzung (Version 2.1.288) registrierte beide Skills, der Verfügbarkeitslauf endete jedoch mit HTTP 429 wegen des Wochenlimits. Die erneute Modellmessung ist daher offen; eine Verbesserung der Aktivierungsrate wird nicht behauptet. Die im früheren Arbeitsprotokoll genannte Basislinie von 0 % lässt sich ohne Rohdaten und mit der damaligen Fehlerbehandlung nicht belastbar bestätigen.

= Leitfaden: Skills richtig bauen und einsetzen <sec-leitfaden>
Dieser Abschnitt fasst Literatur, Herstellerdokumentation @agentskillsspec @anthropic2026bestpractices @claudecode2026skills und Fallstudie zu einer Arbeitsgrundlage für Teams zusammen. Er ist so geschrieben, dass er direkt als interne Richtlinie übernommen werden kann.

== Wohin gehört welches Wissen?
Der häufigste Entwurfsfehler ist nicht ein schlechter Skill, sondern Wissen am falschen Ort. @tab-entscheidung ordnet typische Inhalte dem passenden Mechanismus zu.

#figure(
  table(
    columns: (1fr, auto),
    align: left,
    table.header([*Das Wissen …*], [*gehört in*]),
    [gilt für jede Aufgabe und ist in wenigen Zeilen sagbar (Build-Befehl, Schichtregel)], [`CLAUDE.md` / `AGENTS.md`],
    [ist ein Ablauf oder Fachwissen für eine Aufgabenfamilie], [Skill],
    [darf nie vergessen werden (Formatierung, Pflichtprüfung)], [Hook oder CI],
    [braucht Zugriff auf ein externes System (Ticket, Datenbank)], [MCP-Werkzeug],
    [erfordert breite Suche mit viel Zwischenausgabe], [Subagent],
    [betrifft nur die aktuelle Aufgabe], [Prompt],
  ),
  caption: [Entscheidungshilfe für den Ablageort von Wissen],
) <tab-entscheidung>

Ein Skill ersetzt also keine Regeldatei und keinen Hook; er ergänzt sie. Pflichtwissen gehört zusätzlich als einzeiliger Verweis in den Immer-Kontext, weil Skills nicht zuverlässig ausgelöst werden @vercel2026agentsmd.

== Verzeichnisstruktur
Ein Skill deckt genau _eine_ Aufgabenfamilie ab, etwa „Datenbankmigrationen“ oder „C++-Engine-Code“, nicht „alles zum Backend“. @lst-struktur zeigt eine bewährte Struktur.

#figure(
```text
datenbank-migration/
+-- SKILL.md         Pflicht: Kopf + Anweisungen
+-- references/      Nachschlagewissen,
|   +-- sperren.md   je Datei ein Thema
|   +-- rollback.md
+-- scripts/         ausfuehrbare Pruefungen
|   +-- pruefen.py
|   +-- test_pruefen.py
+-- assets/          Vorlagen, Konfiguration
+-- evals/
|   +-- evals.json   Testaufgaben
+-- README.md        fuer Menschen
+-- LICENSE          Nutzungsrechte
```,
  caption: [Verzeichnisstruktur eines Skills],
  kind: raw,
  supplement: [Listing],
) <lst-struktur>

Der Agent liest nur `SKILL.md` und die dort verlinkten Dateien; `README.md` richtet sich an Menschen (Zweck, Installation, Pflege) und kostet dem Agenten keine Token. Der Ordnername muss mit dem Feld `name` übereinstimmen. Skills liegen einmal im Repository unter `.agents/skills/` und werden für Werkzeuge mit eigenem Pfad (Claude Code: `.claude/skills/`) per Verknüpfung eingebunden – eine Kopie je Werkzeug würde auseinanderlaufen.

== Kopfdaten und Beschreibung
@tab-felder fasst die Felder zusammen. Pflicht sind nur `name` und `description`; alle anderen sind optional @agentskillsspec.

#figure(
  table(
    columns: (auto, 1fr),
    align: left,
    table.header([*Feld*], [*Regel*]),
    [`name`], [1–64 Zeichen, nur `a-z`, `0-9` und Bindestrich, gleich dem Ordnernamen; keine reservierten Wörter wie „claude“ oder „anthropic“],
    [`description`], [höchstens 1.024 Zeichen, dritte Person, beschreibt _was_ und _wann_],
    [`license`], [Lizenz oder Vertraulichkeitshinweis],
    [`compatibility`], [nur bei besonderen Voraussetzungen (Python-Version, Netzwerk)],
    [`metadata`], [Besitzer, Version und weitere Schlüssel für eigene Werkzeuge],
    [`allowed-tools`], [vorab erlaubte Werkzeuge; experimentell],
    [Claude-Code-Zusätze], [`when_to_use`, `paths` (nur bei passenden Dateien), `disable-model-invocation` (nur manuell), `context: fork` (eigener Subagent), `hooks`],
  ),
  caption: [Felder im Kopf einer `SKILL.md`],
) <tab-felder>

Die Beschreibung entscheidet allein darüber, ob der Skill geladen wird. Bewährt hat sich die Formel *Was + Wann + Auslöser + Abgrenzung*:

- *Schwach:* „Hilft bei Datenbanken.“
- *Stark:* „Plant und prüft Schemamigrationen der PostgreSQL-Datenbank des Bestellsystems. Verwenden bei neuen Tabellen, Spaltenänderungen oder Indizes und wenn der Nutzer ‚Migration‘, ‚Schema‘ oder ‚DB-Update‘ sagt. Nicht für reine Leseabfragen.“

Das Wichtigste gehört an den Anfang. In Claude Code werden `description` und `when_to_use` zusammen nach 1.536 Zeichen abgeschnitten, und die Liste aller Skill-Beschreibungen erhält nur etwa 1 % des Kontextfensters; bei vielen Skills werden die Beschreibungen deshalb gekürzt @claudecode2026skills. Viele Skills verschlechtern so nicht nur die Auswahl @jiang2026demystifying, sondern auch die Beschreibungen selbst.

== Aufbau der Anweisungen
@lst-vorlage zeigt eine Vorlage für den Rumpf. Die Reihenfolge ist Absicht: Nach einer Kontextverdichtung behält Claude Code nur die ersten 5.000 Token jedes aufgerufenen Skills @claudecode2026skills, und Modelle befolgen früh genannte Anweisungen zuverlässiger @jaroslawicz2025ifscale. Das Wichtigste steht deshalb oben, Nachschlagewissen unten oder in Referenzen.

#figure(
  placement: top,
  scope: "parent",
```markdown
---
name: datenbank-migration
description: Plant und prueft Schemamigrationen der PostgreSQL-Datenbank des Bestellsystems. Verwenden bei neuen
  Tabellen, Spaltenaenderungen oder Indizes und wenn der Nutzer "Migration", "Schema" oder "DB-Update" sagt.
  Nicht fuer reine Leseabfragen.
license: Proprietaer, nur intern
metadata:
  owner: team-plattform
  version: "1.2.0"
---

# Datenbank-Migration
Ziel in einem Satz: Migrationen, die ohne Datenverlust vor- und zurueckrollen.

## Vorrang                      <- Projektregeln (AGENTS.md) gewinnen bei Widerspruch
## Ablauf                       <- nummerierte Checkliste, die der Agent abhakt
1. Bestehende Migrationen und Schema lesen
2. Migration mit Vorwaerts- und Rueckwaertsschritt schreiben
3. `python scripts/pruefen.py <datei>` ausfuehren, Funde beheben, Schritt 3 wiederholen
## Regeln                       <- jede Regel mit Begruendung ("weil ...")
- Spalten nie direkt loeschen, weil laufende Versionen sie noch lesen: erst entkoppeln, dann entfernen.
## Gotchas                      <- beobachtete Wiederholungsfehler, je Zeile Fehler -> Korrektur
## Ausgabeformat                <- was der Bericht enthaelt, wie lang er ist
## Referenzen                   <- je Datei: wann lesen
- references/sperren.md: bei Tabellen ueber 10 Mio. Zeilen
```,
  caption: [Vorlage für eine `SKILL.md` (Kommentare mit Pfeil sind Erläuterungen, nicht Teil der Datei)],
  kind: raw,
  supplement: [Listing],
) <lst-vorlage>

Für den Schreibstil gelten sechs Regeln:
+ *Imperativ und konkret:* „Führe `pruefen.py` aus“ statt „man könnte prüfen“.
+ *Begründen statt befehlen:* Eine Regel mit „weil“ überträgt das Modell auf neue Fälle; gehäufte Großbuchstaben-MUSTs wirken starr und verdrängen einander.
+ *Freiheitsgrad passend wählen:* Bei riskanten Abläufen (Migrationen, Releases) exakte Befehle vorgeben; bei Entwurfsaufgaben Heuristiken und Ziele @anthropic2026bestpractices.
+ *Eine Bezeichnung je Begriff:* nicht abwechselnd „Feld“, „Spalte“, „Attribut“.
+ *Nichts Zeitabhängiges:* statt „ab Juli neue API“ einen Abschnitt „Alte Muster“.
+ *Pfade mit Schrägstrich* (`scripts/pruefen.py`), damit sie auf allen Systemen funktionieren.

== Skripte und Referenzen
Skripte sind der wirksamste Teil eines Skills, weil sie Qualität _messen_ statt sie zu beschreiben @blyth2025static. Ihr Code kostet keine Token, ihre Ausgabe schon. Daraus folgen Regeln:
- Im Skill eindeutig sagen, ob ein Skript *ausgeführt* oder *als Referenz gelesen* werden soll.
- Standardmäßig nur lesend; schreibende Aktionen nur mit ausdrücklicher Option.
- Kompakte, begrenzte Ausgabe (`--limit`, Filter, optional JSON), Fundstellen als `datei:zeile`.
- Eindeutige Exit-Codes (0 = sauber, 1 = Funde, 2 = Bedienfehler) und hilfreiche Fehlermeldungen statt Abstürzen.
- Möglichst nur Standardbibliothek; sonst Abhängigkeiten im Feld `compatibility` nennen.
- Keine unbegründeten Schwellwerte; jede Konstante mit kurzer Begründung.
- Kein Netzwerkzugriff und keine Zugangsdaten ohne zwingenden Grund.
- Selbst testen: absichtlich fehlerhafte Beispiele müssen gefunden werden, echter Code muss stichprobenartig auf Fehlalarme geprüft werden. In der Fallstudie fielen so drei Fehlalarmquellen auf, bevor der Skill eingesetzt wurde.

Referenzdateien behandeln je ein Thema, sind nur eine Ebene tief von `SKILL.md` verlinkt (bei tieferer Verschachtelung lesen Agenten Dateien oft nur teilweise) und erhalten ab etwa 100 Zeilen ein Inhaltsverzeichnis @anthropic2026bestpractices.

== Richtig nutzen im Alltag
Für Entwickler:innen, die Skills anwenden, gelten diese Regeln:
+ *Bei klarer Aufgabe den Skill direkt aufrufen* (`/name` oder Nennung im Prompt), statt auf die automatische Auslösung zu hoffen.
+ *Eine Aufgabe je Sitzung.* Fremde Themen in einer neuen Sitzung beginnen, damit alter Kontext nicht mitbezahlt wird und nicht stört @hong2025contextrot.
+ *Ergebnisse an Prüfungen messen*, nicht an der Überzeugungskraft der Antwort; wahrgenommene und tatsächliche Wirkung fallen auseinander @becker2025metr.
+ *Wiederholte Fehler melden.* Jeder zweite gleiche Fehler wird eine Gotcha-Zeile.
+ *Kosten über das Modell steuern.* Kleinere Modelle mit gutem Skill erreichen größere Modelle ohne Skill @li2026skillsbench; für Routine reicht oft das günstigere Modell.
+ *Werkzeugfunde beurteilen.* Fehlalarme dürfen mit Begründung bestehen bleiben.

== Anti-Muster
@tab-antimuster listet, wie Skills _nicht_ eingesetzt werden sollten, jeweils mit Folge und Alternative.

#figure(
  placement: top,
  scope: "parent",
  table(
    columns: (1.3fr, 1.2fr, 1.5fr),
    align: left,
    table.header([*Anti-Muster*], [*Folge*], [*Besser*]),
    [Skill als Ablage für alles (Wiki-Kopie, komplette API-Doku)], [verwässerte Anweisungen, hohe Kosten], [2–3 fokussierte Module, Rest in Referenzen @li2026skillsbench],
    [Vage Beschreibung („Hilft bei Code“)], [Skill wird nicht geladen], [Was + Wann + Auslöser + Abgrenzung],
    [Viele ähnliche Skills], [falsche Auswahl, gekürzte Beschreibungen @jiang2026demystifying], [zusammenlegen, klare Grenzen],
    [Pflichtprüfung nur im Skill], [wird in einem Teil der Fälle vergessen @vercel2026agentsmd], [zusätzlich Hook oder CI],
    [Lange Regeldatei statt Skill], [niedrigere Erfolgsrate, über 20 % Mehrkosten @gloaguen2026agentsmd], [Regeldatei kurz, Details in Skills],
    [Erklären, was das Modell ohnehin weiß], [Token und Ablenkung], [nur Projekt- und Domänenwissen],
    [Vom Modell erzeugter Skill ohne Prüfung], [im Mittel kein Nutzen @li2026skillsbench], [aus echten Fehlern kuratieren],
    [Starre MUST-Ketten ohne Begründung], [schlechte Übertragung auf neue Fälle], [Regel plus „weil“],
    [Tief verschachtelte Referenzen], [unvollständiges Lesen], [eine Ebene, Inhaltsverzeichnis],
    [Ungeprüfte Skills aus Marktplätzen], [26,1 % verwundbar @liu2026skillsecurity], [interne Registry mit Review],
    [Zugangsdaten oder Kundendaten im Skill], [Datenabfluss], [Umgebungsvariablen, Secret-Store],
    [Skripte mit ungefilterter Ausgabe], [voller Kontext, höhere Kosten], [Begrenzung, Zusammenfassung],
    [Skill ohne Testaufgaben], [Wirkung unbekannt], [Evals mit Basislinie, mehrere Modelle],
  ),
  caption: [Anti-Muster beim Einsatz von Skills],
) <tab-antimuster>

== Lebenszyklus und Freigabe im Unternehmen
Skills sind Code und brauchen denselben Lebenszyklus:
+ *Bedarf belegen:* wiederkehrende Fehler ohne Skill sammeln.
+ *Testaufgaben zuerst:* mindestens drei realistische Aufgaben mit prüfbaren Kriterien.
+ *Minimaler Entwurf:* nur so viel, dass die Testaufgaben bestehen.
+ *Messen:* mit und ohne Skill, mehrere Läufe, alle eingesetzten Modelle; neben Qualität auch Token und Laufzeit. In der Fallstudie zeigte erst diese Messung, dass der Skill die Antworten um 20 % verlängert.
+ *Review und Freigabe* nach der Checkliste unten.
+ *Ausrollen* über eine interne Registry oder das Repository.
+ *Beobachten:* Wird der Skill ausgelöst? Welche Fehler wiederholen sich?
+ *Pflegen:* Gotchas ergänzen, Version erhöhen, Änderungen gegen die Testaufgaben prüfen.
+ *Stilllegen,* wenn der Ablauf entfällt oder der Skill nicht mehr messbar hilft.

*Freigabe-Checkliste:*
- Name gleich Ordnername; Beschreibung mit Was, Wann, Auslösern und Abgrenzung.
- `SKILL.md` unter 500 Zeilen, Wichtigstes oben, keine zeitabhängigen Aussagen.
- Referenzen eine Ebene tief, je ein Thema, Inhaltsverzeichnis ab 100 Zeilen.
- Skripte gelesen, getestet, standardmäßig nur lesend, ohne Zugangsdaten.
- Mindestens drei Testaufgaben mit Vergleich gegen eine Basislinie.
- Besitzer, Version und Lizenz bzw. Vertraulichkeit eingetragen.
- Pflichtprüfungen zusätzlich als Hook oder in der CI.
- Keine inhaltliche Überschneidung mit bestehenden Skills.

= Verwandte Arbeiten
Die Idee wiederverwendbarer Fähigkeiten geht auf Agenten wie _Voyager_ zurück, der eine wachsende Bibliothek ausführbarer Fertigkeiten aufbaut @wang2023voyager. SWE-agent zeigt, dass die Schnittstelle zwischen Agent und Rechner ein eigener Gestaltungsgegenstand ist @yang2024sweagent. Zur Rolle von Entwickler:innen beschreiben Bird et al. die Verschiebung vom Schreiben zum Prüfen von Code @bird2023. Arbeiten zu Kontextdateien @gloaguen2026agentsmd, Skill-Benchmarks @li2026skillsbench @shaposhnikov2026framework @jiang2026demystifying und Skill-Sicherheit @liu2026skillsecurity bilden die unmittelbare Grundlage dieser Arbeit.

= Schlussfolgerung und Ausblick
Agent Skills sind ein wirksames, werkzeugübergreifendes Mittel, um KI-Agenten das Wissen großer Projekte zugänglich zu machen – aber nur unter Bedingungen. Sie helfen, wenn sie von Menschen kuratiert, fokussiert und als Arbeitsablauf statt als Lexikon geschrieben sind (RQ2). Ihre größte Schwäche ist die unzuverlässige Aktivierung; ihre größte Stärke entfalten sie im Zusammenspiel mit kurzem Immer-Kontext, deterministischen Prüfskripten und Hooks (RQ1, RQ3). Im Unternehmen müssen sie wie Code behandelt werden: versioniert, getestet, gemessen und als Lieferkettenrisiko abgesichert (RQ4). Der Leitfaden in @sec-leitfaden übersetzt diese Befunde in konkrete Regeln für Struktur, Beschreibung, Anweisungen, Skripte, Nutzung und Freigabe.

Für den Einstieg in einem Team genügen fünf Schritte: wiederkehrende Fehler sammeln, drei Testaufgaben formulieren, einen kleinen Skill nach @lst-vorlage schreiben, ihn mit und ohne Skill messen und Pflichtprüfungen zusätzlich als Hook absichern.

Offen sind vor allem drei Fragen: wie sich die Aktivierung von Skills ohne Kontextkosten zuverlässig machen lässt, wie Skills mit dem Code, den sie beschreiben, automatisch aktuell bleiben, und wie sich ihr Nutzen in großen, proprietären Codebasen über längere Zeiträume messen lässt. Die Fallstudie liefert dafür einen ersten, bewusst kleinen Datenpunkt.
