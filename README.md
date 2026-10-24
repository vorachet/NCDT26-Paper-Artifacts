# Measuring the Mission inside the Model: artifacts

Artifacts for the NCDT 2026 paper *Measuring the Mission inside the Model:
Computational Support for Mission Engineering in Arcadia and Capella*.



| What | Where |
| --- | --- |
| The DSL example: a naval combat management system with assumed values written by the authors, in the four Arcadia layers OA, SA, LA and PA | [`DSL/WarshipCombatManagement.norasi`](DSL/WarshipCombatManagement.norasi) |
| 36 screenshots of the views the add-on adds to Capella, each taken on that model | [`Screenshots/`](Screenshots) |
| The views running, in a screencast video | [Screencast Video](https://docs.google.com/videos/d/1AfebR1RBI7VI1dklc5QpczjE0rkalNtefX3jGMnSub8/play?usp=sharing) |

Every screenshot shows the DSL example open in Capella on 23 October 2026: 28 chains, 45 measures,
205 interfaces and 227 exchange items. The numbers on each screen are those of the model on that day.

## Screenshots by view

The paper's Table 1 names eight mission-engineering tasks, T1 to T8, and the views that serve each one.
The screenshots cover nine of those views.

| View | Tasks | Screenshots |
| --- | --- | --- |
| [ConOps](#conops) | T1, T2 | 05, 06, 07, 32 |
| [TPM chart](#tpm-chart) | T1, T5 | 14, 15, 16 |
| [Mission Thread](#mission-thread) | T2, T3 | 35, 36 |
| [DSL editor](#dsl-editor) | T3 | 33, 34 |
| [Boundary](#boundary) | T4 | 08, 09, 10, 11 |
| [Matrix](#matrix) | T4 | 20, 21, 22, 23, 24, 25, 26, 27, 28 |
| [Interfaces](#interfaces) | T4 | 12, 13, 29, 30, 31 |
| [Missions](#missions) | T6, T7 | 01, 02, 03, 04 |
| [RACI](#raci) | T8 | 17, 18, 19 |

The other two views in Table 1 have no screenshot here: Sensitivity (T6) and Math Functions (T3). Both
appear in the paper itself.

## ConOps

The concept of operations. The top half lists each layer's threads with their measures. The bottom half
plays one thread step by step, with each actor in its domain.

![ConOps view: the OA thread on the domain bands](Screenshots/plugin-05.png)

**`plugin-05` · ConOps.** The OA need *Air threat gone from the defended area* is selected, with arrows to
the SA, LA and PA measures that report it. Its thread plays on the domain bands at step 1 of 3: *Air
threat: Fly at the ship → Echo on the screen → Air picture operator*.

![ConOps view: the same thread with the domains as planes](Screenshots/plugin-06.png)

**`plugin-06` · ConOps.** The same thread in the layered view. Each domain is a plane, and Government,
Academic and Industry stand as columns beside them.

![ConOps view: the LA thread Logical engagement](Screenshots/plugin-07.png)

**`plugin-07` · ConOps.** The LA thread *Logical engagement* at step 1 of 11. Each logical part stands where
the OA entity it traces to stands, and each step shows its technique.

![ConOps view: the LA thread after Refresh](Screenshots/plugin-32.png)

**`plugin-32` · ConOps.** The same LA thread after Refresh. The list on the right gives each step's
function, its technique and the exchange that follows it.

## TPM chart

The TPM view evaluates the whole model at each save, or on *Evaluate*: here 4 layers in 0.42 s, with
5 BREACH. Its chart draws one column per layer, each measure normalized on its own band.

![TPM chart, OA column](Screenshots/plugin-14.png)

**`plugin-14` · TPM chart, OA column.** The needs in words, each on its scale with today's level framed:
`HOSTILE_OUTSIDE_ONLY`, `LOST_OUTSIDE_RAID`, `LEAKER_INSIDE_2_KM`, `UNPROTECTED_HOURS`.

![TPM chart, SA column](Screenshots/plugin-15.png)

**`plugin-15` · TPM chart, SA column.** Every SA MOP inside its band and OK.

![TPM chart, PA column](Screenshots/plugin-16.png)

**`plugin-16` · TPM chart, PA column.** The 5 breaches outside their bands (11.6, 2.6 and 8.1 above,
97.96 and 73.7 below), while *Q7_Ownership_Cost_MTHB_Year* stays inside at 28.

## Mission Thread

Every measure under the measure it refines, layer by layer, from the OA MOEs down to the PA MOPs.

![Mission Thread view: the tree of measures](Screenshots/plugin-35.png)

**`plugin-35` · Mission Thread.** 45 measures in 4 layers, joined by 36 arrows. The OA MOEs sit on top with
their scale and today's level; the SA, LA and PA MOPs sit beneath with their band and verdict. The header
names the 4 measures that support nothing above them.

![Mission Thread view: chains beside the tree of measures](Screenshots/plugin-36.png)

**`plugin-36` · Mission Thread.** *Thread and measures* at 37 %: each layer's chains on the left, with their
steps, parameters and techniques, and the tree of measures on the right.

## DSL editor

The whole model as one document, opened inside Capella. Capella rewrites the document at every save, so it
opens read-only; *Live mode* makes it editable, and each change goes into the model.

![DSL editor: an MOE with its band, scale, formula and RACI lines](Screenshots/plugin-33.png)

**`plugin-33` · DSL editor.** The MOE *Air_Threat_Gone_From_The_Defended_Area* with its band, scale,
today's level, formula `LEVEL('Small_Air_Target_Detection_Range_km')`, rationale and RACI lines. The
Project Explorer shows the same measure as a Capella constraint with its property values, and the guide
on the right gives the grammar of a measure.

![DSL editor: content assist offering the model's names](Screenshots/plugin-34.png)

**`plugin-34` · DSL editor.** Content assist offers every name in the model, each with the icon of its
kind. The guide gives the grammar of the whole document.

## Boundary

The layers as circles, left to right, with the entities outside them. Four tabs go from functions to
interfaces, techniques and the build plan.

![Boundary view, Functions tab](Screenshots/plugin-08.png)

**`plugin-08` · Boundary, Functions tab.** The SA and LA circles with their functions, three LA chains
drawn in their type's color, and three of the 42 techniques ticked.

![Boundary view, Interfaces tab](Screenshots/plugin-09.png)

**`plugin-09` · Boundary, Interfaces tab.** The SA system with the interface *Data_Link_Out* selected,
carrying *Own_Track_Data* to *Allied_Unit*, and its 5 associated MOPs below.

![Boundary view, Techniques tab](Screenshots/plugin-10.png)

**`plugin-10` · Boundary, Techniques tab.** Each SA function, the LA functions and techniques that carry it
out, and the PA functions that run them: 37 SA functions, 55 LA functions (42 with a technique) and 76 PA
functions.

![Boundary view, Build plan tab](Screenshots/plugin-11.png)

**`plugin-11` · Boundary, Build plan tab.** The parts to buy, 89 lines (40 hardware, 49 software), each
with its quantity, unit cost, cost and techniques; three lines are ticked.

## Matrix

The model as tables, one tab per layer, plus tabs for measures against measures, realizations, traces and
the stakeholders' N2 chart.

![Matrix view, OA tab](Screenshots/plugin-20.png)

**`plugin-20` · Matrix, OA tab.** Each OA chain, its MOE with direction, scale name and scale values, and
the entities, activities and interactions of the chain.

![Matrix view, SA tab](Screenshots/plugin-21.png)

**`plugin-21` · Matrix, SA tab.** 13 MOPs, all OK, with direction, min, value and max, against the 22
elements their formulas name.

![Matrix view, PA tab](Screenshots/plugin-22.png)

**`plugin-22` · Matrix, PA tab.** 13 MOPs, 8 OK and 5 BREACH, against the 26 nodes, behaviors and
functions their formulas name.

![Matrix view, LA tab](Screenshots/plugin-23.png)

**`plugin-23` · Matrix, LA tab.** 12 MOPs, all OK, against the 13 elements their formulas name.

![Matrix view, MOE × MOP tab](Screenshots/plugin-24.png)

**`plugin-24` · Matrix, MOE × MOP tab.** The 7 OA MOEs against the 38 MOPs below them, with R where the MOP
refines the MOE.

![Matrix view, Realizations tab](Screenshots/plugin-25.png)

**`plugin-25` · Matrix, Realizations tab.** Each OA chain and entity over what realizes it in SA, with
the measures about each element.

![Matrix view, Traces tab](Screenshots/plugin-26.png)

**`plugin-26` · Matrix, Traces tab.** One OA chain, *Mission_Defended_Area_Clear_Of_Air_Threat_For_6_Hours*,
traced through every layer, with all 45 measures and their verdicts.

![Matrix view, Stakeholders tab, PA](Screenshots/plugin-27.png)

**`plugin-27` · Matrix, Stakeholders tab, PA.** The N2 chart of the 101 PA entities and the 229 exchanges
and links between them.

![Matrix view, Stakeholders tab, SA, LA and PA](Screenshots/plugin-28.png)

**`plugin-28` · Matrix, Stakeholders tab, SA, LA and PA.** The same chart over 155 entities and 402
exchanges and links.

## Interfaces

Every interface in SA, LA and PA, as a table and as a diagram.

![Interfaces view, Matrix tab](Screenshots/plugin-12.png)

**`plugin-12` · Interfaces, Matrix tab.** 205 interfaces and 227 exchange items, each with who requires it,
who provides it and what it realizes.

![Interfaces view, Diagram tab, SA](Screenshots/plugin-13.png)

**`plugin-13` · Interfaces, Diagram tab, SA.** 15 interfaces between 10 entities, with the system's
required and provided interfaces listed on the right.

![Interfaces view, Diagram tab, LA](Screenshots/plugin-29.png)

**`plugin-29` · Interfaces, Diagram tab, LA.** 61 interfaces between 36 entities, with *Threat_Signatures*
selected: its 4 exchange items and 5 associated MOPs.

![Interfaces view, Diagram tab, PA, one interface selected](Screenshots/plugin-30.png)

**`plugin-30` · Interfaces, Diagram tab, PA.** 129 interfaces between 93 entities, with *Threat_Signatures*
selected.

![Interfaces view, Diagram tab, PA](Screenshots/plugin-31.png)

**`plugin-31` · Interfaces, Diagram tab, PA.** The same diagram with nothing selected.

## Missions

One chain at a time. Pick a parameter on the left and each measure is computed again across its range;
the graph below shows what each measure is computed from.

![Missions view, OA chain](Screenshots/plugin-01.png)

**`plugin-01` · Missions, OA chain.** *Mission_Defended_Area_Clear_Of_Air_Threat_For_6_Hours*. An OA need
reads no parameter, so the screen shows its scale with today's level, `HOSTILE_OUTSIDE_ONLY`, and the two
SA MOPs that its needed level `CLEAR_FOR_6_H` means.

![Missions view, SA chain](Screenshots/plugin-02.png)

**`plugin-02` · Missions, SA chain.** *Mission_Air_Defence_Engagement*: 2 MOPs charted against
*Evaluate_Threats.tewa_s*. *Detect_To_Engage_Advice_Time_s* moves with it and reads 6.5 against a maximum
of 10.

![Missions view, LA chain](Screenshots/plugin-03.png)

**`plugin-03` · Missions, LA chain.** *Time_Critical_Sensor_To_Track*: 3 MOPs charted against
*detect_km*, and the technique each function is computed by.

![Missions view, PA chain](Screenshots/plugin-04.png)

**`plugin-04` · Missions, PA chain.** *Opportunity_Link_16_Early_Cue*: *Link_16_Early_Warning_Time_s*
swept across *link_track_km*. Upstream, the K_TrackMan fusion measure shows 2.6 BREACH.

## RACI

Who is responsible, accountable, consulted and informed for each measure: 15 stakeholders, 45 of 45
measures with a RACI, and 90 lines in the communication plan.

![RACI view, RACI tab](Screenshots/plugin-17.png)

**`plugin-17` · RACI, RACI tab.** Each measure, by layer and chain, against each stakeholder, with R, A, C
or I in the cell.

![RACI view, Communication plan tab](Screenshots/plugin-18.png)

**`plugin-18` · RACI, Communication plan tab.** For each stakeholder and measure, when they hear of it
(before a change, on a breach, monthly) and how (meeting, message or report).

![RACI view, By stakeholder tab](Screenshots/plugin-19.png)

**`plugin-19` · RACI, By stakeholder tab.** Each stakeholder, then each layer, then each measure and the
part they play.
