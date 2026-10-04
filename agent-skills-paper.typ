#import "ieee-layout.typ": ieee

// Hilfsfunktionen für das Ablaufdiagramm
#let schritt(nr, titel, text-body) = block(
  width: 100%, stroke: 0.5pt, inset: 4pt, radius: 2pt,
)[*#nr. #titel* \ #text-body]
#let pfeil = align(center)[#sym.arrow.b]

#show: ieee.with(
  title: [Agent Skills für KI-Coding-Agenten: Funktionsweise, Evidenzlage, Aufbau und ein evidenzbasierter Leitfaden],
  abstract: [
    KI-Coding-Agenten benötigen in großen Codebasen projektspezifisches Wissen. _Agent Skills_ bündeln Anweisungen, Referenzen und Skripte, die ein Agent bei Bedarf lädt; seit Dezember 2025 ist das Format ein offener Standard. Diese Literaturübersicht ordnet 33 Quellen zu Funktionsweise, Wirksamkeit, Kontextkosten, Rückkopplung und Sicherheit ein. In der aktuellen SkillsBench-Fassung erhöhen kuratierte Skills die Erfolgsrate im Mittel um 16,6 Prozentpunkte, in der Softwareentwicklung um 11,6; einzelne Aufgaben verschlechtern sich. Die Aktivierung hängt vom Werkzeug und Versuchsaufbau ab. Kontextdateien verbessern den Erfolg nicht generell und können zusätzliche Kosten verursachen. Eine Sicherheitsstudie klassifiziert 26,1 % der untersuchten öffentlichen Skills als potenziell verwundbar. Daraus wird ein Leitfaden mit gekennzeichneter Evidenzstärke abgeleitet, ergänzt um Test- und Freigabeverfahren sowie einen illustrativen Beispiel-Skill.
  ],
  authors: (
    (
      name: "Lucas Tuscher",
      department: [Student \ Stand: 4. Oktober 2026]
    ),
  ),
  index-terms: ("Agent Skills", "KI-Coding-Agenten", "Context Engineering", "Software-Qualität", "Large Language Models"),
  bibliography: bibliography("agent-skills-paper.bib", title: [Literaturverzeichnis]),
  figure-supplement: [Abb.],
  paper-size: "a4",
)

// Deutsche Umbrüche und Querverweise; verfügbare Schrift für Windows.
#set text(lang: "de", font: "Times New Roman")
#show raw: set text(font: "Consolas", size: 8pt)
#show raw.where(block: true): it => {
  set text(size: 7.5pt)
  set par(justify: false, first-line-indent: 0pt, leading: 0.45em)
  block(width: 100%, inset: 7pt, fill: rgb("f6f7f9"), radius: 2pt, it)
}

// Feste Spaltenverhältnisse verhindern überlaufende Zellen. Nur horizontale
// Trennlinien, ausreichend Innenabstand und linksbündiger Tabellentext.
#set table(
  inset: (x: 6pt, y: 5pt),
  stroke: (x: none, y: 0.35pt + rgb("ccd2d8")),
  fill: (_, y) => if y == 0 { rgb("e8edf2") } else if calc.odd(y) { none } else { rgb("f7f8fa") },
)
#show figure.where(kind: table): set text(size: 8.5pt)
#show figure.where(kind: table): set par(justify: false, first-line-indent: 0pt, leading: 0.45em)
#show figure.where(kind: table): set figure(supplement: [Tabelle])
#show figure.caption: set text(lang: "de")

= Einleitung <sec-einleitung>
Der Nutzen KI-gestützter Softwareentwicklung ist empirisch widersprüchlich. Kontrollierte Experimente berichten von 55,8 % schnellerer Bearbeitung einer abgegrenzten Aufgabe @peng2023copilot, rund 21 % geschätzter Zeitersparnis bei Google mit breitem Konfidenzintervall @paradis2025google und 26 % mehr abgeschlossenen Aufgaben in drei Feldexperimenten mit fast 5.000 Entwickler:innen @cui2025fieldexperiments. Demgegenüber benötigten erfahrene Open-Source-Entwickler:innen in einer randomisierten Studie mit KI-Werkzeugen 19 % _mehr_ Zeit für Aufgaben in ihren eigenen, ausgereiften Projekten – obwohl sie selbst eine Beschleunigung von 20 % wahrnahmen @becker2025metr. DORA beschreibt KI als _Verstärker_ organisatorischer Stärken und Schwächen; höhere KI-Nutzung ist im Bericht auch mit größerer Auslieferungsinstabilität verbunden @dora2025. GitClear beobachtet im selben Zeitraum mehr duplizierten Code und weniger Refactoring @gitclear2025. Diese Beobachtungen belegen für sich keine kausale Wirkung von KI.

Eine mögliche Erklärung für einen Teil dieser Unterschiede ist der Kontext: Generische Modelle kennen projektspezifische Regeln und Fallstricke nicht zuverlässig. Die Produktivitätsstudien isolieren diese Ursache jedoch nicht. _Agent Skills_ setzen am fehlenden prozeduralen Wissen an und laden es aufgabenbezogen nach @anthropic2025skills.

Diese Arbeit ist eine Literatursynthese mit Leitfaden. Sie führt keine eigenen Messungen durch, sondern stützt sich ausschließlich auf veröffentlichte Studien und Dokumentationen und kennzeichnet bei jeder Aussage, wie belastbar der Beleg ist. Sie beantwortet vier Fragen:

- *RQ1:* Wie funktionieren Agent Skills technisch, und wie grenzen sie sich von anderen Mechanismen ab?
- *RQ2:* Welche Vorteile und Grenzen belegt die empirische Evidenz?
- *RQ3:* Wie sind Skills typischerweise aufgebaut, und was folgt aus der Evidenz für ihren Entwurf?
- *RQ4:* Wie setzt man Skills im Unternehmen verlässlich, kosteneffizient und sicher ein?

@tab-leser zeigt Lesepfade für unterschiedliche Leserschaften.

#figure(
  table(
    columns: (1.15fr, 1fr),
    align: left,
    table.header([*Wenn du …*], [*dann lies …*]),
    [Skills zum ersten Mal kennenlernst], [@sec-grundlagen, danach @sec-vorteile],
    [einen Skill bauen willst], [@sec-leitfaden und @sec-anhang-beispiel],
    [Skills im Unternehmen einführen sollst], [@sec-sicherheit, @sec-lebenszyklus, @sec-grenzen],
    [die Belege prüfen willst], [@sec-methodik und @sec-literatur],
  ),
  caption: [Lesepfade durch die Arbeit],
) <tab-leser>

= Methodik und Evidenzbasis <sec-methodik>
Die Arbeit ist eine narrative Literaturübersicht mit Quellenprüfung zum 4. Oktober 2026. Die Auswahl umfasst arXiv-Arbeiten, Konferenz- und Zeitschriftenbeiträge, Herstellerdokumentationen und technische Berichte. Ein vollständiges Such- und Screeningprotokoll liegt nicht vor; die Übersicht beansprucht daher weder systematische Vollständigkeit noch den methodischen Status eines reproduzierbaren Rapid Review.

*Suchbegriffe:* „agent skills“, „SKILL.md“, „AGENTS.md“, „context engineering“, „coding agent“, „tool selection“, „skill security“, „long context degradation“.

*Einschlusskriterien:* Veröffentlichung ab 2022; messbare Aussage zu Skills, Kontextdateien, Werkzeugauswahl, Kontextlänge, Rückkopplungsschleifen, Produktivität oder Sicherheit von Coding-Agenten, oder Primärdokumentation des Skill-Formats.

*Ausschlusskriterien:* reine Meinungsbeiträge ohne Messung und Arbeiten ohne Bezug zu Code-Agenten.

Die Auswahl umfasst 33 Quellen. @tab-evidenzklassen ordnet sie nach Evidenzklasse. Die vier unmittelbar skillspezifischen Studien werden als Preprints zitiert. Aussagen über Skills sind daher weniger gesichert als Aussagen über Kontextlänge oder Rückkopplung, für die begutachtete Arbeiten vorliegen.

#figure(
  placement: top,
  scope: "parent",
  table(
    columns: (1.4fr, auto, 3fr),
    align: (left, center, left),
    table.header([*Evidenzklasse*], [*Zahl*], [*Quellen*]),
    [Begutachtete Konferenz-/Zeitschriftenbeiträge], [7], [@liu2024lost @madaan2023selfrefine @shinn2023reflexion @yang2024sweagent @pearce2022asleep @paradis2025google @wang2023voyager],
    [Fachzeitschriftenbeitrag], [1], [@bird2023],
    [Workshop-Beitrag], [1], [@gloaguen2026agentsmd],
    [arXiv-Preprints], [11], [@li2026skillsbench @jiang2026demystifying @shaposhnikov2026framework @liu2026skillsecurity @jaroslawicz2025ifscale @gan2025ragmcp @blyth2025static @tran2026cpp @peng2023copilot @becker2025metr @kozak2025],
    [Working Paper], [1], [@cui2025fieldexperiments],
    [Branchen- und technische Berichte], [3], [@dora2025 @gitclear2025 @hong2025contextrot],
    [Standard-, Hersteller- und Projektdokumentation], [9], [@agentskillsspec @anthropic2025skills @anthropic2026bestpractices @claudecode2026skills @claudecode2026hooks @anthropic2025multiagent @vercel2026agentsmd @postgresql2026index @postgresql2026alter],
  ),
  caption: [Evidenzklassen der 33 Quellen; zitierte Fassungen laut Literaturverzeichnis],
) <tab-evidenzklassen>

Zwei Verzerrungen sind zu beachten. Erstens stammen neun Quellen aus Standard-, Hersteller- oder Projektdokumentation; konkrete Werkzeugdetails sind deshalb nicht unabhängig belegt. Zweitens gelten empirische Zahlen jeweils für die untersuchten Modelle, Werkzeuge und Aufgaben. Bei SkillsBench wird die aktuelle Fassung v4 verwendet; die überarbeitete arXiv-Fassung v3 von Gloaguen et al. wird ergänzend zum Workshop-Beitrag berücksichtigt.

Zur Stärke einzelner Aussagen verwendet der Leitfaden (@sec-leitfaden) drei Stufen: *stark* (mehrere unabhängige Studien, mindestens eine begutachtet), *mittel* (eine empirische Studie oder mehrere Preprints) und *schwach* (Herstellerempfehlung oder Einzelmessung eines Herstellers).

= Grundlagen <sec-grundlagen>

== Aufbau eines Skills <sec-aufbau>
Ein Skill ist ein Verzeichnis mit einer `SKILL.md`. Der YAML-Kopf enthält im offenen Standard `name` (1–64 Zeichen, Kleinbuchstaben, Ziffern und Bindestriche; weder Rand- noch Doppelbindestriche; identisch mit dem Verzeichnisnamen) und `description` (1–1.024 Zeichen) @agentskillsspec. Optional kommen `scripts/`, `references/` und `assets/` hinzu. Anthropic stellte Skills im Oktober 2025 vor und veröffentlichte das Format im Dezember 2025 als offenen Standard @anthropic2025skills. Installationspfade und zusätzliche Felder hängen vom Werkzeug ab; Claude Code verwendet beispielsweise `.claude/skills/` @claudecode2026skills. Ein einheitlicher Installationspfad wird durch das Format nicht vorgeschrieben.

== Progressive Offenlegung <sec-progressiv>
Skills werden in drei Stufen geladen @anthropic2025skills @agentskillsspec (@tab-stufen):

#figure(
  placement: top,
  scope: "parent",
  table(
    columns: (0.45fr, 1.3fr, 2fr, 1.4fr),
    align: left,
    table.header([*Stufe*], [*Inhalt*], [*Wann geladen*], [*Größe*]),
    [1], [Name und Beschreibung], [bei der Skill-Erkennung; Sichtbarkeit werkzeugabhängig], [ca. 100 Token je Skill],
    [2], [Rumpf der `SKILL.md`], [wenn die Aufgabe passt], [empfohlen unter 5.000 Token bzw. 500 Zeilen],
    [3], [Referenzen und Skripte], [bei Bedarf; reine Ausführung benötigt nur die Ausgabe im Kontext], [kein Formatlimit; Kontext- und Ausführungsgrenzen bleiben],
  ),
  caption: [Die drei Ladestufen der progressiven Offenlegung],
) <tab-stufen>

Damit kann ein Skill umfangreiche Ressourcen bündeln, ohne sie vollständig in jede Anfrage zu laden. Name und Beschreibung helfen bei der Auswahl; manuelle Aufrufe, Sichtbarkeitsregeln oder zusätzliche Hinweise können die Aktivierung ebenfalls beeinflussen.

== Ablauf zur Laufzeit <sec-laufzeit>
@abb-laufzeit zeigt einen typischen modellgesteuerten Ablauf @anthropic2025skills. Der Agent wählt anhand der verfügbaren Beschreibungen, ob er einen Skill liest oder aufruft. Das Format schreibt weder einen bestimmten Router noch einen Stichwort-Abgleich vor. Explizite Nutzeraufrufe und werkzeugspezifische Filter sind ebenfalls möglich @claudecode2026skills.

#figure(
  block(width: 100%)[
    #schritt(1, [Start], [Das Werkzeug stellt die sichtbaren Skill-Namen und Beschreibungen bereit (Stufe 1).])
    #pfeil
    #schritt(2, [Anfrage], [Der Nutzer stellt eine Aufgabe. Das Modell vergleicht sie mit den Beschreibungen.])
    #pfeil
    #schritt(3, [Entscheidung], [Passt ein Skill, ruft das Modell ihn auf oder liest die `SKILL.md` per Dateizugriff (Stufe 2). Passt keiner, bleibt der Skill ungenutzt.])
    #pfeil
    #schritt(4, [Ausführung], [Das Modell folgt dem Ablauf und liest Ressourcen bei Bedarf (Stufe 3). Bei reiner Skriptausführung muss nur die Ausgabe in den Kontext gelangen.])
    #pfeil
    #schritt(5, [Rückkopplung], [Prüfskripte melden Funde. Das Modell korrigiert und prüft erneut; bei ungelösten Problemen oder erreichtem Rundenlimit berichtet es den offenen Stand.])
  ],
  caption: [Ablauf der Skill-Nutzung zur Laufzeit],
  kind: image,
) <abb-laufzeit>

== Geltungsbereiche, Vorrang und Konflikte <sec-vorrang>
Skills können im Repository, im Benutzerverzeichnis oder über Organisationsverwaltung bereitgestellt werden. Gleichnamige Skills unterliegen werkzeugspezifischen Vorrangregeln @claudecode2026skills. Für inhaltliche Konflikte zwischen _verschiedenen_ Skills belegen die herangezogenen Quellen keinen einheitlichen Mechanismus. Als Entwurfsheuristik empfiehlt sich, Überschneidungen zu vermeiden und die maßgeblichen Projektregeln ausdrücklich zu benennen. Ein Satz im Skill ersetzt dabei nicht die tatsächliche Instruktionshierarchie des Werkzeugs.

== Abgrenzung zu verwandten Mechanismen <sec-abgrenzung>
@tab-mechanismen ordnet Skills in das Umfeld der Agentenkonfiguration ein. Entscheidend ist der Unterschied zwischen _immer geladenem_ Kontext, _bei Bedarf geladenem_ Wissen und _deterministisch ausgeführten_ Prüfungen.

#figure(
  placement: top,
  scope: "parent",
  table(
    columns: (1.2fr, 1.25fr, 1.3fr, 1.55fr),
    align: left,
    table.header([*Mechanismus*], [*Ladeverhalten*], [*Geeignet für*], [*Schwäche*]),
    [`CLAUDE.md` / `AGENTS.md`, Cursor Rules, Copilot Instructions], [je nach Werkzeug, Verzeichnis und Regeltyp], [wenige Regeln, die jede Aufgabe betreffen], [kostet bei jeder Anfrage; kein genereller Erfolgsgewinn @gloaguen2026agentsmd],
    [Skill], [bei passender Aufgabe, vom Modell gewählt], [Abläufe, Fachwissen, Prüfskripte], [Aktivierung unzuverlässig @vercel2026agentsmd @jiang2026demystifying],
    [Slash-Command / Prompt-Vorlage], [nur auf expliziten Aufruf durch den Menschen], [bewusst gestartete, wiederkehrende Aufgaben], [kein automatisches Laden],
    [Hook], [bei Ereignis, deterministisch], [Pflichtprüfungen, die nie vergessen werden dürfen @claudecode2026hooks], [starr, kein Urteilsvermögen],
    [MCP-Werkzeug], [Beschreibungen direkt oder per Werkzeug-Erkennung; Aufruf bei Bedarf], [Zugriff auf externe Systeme], [viele Werkzeugbeschreibungen belasten die Auswahl @gan2025ragmcp],
    [Subagent], [eigener Kontext], [breite Suche, Isolation langer Ausgaben], [hoher Tokenverbrauch @anthropic2025multiagent],
    [RAG / Dokumentationssuche], [Abruf per Ähnlichkeitssuche], [große, wechselnde Wissensbestände], [Abrufqualität und Aktualität; Abläufe müssen zusätzlich gestaltet werden],
    [Fine-Tuning], [durch Training in Modellgewichten verankert], [dauerhaft stabiles Verhalten und Stil], [teuer, nicht pro Repository änderbar],
  ),
  caption: [Mechanismen zur Steuerung von Coding-Agenten. Zeilen ohne Quelle sind einordnende Beschreibungen des Autors.],
) <tab-mechanismen>

Skills und RAG sind keine Gegensätze: Ein Skill kann auf eine Suchfunktion oder ein Werkzeug verweisen. RAG beantwortet „Was steht in der Dokumentation?“, ein Skill beschreibt „Wie gehen wir vor, und woran messen wir Qualität?“.

== Typischer inhaltlicher Aufbau <sec-anatomie>
Die Spezifikation @agentskillsspec und die Herstellerempfehlungen @anthropic2026bestpractices ergeben das Grundmuster in @tab-anatomie. Die Tabelle beschreibt Empfehlungen, keine Häufigkeitsverteilung. SkillsBench v4 berichtet ergänzend Größenstatistiken: Der Median der `SKILL.md` liegt in der erreichbaren Stichprobe bei 4,8 KB, der des gesamten Pakets bei 7,2 KB @li2026skillsbench. Diese Stichprobe ist keine repräsentative Vollerhebung aller Skills.

#figure(
  table(
    columns: (0.9fr, 2fr),
    align: left,
    table.header([*Baustein*], [*Inhalt*]),
    [YAML-Kopf], [`name`, `description` (Pflicht); optional Lizenz, Voraussetzungen, Metadaten],
    [Ziel], [ein Satz, was der Skill erreichen soll],
    [Ablauf], [nummerierte Schritte, die der Agent abarbeitet],
    [Regeln], [kurze Aufzählung, idealerweise mit Begründung],
    [Gotchas], [bekannte Fehler mit Korrektur],
    [Ausgabeformat], [Inhalt und Länge des Berichts],
    [Verweise], [Referenzen mit Hinweis, wann sie zu lesen sind; Skripte mit Hinweis, ob ausführen oder lesen],
  ),
  caption: [Empfohlene Bausteine einer `SKILL.md`],
) <tab-anatomie>

= Ergebnisse der Literaturanalyse <sec-literatur>

== Wirksamkeit von Skills <sec-wirksamkeit>
Die aktuelle Fassung von _SkillsBench_ (v4) umfasst 87 Aufgaben aus acht Domänen und 18 Modell-Werkzeug-Konfigurationen @li2026skillsbench. Im Vergleich ohne bzw. mit kuratierten Skills steigt die mittlere Erfolgsrate von 33,9 % auf 50,5 % (+16,6 Prozentpunkte). In der Softwareentwicklung beträgt der Zugewinn 11,6 Prozentpunkte; 13 von 87 Aufgaben verschlechtern sich. Selbstgenerierte Skills werden separat in drei Konfigurationen untersucht und schneiden dort schlechter ab als die jeweilige Basislinie. Das ist kein Beleg, dass Modelle grundsätzlich keine nützlichen Skills entwerfen können: Die Autoren nennen auch Probleme bei Erkennung und Trennung von Erzeugungs- und Lösungsphase. Kompakte Skills und wenige passende Skills pro Aufgabe schneiden besser ab als umfassende Pakete; kleinere Modelle mit Skills können stärkere Basislinien ohne Skills erreichen.

Shaposhnikov et al. werten 500 reale Skills mit 1.000 abgeleiteten Aufgaben über 19 Agent-Modell-Konfigurationen aus und zeigen, dass Modelle sich stark darin unterscheiden, wie treu sie Skill-Anweisungen folgen @shaposhnikov2026framework. Jiang et al. normalisieren 8.135 Versuchsdatensätze und klassifizieren 238 gültige Labels aus 240 qualitativ codierten Datensätzen: Prozedurale Anker machen 65,7 % der Skill-Fälle aus, explizite Wissensinjektion 4,5 % @jiang2026demystifying. Diese Anteile beschreiben Nutzungsweisen, keine Erfolgsraten aller Durchläufe. Alle drei Studien werden als Preprints zitiert.

== Vorteile und Grenzen im Überblick <sec-vorteile>
@tab-vorteile fasst zusammen, was für und gegen Skills spricht, jeweils mit Beleg.

#figure(
  placement: top,
  scope: "parent",
  table(
    columns: (1fr, 1fr),
    align: left,
    table.header([*Vorteile*], [*Grenzen*]),
    [Wirksam, wenn kuratiert: +16,6 Prozentpunkte im Mittel @li2026skillsbench], [Selbstgenerierte Skills in drei Konfigurationen schlechter als die Basislinie; 13 von 87 Aufgaben werden schlechter; in der Softwareentwicklung nur +11,6 Prozentpunkte @li2026skillsbench],
    [Kontextsparend durch progressive Offenlegung (@tab-stufen)], [Aktivierung unzuverlässig: in einer Herstellermessung 56 % nie aufgerufen @vercel2026agentsmd],
    [Wirken als wiederholbarer Ablauf, nicht als Lexikon @jiang2026demystifying], [Auswahl verschlechtert sich mit der Zahl der Skills @jiang2026demystifying],
    [Kleinere Modelle mit Skill können stärkere Basislinien ohne Skill erreichen @li2026skillsbench], [Modelle folgen Skill-Anweisungen unterschiedlich treu @shaposhnikov2026framework],
    [Deterministische Prüfung über Skripte; Rückkopplung wirkt stark @blyth2025static @tran2026cpp], [Skripte sind Code: Fehlalarme und Sicherheitsrisiken (@sec-sicherheit); Skills mit Skripten häufiger verwundbar @liu2026skillsecurity],
    [Wiederverwendbar, im Repository versionierbar, im Team teilbar], [Pflegeaufwand; veraltete Skills können unbemerkt schaden (Schlussfolgerung des Autors, nicht gemessen)],
    [Offener, werkzeugübergreifender Standard @agentskillsspec], [Werkzeugspezifische Zusatzfelder und Limits @claudecode2026skills],
    [Kein Training nötig; sofort änderbar], [zusätzlicher Token- und Zeitverbrauch möglich (@sec-token)],
  ),
  caption: [Vorteile und Grenzen von Agent Skills],
) <tab-vorteile>

== Aktivierung: das unterschätzte Problem <sec-aktivierung>
Ein Skill kann über seine Inhalte wirken, wenn diese tatsächlich zugänglich werden. Vercel meldet in einem Next.js-16-Setup 56 % nicht aufgerufene Skills; ein 8-KB-Dokumentationsindex in `AGENTS.md` erreichte 100 % Erfolg, ein explizit angeforderter Skill 79 % @vercel2026agentsmd. SkillsBench v4 zeigt dagegen, dass Erkennung in vielen getesteten Konfigurationen nicht der Hauptengpass ist @li2026skillsbench. Aktivierung ist somit abhängig vom Setup. Jiang et al. berichten bei fünf bis 100 angebotenen Skills einen Rückgang der Präzision der tatsächlichen Nutzung von 29,6 % auf 3,3 %, ohne entsprechenden allgemeinen Einbruch des Aufgabenerfolgs @jiang2026demystifying. Diese Präzision ist von Aktivierungsrate und Erfolgsrate zu unterscheiden. Bei MCP-Werkzeugen verbessert Retrieval die Auswahlgenauigkeit von 13,62 % auf 43,13 % und reduziert Prompt-Token um mehr als 50 % @gan2025ragmcp.

Daraus folgt als Entwurfsheuristik: Beschreibungen sollten konkrete Aufgaben und Grenzen nennen. Bei Aktivierungsproblemen kann ein kurzer Verweis in dauerhaft verfügbarem Projektkontext helfen. Messwerte verschiedener Quellen sind wegen unterschiedlicher Werkzeuge, Aufgaben und Definitionen nicht unmittelbar vergleichbar (@sec-grenzen).

== Kontextbudget und Regeldateien <sec-kontext>
Mehr Kontext ist nicht automatisch besser. Gloaguen et al. untersuchen SWE-bench-Aufgaben sowie 138 CTXbench-Aufgaben; die aktualisierte Fassung v3 findet keinen generellen Erfolgsgewinn durch Kontextdateien, aber durchschnittlich über 20 % höhere Inferenzkosten @gloaguen2026agentsmd. Daraus folgt kein pauschales Verbot von `AGENTS.md`: Nichtstandardisierte Projektregeln können weiterhin nützlich sein. IFScale misst bei 500 Keyword-Anweisungen für Geschäftsberichte selbst bei den besten Modellen nur 68 % Befolgung und eine Bevorzugung früher Anweisungen @jaroslawicz2025ifscale. Diese künstliche Aufgabe ist kein direkter Coding-Benchmark. Context Rot @hong2025contextrot und Lost in the Middle @liu2024lost zeigen ebenfalls Kontextprobleme in ihren jeweiligen Aufgaben. Gemeinsam motivieren die Befunde knappe, relevante Anweisungen; sie beweisen keine universelle optimale Skill-Länge.

== Rückkopplungsschleifen schlagen Anweisungen <sec-rueckkopplung>
Anweisungen allein garantieren keine Qualität; Prüfwerkzeuge mit Rückmeldung an das Modell wirken stärker. Blyth et al. lassen GPT-4o Code iterativ anhand statischer Analyse (Bandit, Pylint) verbessern: Sicherheitsprobleme sinken von über 40 % auf 13 %, Lesbarkeitsverstöße von über 80 % auf 11 % und Zuverlässigkeitswarnungen von über 50 % auf 11 % innerhalb von zehn Iterationen @blyth2025static. Für C++ zeigen Tran et al. an 3,52 Millionen produktiven Code-Änderungen, dass KI-generierter Code überdurchschnittlich viele Kopier- und Allokationskosten, Kopplungsprobleme und handgeschriebene Schleifen statt Standardalgorithmen enthält, was 5–8 % mehr Rechenressourcen kostet; gezieltes, taxonomiebasiertes Feedback senkte die betroffenen Warnungen um 11,1 % @tran2026cpp. Allgemeiner belegen _Self-Refine_ @madaan2023selfrefine und _Reflexion_ @shinn2023reflexion, dass Modelle mit Rückmeldung über mehrere Runden deutlich bessere Ergebnisse erzielen. Wie stark die Gestaltung der Schnittstelle zwischen Agent und Umgebung zählt, zeigt SWE-agent: Speziell entworfene Befehle mit kompakter Ausgabe verbessern die Lösungsrate realer GitHub-Issues erheblich @yang2024sweagent. Die Arbeiten untersuchen Rückkopplung allgemein, nicht speziell in Skills; dass Skripte in Skills denselben Effekt haben, ist eine plausible Übertragung, aber nicht direkt gemessen.

Ein Skill sollte daher nicht nur beschreiben, wie guter Code aussieht, sondern Skripte mitliefern, die Abweichungen _messen_, und eine Schleife vorschreiben: prüfen, korrigieren, erneut prüfen.

== Token-Ökonomie und Subagenten <sec-token>
Anthropic berichtet für sein Recherchesystem 90,2 % höhere Leistung als bei einem Einzelagenten und ungefähr den 15-fachen Tokenverbrauch einer normalen Unterhaltung; Tokenmenge erklärt im dortigen Vergleich 80 % der Leistungsvarianz @anthropic2025multiagent. Diese Herstellerzahlen sind keine Coding-Messung und keine kausale Kostenformel. Gezielte Suche, kompakte Werkzeugausgaben und kurze Berichte können den aktiven Kontext begrenzen; tatsächliche Kosten hängen auch von Modell, Caching und Kontextverwaltung ab. SkillsBench v4 enthält Token- und Kostenauswertungen, deren Werte an die untersuchten Konfigurationen gebunden sind @li2026skillsbench.

= Sicherheit <sec-sicherheit>
Skills können das Verhalten und die Codeausführung des Agenten beeinflussen. Liu et al. sammeln 42.447 öffentliche Skills und analysieren davon 31.132: Ihr Detektor klassifiziert 26,1 % als mindestens einmal verwundbar und 5,2 % als mit hochkritischen, möglicherweise absichtlichen Mustern versehen @liu2026skillsecurity. Für Skills mit Skripten beträgt das Odds Ratio 2,12; das ist kein Verhältnis der Verwundbarkeitswahrscheinlichkeiten. Die Detektorwerte (86,7 % Präzision, 82,5 % Recall) begrenzen die Aussagekraft; die Zahlen sind keine bestätigte Quote aller öffentlich verfügbaren Skills. Daneben fanden Pearce et al. rund 40 % verwundbare Copilot-Programme in ausgewählten sicherheitsrelevanten Szenarien @pearce2022asleep. Kozak et al. untersuchen unsichere Agentenaktionen bei Software-Setup-Aufgaben @kozak2025.

== Bedrohungsmodell
Ein Skill kann auf vier Wegen schaden: (1) _Prompt Injection_ in `SKILL.md` oder Referenzen, die den Agenten zu fremden Zielen lenkt; (2) _Datenabfluss_ über Skripte oder Netzwerkzugriffe; (3) _Rechteausweitung_, wenn ein Skill mehr Werkzeuge nutzt, als seine Aufgabe braucht; (4) _Lieferkettenangriffe_ über nachgeladene Abhängigkeiten oder unbemerkte Änderungen nach der Freigabe. Diese vier Klassen folgen der Einteilung bei @liu2026skillsecurity.

== Gegenmaßnahmen
@tab-sicherheit ordnet jeder Bedrohung eine Gegenmaßnahme zu. Die Zuordnung ist eine Ableitung des Autors aus allgemeinen Sicherheitsprinzipien; die Wirksamkeit dieser Maßnahmen für Skills wurde in den verwendeten Quellen nicht gemessen.

#figure(
  placement: top,
  scope: "parent",
  table(
    columns: (1fr, 3fr),
    align: left,
    table.header([*Bedrohung*], [*Gegenmaßnahme*]),
    [Prompt Injection], [Review aller Dateien des Skills, auch der Referenzen; keine Skills aus ungeprüften Quellen; Anweisungen zum Ignorieren von Regeln oder Verstecken von Ausgaben als Warnsignal],
    [Datenabfluss], [Skripte ohne Netzwerkzugriff; Ausführung in einer Sandbox; keine Zugangsdaten im Skill, stattdessen Secret-Store],
    [Rechteausweitung], [Prinzip der minimalen Rechte; Berechtigungen im ausführenden Werkzeug begrenzen; `allowed-tools` ist keine Sandbox; schreibende Aktionen nur mit ausdrücklicher Option],
    [Lieferkette], [Abhängigkeiten festpinnen; Skills nur aus interner Registry mit Versionierung und Code-Review; Änderungen per Pull Request],
    [Unbemerkte Änderung], [Prüfsummen oder Signierung der Skill-Verzeichnisse; Änderungen im Audit-Log],
  ),
  caption: [Bedrohungen und Gegenmaßnahmen für Skills],
) <tab-sicherheit>

= Leitfaden: Skills richtig bauen und einsetzen <sec-leitfaden>
Dieser Abschnitt übersetzt die Befunde in Regeln, die direkt als interne Richtlinie übernommen werden können. @tab-regeln zeigt zuerst, wie gut jede Kernregel belegt ist, damit Teams wissen, welche Regeln sie unbedingt einhalten und welche sie an ihren Kontext anpassen können.

#figure(
  placement: top,
  scope: "parent",
  table(
    columns: (1.5fr, 2.2fr, 0.65fr),
    align: left,
    table.header([*Regel*], [*Beleg*], [*Stärke*]),
    [Kurz halten, Wichtigstes nach vorn, nur Projektwissen], [Kein genereller Gewinn durch Kontextdateien @gloaguen2026agentsmd; Befolgung sinkt mit Zahl der Anweisungen @jaroslawicz2025ifscale; Leistung sinkt mit Länge @hong2025contextrot @liu2024lost], [stark],
    [Prüfskripte mit Schleife „prüfen – korrigieren – erneut prüfen“], [Rückkopplung wirkt @blyth2025static @tran2026cpp @madaan2023selfrefine @shinn2023reflexion @yang2024sweagent (allgemein, nicht skillspezifisch)], [stark],
    [Modellentwürfe kuratieren und gegen eine Basislinie prüfen], [@li2026skillsbench], [mittel],
    [Wenige passende Skills pro Aufgabe; kompakte Inhalte], [@li2026skillsbench], [mittel],
    [Als Ablauf schreiben, nicht als Lexikon], [@jiang2026demystifying (65,7 % prozedurale Anker)], [mittel],
    [Wenige, klar abgegrenzte Skills], [Präzision der Nutzung sinkt bei großen Skill-Pools @jiang2026demystifying @gan2025ragmcp], [mittel],
    [Skills vor Freigabe auf Sicherheit prüfen], [26,1 % vom Detektor als verwundbar klassifiziert @liu2026skillsecurity; Risiken generierten Codes @pearce2022asleep @kozak2025], [mittel],
    [Beschreibung mit Auslösern und Abgrenzung], [Aktivierung kann ein Engpass sein @vercel2026agentsmd @jiang2026demystifying; die Formel selbst ist Herstellerempfehlung @anthropic2026bestpractices], [mittel bis schwach],
    [Pflichtwissen zusätzlich im Immer-Kontext oder Hook], [Einzelmessung eines Herstellers @vercel2026agentsmd], [schwach],
    [Freiheitsgrad anpassen; Referenzen eine Ebene tief; Inhaltsverzeichnis ab 100 Zeilen], [Herstellerempfehlung @anthropic2026bestpractices, nicht unabhängig geprüft], [schwach],
  ),
  caption: [Evidenzstärke der Kernregeln des Leitfadens],
) <tab-regeln>

== Wohin gehört welches Wissen? <sec-ablage>
Der häufigste Entwurfsfehler ist nicht ein schlechter Skill, sondern Wissen am falschen Ort. @tab-entscheidung ordnet typische Inhalte dem passenden Mechanismus zu.

#figure(
  table(
    columns: (1.8fr, 1fr),
    align: left,
    table.header([*Das Wissen …*], [*gehört in*]),
    [gilt für jede Aufgabe und ist in wenigen Zeilen sagbar (Build-Befehl, Schichtregel)], [`CLAUDE.md` / `AGENTS.md`],
    [ist ein Ablauf oder Fachwissen für eine Aufgabenfamilie], [Skill],
    [darf nie vergessen werden (Formatierung, Pflichtprüfung)], [Hook oder CI],
    [braucht Zugriff auf ein externes System (Ticket, Datenbank)], [MCP-Werkzeug],
    [ist ein großer, wechselnder Faktenbestand (API-Doku, Wiki)], [Suche/RAG, im Skill nur verlinkt],
    [erfordert breite Suche mit viel Zwischenausgabe], [Subagent],
    [betrifft nur die aktuelle Aufgabe], [Prompt],
  ),
  caption: [Entscheidungshilfe für den Ablageort von Wissen],
) <tab-entscheidung>

Ein Skill ersetzt also keine Regeldatei und keinen Hook; er ergänzt sie. Bei wiederkehrenden Aktivierungsproblemen kann ein kurzer Verweis im dauerhaften Kontext helfen @vercel2026agentsmd. Verbindliche Prüfungen gehören in unabhängig konfigurierte Hooks oder CI; ein erst mit dem Skill geladener Hook hilft bei ausbleibender Aktivierung nicht.

== Verzeichnisstruktur <sec-struktur>
Als Entwurfsheuristik deckt ein Skill _eine_ Aufgabenfamilie ab, etwa „Datenbankmigrationen“, nicht „alles zum Backend“. @lst-struktur zeigt eine bewährte Struktur.

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

Der Agent lädt `SKILL.md` und bei Bedarf weitere Dateien. `README.md` richtet sich vor allem an Menschen; wenn der Agent sie liest, beansprucht sie ebenfalls Kontext. Im offenen Standard stimmen Ordnername und `name` überein. Eine gemeinsame Quelle mit werkzeugspezifischen Verknüpfungen kann doppelte Pflege vermeiden; vor dem Einsatz muss geprüft werden, ob das jeweilige Werkzeug diese Pfade und Verknüpfungen unterstützt.

== Kopfdaten und Beschreibung <sec-kopf>
@tab-felder fasst die Felder zusammen. Pflicht sind nur `name` und `description`; alle anderen sind optional @agentskillsspec.

#figure(
  placement: top,
  scope: "parent",
  table(
    columns: (1fr, 3fr),
    align: left,
    table.header([*Feld*], [*Regel*]),
    [`name`], [1–64 Zeichen, nur Kleinbuchstaben, Ziffern und Bindestriche; keine Rand- oder Doppelbindestriche; gleich dem Ordnernamen. Reservierte Namen sind werkzeugspezifisch.],
    [`description`], [1–1.024 Zeichen; beschreibt _was_ und _wann_. Dritte Person ist eine Herstellerempfehlung, keine Formatpflicht.],
    [`license`], [Lizenz oder Vertraulichkeitshinweis],
    [`compatibility`], [1–500 Zeichen; besondere Voraussetzungen wie Python-Version oder Netzwerk],
    [`metadata`], [Besitzer, Version und weitere Schlüssel für eigene Werkzeuge],
    [`allowed-tools`], [vorab erlaubte Werkzeuge; experimentell],
    [Claude-Code-Zusätze], [`when_to_use`, `paths` (nur bei passenden Dateien), `disable-model-invocation` (nur manuell), `context: fork` (eigener Subagent), `hooks`],
  ),
  caption: [Felder im Kopf einer `SKILL.md`],
) <tab-felder>

Die Beschreibung ist ein wichtiges Auswahlkriterium; explizite Aufrufe und Werkzeugregeln beeinflussen das Laden ebenfalls. Die Formel *Was + Wann + Auslöser + Abgrenzung* ist eine praktische Entwurfsheuristik, angelehnt an die Herstellerempfehlung @anthropic2026bestpractices:

- *Schwach:* „Hilft bei Datenbanken.“
- *Stark:* „Plant und prüft Schemamigrationen der PostgreSQL-Datenbank des Bestellsystems. Verwenden bei neuen Tabellen, Spaltenänderungen oder Indizes und wenn der Nutzer ‚Migration‘, ‚Schema‘ oder ‚DB-Update‘ sagt. Nicht für reine Leseabfragen.“

Die Auswahlhilfe gehört an den Anfang. Claude Code begrenzt die gelistete Kombination aus `description` und `when_to_use` standardmäßig auf 1.536 Zeichen und das Beschreibungsbudget auf etwa 1 % des Kontextfensters; beide Werte sind konfigurierbar. Bei Überschreitung entfallen einzelne Beschreibungen, während die Namen erhalten bleiben @claudecode2026skills. Diese Details gelten für die am 4. Oktober 2026 geprüfte Dokumentation, nicht für den offenen Standard.

== Aufbau der Anweisungen <sec-anweisungen>
@lst-vorlage zeigt eine Vorlage. In Claude Code bleiben bei Kontextverdichtung höchstens die ersten 5.000 Token je aufgerufenem Skill erhalten; gemeinsam gilt ein Budget von 25.000 Token, sodass ältere Skills ganz entfallen können @claudecode2026skills. Kritische Regeln gehören deshalb nach vorn, Details in Referenzen.

#figure(
  placement: top,
  scope: "parent",
```markdown
---
name: datenbank-migration
description: >-
  Plant und prueft PostgreSQL-Migrationen des Bestellsystems.
  Verwenden bei Tabellen, Spalten, Indizes und DB-Updates.
  Nicht fuer reine Leseabfragen.
license: Proprietaer, nur intern
metadata:
  owner: team-plattform
  version: "1.2.0"
---

# Datenbank-Migration
Ziel: Migrations- und Wiederherstellungsplan mit geprueften Risiken.

## Vorrang                      <- Projektregeln (AGENTS.md) gewinnen bei Widerspruch
## Ablauf                       <- nummerierte Checkliste, die der Agent abhakt
1. Bestehende Migrationen und Schema lesen
2. Migration mit Vorwaerts- und Rueckwaertsschritt schreiben
3. Strukturpruefer im Skill-Verzeichnis ausfuehren; Funde beheben
4. Hoechstens drei Pruefrunden; SQL und Rollback separat testen
## Regeln                       <- jede Regel mit Begruendung ("weil ...")
- Spalten nie direkt loeschen, weil laufende Versionen sie noch lesen: erst entkoppeln, dann entfernen.
## Gotchas                      <- beobachtete Wiederholungsfehler, je Zeile Fehler -> Korrektur
## Ausgabeformat                <- was der Bericht enthaelt, wie lang er ist
## Referenzen                   <- je Datei: wann lesen
- references/sperren.md: bei grossen Tabellen mit laufenden Zugriffen
```,
  caption: [Vorlage für eine `SKILL.md` (Kommentare mit Pfeil sind Erläuterungen, nicht Teil der Datei)],
  kind: raw,
  supplement: [Listing],
) <lst-vorlage>

Für den Schreibstil gelten sieben Regeln:
+ *Imperativ und konkret:* „Führe `pruefen.py` aus“ statt „man könnte prüfen“.
+ *Regeln knapp begründen:* Eine kurze Begründung kann das Ziel einer Regel verdeutlichen. Ein genereller Übertragungsvorteil gegenüber Großbuchstaben-MUSTs ist in den verwendeten Quellen nicht gemessen; dies ist eine Entwurfsheuristik des Autors.
+ *Freiheitsgrad passend wählen:* Bei riskanten Abläufen (Migrationen, Releases) exakte Befehle vorgeben; bei Entwurfsaufgaben Heuristiken und Ziele @anthropic2026bestpractices.
+ *Eine Bezeichnung je Begriff:* nicht abwechselnd „Feld“, „Spalte“, „Attribut“.
+ *Nichts Zeitabhängiges:* statt „ab Juli neue API“ einen Abschnitt „Alte Muster“.
+ *Pfade mit Schrägstrich* (`scripts/pruefen.py`), damit sie auf allen Systemen funktionieren.
+ *Nur ergänzen, was das Modell nicht weiß:* Projekt- und Domänenwissen statt Allgemeinwissen, weil zusätzlicher Kontext Kosten verursacht und den Erfolg senken kann @gloaguen2026agentsmd.

=== Schlecht gegen gut
@tab-schlechtgut stellt für dieselbe Aufgabe einen schwachen und einen starken Entwurf gegenüber. Die Gegenüberstellung ist ein illustratives Beispiel des Autors, keine Messung.

#figure(
  placement: top,
  scope: "parent",
  table(
    columns: (0.75fr, 1.4fr, 2fr),
    align: left,
    table.header([*Element*], [*Schwach*], [*Stark*]),
    [Beschreibung], [„Hilft bei Datenbanken.“], [Was, Wann, Auslöser, Abgrenzung (siehe oben)],
    [Ablauf], [„Achte auf gute Migrationen und teste sie.“], [Nummerierte Schritte mit konkretem Prüfbefehl, Rundenlimit und Bericht offener Funde],
    [Regeln], [„IMMER Rollback vorsehen! NIE Daten verlieren!“], [„Spalten nie direkt löschen, weil laufende Versionen sie noch lesen: erst entkoppeln, dann entfernen.“],
    [Wissen], [Erklärt, was SQL und ein Index sind], [Nur Projektspezifisches: Namensschema, Sperrverhalten bei großen Tabellen],
    [Prüfung], [keine], [Skript mit festen Exit-Codes und begrenzter Ausgabe],
    [Länge], [900 Zeilen Wiki-Kopie], [unter 100 Zeilen, Details in Referenzen],
  ),
  caption: [Gegenüberstellung eines schwachen und eines starken Skills],
) <tab-schlechtgut>

== Skripte und Referenzen <sec-skripte>
Prüfskripte können eine verlässliche Rückkopplung ermöglichen; dass sie generell der wirksamste Teil eines Skills sind, ist nicht direkt belegt (@sec-rueckkopplung). Bei reiner Ausführung muss der Skriptcode nicht in den Modellkontext; beim Review oder Debugging wird er oft dennoch gelesen. Daraus folgen praktische Empfehlungen:
- Im Skill eindeutig sagen, ob ein Skript *ausgeführt* oder *als Referenz gelesen* werden soll.
- Standardmäßig nur lesend; schreibende Aktionen nur mit ausdrücklicher Option.
- Kompakte, begrenzte Ausgabe (`--limit`, Filter, optional JSON), Fundstellen als `datei:zeile`; das entspricht dem Prinzip kompakter Schnittstellen bei @yang2024sweagent.
- Eindeutige Exit-Codes (0 = sauber, 1 = Funde, 2 = Bedienfehler) und hilfreiche Fehlermeldungen statt Abstürzen.
- Möglichst nur Standardbibliothek; sonst Abhängigkeiten im Feld `compatibility` nennen.
- Keine unbegründeten Schwellwerte; jede Konstante mit kurzer Begründung.
- Kein Netzwerkzugriff und keine Zugangsdaten ohne zwingenden Grund, weil Skripte das Hauptrisiko darstellen @liu2026skillsecurity.
- Selbst testen: absichtlich fehlerhafte Beispiele müssen gefunden werden; echter Code muss stichprobenartig auf Fehlalarme geprüft werden, denn ein Prüfskript ist selbst Code.

Referenzdateien behandeln je ein Thema, sind nur eine Ebene tief von `SKILL.md` verlinkt (bei tieferer Verschachtelung lesen Agenten Dateien oft nur teilweise) und erhalten ab etwa 100 Zeilen ein Inhaltsverzeichnis @anthropic2026bestpractices.

== Testen und Beobachten <sec-testen>
Ein Skill ist erst dann belegt wirksam, wenn zwei Dinge getrennt gemessen wurden: ob er _ausgelöst_ wird und ob er _hilft_, wenn er geladen ist. Als Vorbild für das Messdesign dient SkillsBench: dieselbe Aufgabe ohne Skill und mit Skill, mehrere Läufe, mehrere Modelle @li2026skillsbench @shaposhnikov2026framework.

*Auslösetests (Trigger-Tests).* Ein Testsatz enthält _positive_ Anfragen (Skill soll laden), _negative_ Anfragen (Skill soll nicht laden, etwa Leseabfragen) und _Grenzfälle_ (Formulierungen ohne die Schlüsselwörter der Beschreibung). Jede Anfrage wird mehrfach ausgeführt, weil das Modell nicht deterministisch entscheidet. Gemessen wird die Aktivierungsrate je Gruppe; als Aktivierung zählt nur ein erfolgreicher Skill-Aufruf oder eine vollständige Lektüre der `SKILL.md`, nicht die bloße Nennung des Namens. Ein Vorlagenformat steht in @sec-anhang-trigger.

*Wirksamkeitstests.* Mindestens drei realistische Aufgaben mit vorab festgelegten, möglichst per Skript prüfbaren Kriterien, jeweils mit und ohne Skill, mehrere Läufe, alle eingesetzten Modelle; neben Qualität auch Token und Laufzeit. Kriterien nicht erst nach dem Lauf festlegen.

*Beobachtbarkeit.* Werkzeugprotokolle und passende Hooks können erfolgreiche Skill-Aufrufe bzw. Dateizugriffe dokumentieren @claudecode2026hooks. Ein Kennsatz im Abschlussbericht ist nur ein Hinweis und kein Nachweis des Ladens.

*Fehlersuche, wenn ein Skill nicht greift:* (1) Ist er sichtbar (richtiges Verzeichnis, gültiger Kopf, Name gleich Ordner)? (2) Wurde die Beschreibung gekürzt (@sec-kopf)? (3) Enthält die Beschreibung die Wörter, die Nutzer tatsächlich schreiben? (4) Konkurriert ein ähnlicher Skill? (5) Hilft ein Verweis im Immer-Kontext oder ein Hook?

== Richtig nutzen im Alltag <sec-alltag>
Für Entwickler:innen, die Skills anwenden, gelten diese Regeln:
+ *Bei klarer Aufgabe den Skill direkt aufrufen* (`/name` oder Nennung im Prompt), statt auf die automatische Auslösung zu hoffen, weil diese unzuverlässig ist @vercel2026agentsmd.
+ *Eine Aufgabe je Sitzung.* Fremde Themen in einer neuen Sitzung beginnen, damit alter Kontext nicht mitbezahlt wird und nicht stört @hong2025contextrot.
+ *Ergebnisse an Prüfungen messen*, nicht an der Überzeugungskraft der Antwort; wahrgenommene und tatsächliche Wirkung können weit auseinanderfallen @becker2025metr.
+ *Wiederholte Fehler melden.* Jeder zweite gleiche Fehler wird eine Gotcha-Zeile.
+ *Kosten über das Modell steuern.* Kleinere Modelle mit gutem Skill können stärkere Basislinien ohne Skill erreichen @li2026skillsbench; für Routine reicht oft das günstigere Modell.
+ *Werkzeugfunde beurteilen.* Fehlalarme dürfen mit Begründung bestehen bleiben.

== Anti-Muster <sec-antimuster>
@tab-antimuster listet, wie Skills _nicht_ eingesetzt werden sollten, jeweils mit Folge und Alternative.

#figure(
  placement: top,
  scope: "parent",
  table(
    columns: (1.3fr, 1.2fr, 1.5fr),
    align: left,
    table.header([*Anti-Muster*], [*Folge*], [*Besser*]),
    [Skill als Ablage für alles (Wiki-Kopie, komplette API-Doku)], [verwässerte Anweisungen, hohe Kosten], [Wenige passende Skills, kompakte Inhalte und Referenzen @li2026skillsbench],
    [Vage Beschreibung („Hilft bei Code“)], [Skill wird nicht geladen], [Was + Wann + Auslöser + Abgrenzung],
    [Viele ähnliche Skills], [falsche Auswahl, gekürzte Beschreibungen @jiang2026demystifying], [zusammenlegen, klare Grenzen],
    [Pflichtprüfung nur im Skill], [wird in einem Teil der Fälle vergessen @vercel2026agentsmd], [zusätzlich Hook oder CI],
    [Lange Regeldatei statt Skill], [kein genereller Erfolgsgewinn, über 20 % Mehrkosten @gloaguen2026agentsmd], [Regeldatei kurz, Details in Skills],
    [Erklären, was das Modell ohnehin weiß], [Token und Ablenkung], [nur Projekt- und Domänenwissen],
    [Vom Modell erzeugter Skill ohne Prüfung], [in den untersuchten Konfigurationen kein Vorteil @li2026skillsbench], [aus echten Fehlern kuratieren],
    [Starre MUST-Ketten ohne Begründung], [Ziel einer Regel bleibt unklar (Entwurfsheuristik)], [Regel knapp begründen],
    [Tief verschachtelte Referenzen], [unvollständiges Lesen (Herstellerhinweis)], [eine Ebene, Inhaltsverzeichnis],
    [Ungeprüfte Skills aus Marktplätzen], [26,1 % vom Detektor als verwundbar klassifiziert @liu2026skillsecurity], [interne Registry mit Review],
    [Zugangsdaten oder Kundendaten im Skill], [Datenabfluss], [Umgebungsvariablen, Secret-Store],
    [Skripte mit ungefilterter Ausgabe], [voller Kontext, höhere Kosten], [Begrenzung, Zusammenfassung],
    [Skill ohne Testaufgaben], [Wirkung unbekannt; 13 von 87 Aufgaben wurden mit Skill schlechter @li2026skillsbench], [Evals mit Basislinie, mehrere Modelle],
    [Widersprüchliche Skills ohne Vorrang], [unvorhersehbares Verhalten (Schlussfolgerung des Autors)], [Vorrang festhalten, Überschneidung vermeiden],
  ),
  caption: [Anti-Muster beim Einsatz von Skills],
) <tab-antimuster>

== Lebenszyklus und Freigabe im Unternehmen <sec-lebenszyklus>
Skills sind Code und brauchen denselben Lebenszyklus:
+ *Bedarf belegen:* wiederkehrende Fehler ohne Skill sammeln.
+ *Testaufgaben zuerst:* mindestens drei realistische Aufgaben mit prüfbaren Kriterien.
+ *Minimaler Entwurf:* nur so viel, dass die Testaufgaben bestehen.
+ *Messen:* mit und ohne Skill, mehrere Läufe, alle eingesetzten Modelle; neben Qualität auch Token und Laufzeit. Da einzelne Aufgaben mit Skill schlechter werden können @li2026skillsbench, ist die Messung Pflicht und kein Luxus.
+ *Review und Freigabe* nach der Checkliste unten.
+ *Ausrollen* über eine interne Registry oder das Repository.
+ *Beobachten:* Wird der Skill ausgelöst? Welche Fehler wiederholen sich?
+ *Pflegen:* Gotchas ergänzen, Version erhöhen, Änderungen gegen die Testaufgaben prüfen.
+ *Stilllegen,* wenn der Ablauf entfällt oder der Skill nicht mehr messbar hilft.

*Freigabe-Checkliste:*
- Name gleich Ordnername; Beschreibung mit Was, Wann, Auslösern und Abgrenzung.
- `SKILL.md` unter 500 Zeilen, Wichtigstes oben, keine zeitabhängigen Aussagen.
- Referenzen eine Ebene tief, je ein Thema, Inhaltsverzeichnis ab 100 Zeilen.
- Skripte gelesen, getestet, standardmäßig nur lesend, ohne Zugangsdaten und ohne Netzwerkzugriff.
- Alle Dateien (auch Referenzen) auf Prompt Injection geprüft.
- Mindestens drei Testaufgaben mit Vergleich gegen eine Basislinie; Trigger-Tests mit positiven und negativen Anfragen.
- Besitzer, Version und Lizenz bzw. Vertraulichkeit eingetragen.
- Pflichtprüfungen zusätzlich als Hook oder in der CI.
- Keine inhaltliche Überschneidung oder Widersprüche mit bestehenden Skills.

= Grenzen und offene Fragen <sec-grenzen>
*Grenzen dieser Arbeit.*
- *Keine eigenen Messungen:* Alle Zahlen stammen aus den zitierten Quellen und gelten für deren Modelle, Werkzeuge und Aufgaben.
- *Junges Feld:* Die vier Studien, die Skills direkt untersuchen @li2026skillsbench @jiang2026demystifying @shaposhnikov2026framework @liu2026skillsecurity, sind Preprints; Befunde können sich bei Begutachtung oder mit neuen Modellen ändern.
- *Narrative Auswahl:* Ein vollständiges Such- und Screeningprotokoll fehlt; Quellen können übersehen worden sein.
- *Herstellerbezug:* Werkzeugdetails (Limits, Zusatzfelder, Vorrang) stammen aus Herstellerdokumentation und ändern sich schnell.
- *Übertragungen:* Die Wirkung von Rückkopplung und Kontextlänge ist allgemein belegt, nicht speziell für Skills. Sicherheitsmaßnahmen und Konfliktregeln sind Ableitungen, keine gemessenen Befunde.

*Offene Forschungsfragen.*
+ Wie hoch ist die Aktivierungsrate von Skills über Modelle, Werkzeuge und Beschreibungsstile hinweg? Vercel, SkillsBench und Jiang et al. verwenden unterschiedliche Aufgaben und Kennzahlen.
+ Wie lässt sich die Aktivierung ohne zusätzliche Kontextkosten verbessern?
+ Wie bleiben Skills mit dem Code, den sie beschreiben, automatisch aktuell?
+ Wie entwickelt sich der Nutzen von Skills in großen, proprietären Codebasen über längere Zeiträume? Der Zugewinn in der Softwareentwicklung war in SkillsBench vergleichsweise klein @li2026skillsbench; ob projektspezifische Skills hier mehr bringen, ist ungeklärt.
+ Wie wirken Skills mit Konflikten untereinander, und welche Vorrangmechanismen helfen?

= Schlussfolgerung <sec-schluss>
Agent Skills sind ein wirksames, werkzeugübergreifendes Mittel, um KI-Agenten Wissen zugänglich zu machen, aber nur unter Bedingungen. Bei modellgesteuerter Aktivierung entscheidet der Agent anhand verfügbarer Beschreibungen, ob er einen Skill öffnet (RQ1). Skills helfen, wenn sie von Menschen kuratiert, fokussiert und als Arbeitsablauf statt als Lexikon geschrieben sind; selbstgenerierte Skills unterliegen in den untersuchten Konfigurationen der Basislinie, und in der Softwareentwicklung liegt der Zugewinn unter dem Gesamtdurchschnitt (RQ2). Aktivierung und korrekte Anwendung hängen vom Setup ab; kurzer relevanter Kontext und überprüfbare Abläufe sind deshalb sinnvolle Gestaltungsziele (RQ3). Im Unternehmen müssen sie wie Code behandelt werden: versioniert, getestet, gemessen und als Lieferkettenrisiko abgesichert (RQ4).

Für den Einstieg in einem Team genügen fünf Schritte: wiederkehrende Fehler sammeln, drei Testaufgaben formulieren, einen kleinen Skill nach @lst-vorlage schreiben, ihn mit und ohne Skill messen und Pflichtprüfungen zusätzlich als Hook absichern.

#pagebreak()
#set page(columns: 1)
#show figure: set block(breakable: false)
#show figure.where(kind: raw): set block(breakable: false)

= Anhang A: Vollständiger Beispiel-Skill <sec-anhang-beispiel>
Der folgende Skill illustriert den Leitfaden. Er besteht aus der `SKILL.md` (@lst-beispiel-skill) und einem lesenden Strukturprüfer (@lst-beispiel-skript); projektspezifische Schema-, Sperr- und Rollback-Informationen müssen ergänzt werden. Seine Wirksamkeit wurde nicht empirisch evaluiert. PostgreSQL erlaubt `CREATE INDEX CONCURRENTLY` nicht innerhalb eines Transaktionsblocks @postgresql2026index. Eine neue Pflichtspalte braucht eine passende Einführungsstrategie; ein Default ist eine Möglichkeit, ein schrittweises Backfill eine andere @postgresql2026alter. Das Beispiel garantiert weder Datenverlustfreiheit noch einen sicheren Rollback.

#figure(
```markdown
---
name: datenbank-migration
description: >-
  Plant und prueft PostgreSQL-Migrationen des Bestellsystems.
  Verwenden bei Tabellen, Spalten, Indizes und DB-Updates.
  Nicht fuer reine Leseabfragen.
compatibility: Erfordert Python 3.10+ und eine PostgreSQL-Testdatenbank.
license: Proprietaer, nur intern
metadata:
  owner: team-plattform
  version: "1.0.0"
---

# Datenbank-Migration
Ziel: Migrations- und Wiederherstellungsplan mit geprueften Risiken.

## Vorrang
Regeln in AGENTS.md gewinnen bei Widerspruch zu diesem Skill.

## Ablauf
1. Lies das aktuelle Schema und die letzten drei Migrationen
   im Verzeichnis db/migrations/.
2. Schreibe die neue Migration mit Abschnitt `-- up` und `-- down`.
3. Fuehre den Strukturpruefer aus. Er liegt im Skill-Verzeichnis;
   verwende dessen absoluten Pfad, unabhaengig vom Arbeitsverzeichnis:
   `python <skill-verzeichnis>/scripts/pruefen.py db/migrations/<datei>.sql`
4. Korrigiere Funde und pruefe erneut, hoechstens drei Runden.
   Exit-Code 0 bestaetigt nur die gepruefte Dateistruktur.
5. Pruefe up und down in einer isolierten Testdatenbank; bewerte
   Sperren, Altversionen und Datenverlust. Aendere keine Produktion.
6. Berichte in zehn Zeilen: Aenderung, Risiko, Tests, offene Funde.

## Regeln
- Spalten erst entkoppeln, dann spaeter entfernen; pruefe vorher,
  ob Altversionen die Spalte noch verwenden und Daten gesichert sind.
- Pflichtspalten mit Default oder gestuftem Backfill einfuehren;
  teste vorhandene Daten und Schreibzugriffe alter Versionen.
- Fuer Indizes auf aktiven grossen Tabellen CONCURRENTLY pruefen;
  dies erlaubt Schreibzugriffe, aber keinen Transaktionsblock.

## Gotchas
- down fehlt oder ist leer: Rueckwaertsschritt schreiben und testen.
- CONCURRENTLY im Transaktionsblock: separate Migration verwenden.
- Datenumformung ohne Wiederherstellung: Sicherungsplan klaeren.

## Ausgabeformat
Maximal zehn Zeilen: Aenderung, Risiko, Rollback, Tests, offene Funde.

## Referenzen
- Lies die Projektdokumentation zum Schema und Rollout-Verfahren.
- Pruefe PostgreSQL-Dokumentation zu CREATE INDEX und ALTER TABLE.
```,
  caption: [Beispiel-Skill `datenbank-migration` (`SKILL.md`)],
  kind: raw,
  supplement: [Listing],
) <lst-beispiel-skill>

#figure(
```python
#!/usr/bin/env python3
"""Prueft nur up/down-Abschnitte, nicht SQL-Sicherheit oder Rollback.
Exit-Codes: 0 = sauber, 1 = Funde, 2 = Bedienfehler."""
import re
import sys

LIMIT = 20  # Ausgabe begrenzen; kein SQL-Parser

def pruefe(pfad):
    with open(pfad, encoding="utf-8") as f:
        zeilen = f.read().splitlines()
    marker = [(i, m[1].lower()) for i, z in enumerate(zeilen)
              if (m := re.fullmatch(r"\s*--\s*(up|down)\s*", z, re.I))]
    if [name for _, name in marker] != ["up", "down"]:
        return [(1, "Erwartet: genau '-- up', dann '-- down'")]
    funde = []
    for j, (start, name) in enumerate(marker):
        ende = marker[j + 1][0] if j == 0 else len(zeilen)
        inhalt = "\n".join(zeilen[start + 1:ende])
        # Heuristik: Kommentare entfernen; SQL-Literale werden nicht geparst.
        inhalt = re.sub(r"/\*.*?\*/|--[^\n]*", "", inhalt, flags=re.S)
        if not inhalt.strip(" \t\r\n;"):
            funde.append((start + 1, f"Abschnitt '{name}' ist leer"))
    return funde

def main():
    if len(sys.argv) != 2:
        print("Aufruf: pruefen.py <datei.sql>", file=sys.stderr)
        return 2
    try:
        funde = pruefe(sys.argv[1])
    except (OSError, UnicodeError) as e:
        print(f"Datei nicht lesbar: {e}", file=sys.stderr)
        return 2
    for nr, msg in funde[:LIMIT]:
        print(f"{sys.argv[1]}:{nr}: {msg}")
    if len(funde) > LIMIT:
        print(f"{len(funde) - LIMIT} weitere Funde nicht angezeigt")
    return 1 if funde else 0

if __name__ == "__main__":
    sys.exit(main())
```,
  caption: [Illustrativer Strukturprüfer; Exit-Code 0 ist kein SQL-Sicherheitsnachweis],
  kind: raw,
  supplement: [Listing],
) <lst-beispiel-skript>

= Anhang B: Vorlage für Auslösetests <sec-anhang-trigger>
Vorlage für `evals/evals.json` mit positiven, negativen und Grenzfall-Anfragen. Jede Anfrage wird mehrfach ausgeführt; gezählt wird nur ein erfolgreicher Skill-Aufruf oder eine vollständige Lektüre der `SKILL.md`.

#figure(
```json
{
  "skill": "datenbank-migration",
  "runs_per_prompt": 5,
  "cases": [
    {"prompt": "Fuege der Tabelle orders eine Spalte status hinzu",
     "expect_load": true,  "kind": "positiv"},
    {"prompt": "Schreibe ein DB-Update fuer den neuen Index",
     "expect_load": true,  "kind": "positiv"},
    {"prompt": "Wie viele Bestellungen gab es gestern?",
     "expect_load": false, "kind": "negativ"},
    {"prompt": "Erklaere den Unterschied zwischen INNER und LEFT JOIN",
     "expect_load": false, "kind": "negativ"},
    {"prompt": "Die Kundentabelle braucht ein zusaetzliches Feld",
     "expect_load": true,  "kind": "grenzfall"}
  ]
}
```,
  caption: [Vorlage für einen Trigger-Testsatz],
  kind: raw,
  supplement: [Listing],
)

#pagebreak()
= Anhang C: Glossar <sec-anhang-glossar>
#figure(
  table(
    columns: (1fr, 1.7fr),
    align: left,
    table.header([*Begriff*], [*Bedeutung in dieser Arbeit*]),
    [Agent Skill], [Verzeichnis mit `SKILL.md`, optionalen Referenzen, Skripten und Assets, das ein Agent bei Bedarf lädt],
    [Immer-Kontext], [Für die Aufgabe dauerhaft bereitgestellte Regeln; der Geltungsbereich hängt vom Werkzeug ab],
    [Progressive Offenlegung], [dreistufiges Laden: Metadaten, Anweisungen, Ressourcen],
    [Aktivierung], [Der Agent lädt den Skill tatsächlich für eine Aufgabe],
    [Prüfskript], [Skript im Skill, das Qualität misst und Funde meldet],
    [Hook], [deterministisch ausgeführte Aktion bei einem Ereignis des Agenten],
    [Gotcha], [dokumentierter, wiederkehrender Fehler mit Korrektur],
    [Subagent], [Agent mit eigenem Kontext für eine Teilaufgabe],
    [MCP], [Protokoll, über das Agenten externe Werkzeuge und Systeme nutzen],
    [Context Rot], [Leistungsabfall bei wachsender Eingabelänge @hong2025contextrot],
    [RAG], [Abruf relevanter Textstellen per Suche, um sie dem Modell mitzugeben],
    [Evidenzstärke], [stark / mittel / schwach, siehe @sec-methodik],
  ),
  caption: [Glossar der verwendeten Begriffe],
) <tab-glossar>
