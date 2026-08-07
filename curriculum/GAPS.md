# Curriculum gap report

What fell out of mapping all 155 NCERT chapters (Class 1-12) onto the 155 skills in
`skill-map.json`. Compiled 2026-08-07 from the Reprint 2026-27 printings.

Nothing here has been applied. `skill-map.json` is untouched.

Coverage: **147 of 155 skills** are reached by at least one NCERT chapter.
**6 chapters** map to no skill at all.

---

## 1. The Class 9 to Class 10 cliff

The 2026-27 shelf holds a **new 8-chapter Class 9 book** and the **old rationalised
14-chapter Class 10 book**. They do not line up.

### Missing

| Class 10 chapter | What it assumes | Last taught |
|---|---|---|
| Ch6 Triangles (similarity) | congruence, basic proportionality | **Class 7 Part 2 Ch1** - a two-year gap, and similarity itself appears nowhere first |
| Ch12 Surface Areas and Volumes | surface area and volume of cylinder, cone, sphere | **nowhere in Classes 6-9** - see below |
| Ch13 Statistics (grouped data) | frequency tables, grouped mean/median/mode | Class 8 Part 2 Ch5 covers ungrouped mean/median only |
| Ch3 Pair of Linear Equations in Two Variables | linear equations in two variables | Class 9 Ch2 is *Linear Polynomials* - partial |

**The 3D mensuration hole is the sharpest finding in the whole set.** Volume and surface
area of solids is taught in **no chapter of Class 6, 7, 8 or 9**:

- Class 6 Ch6 *Perimeter and Area* - sections 6.1 Perimeter, 6.2 Area, 6.3 Area of a Triangle. All 2D.
- Class 7 - **no mensuration chapter at all**, in either part.
- Class 8 Part 2 Ch7 *Area* - section 7.1 Rectangle and Squares. 2D.
- Class 9 Ch6 *Measuring Space* - perimeter of a circle, arc length, area of rectangle,
  parallelogram, triangle, circle. All 2D. The book's own preface says the chapter
  "addresses two-dimensional figures".

Class 10 Ch12 then opens at `12.2 Surface Area of a Combination of Solids`. A student is
asked to combine solids whose individual formulas were never taught.

Good news: `surface-area-cuboid`, `volume-cuboid` and `solids-advanced` already exist in
`skill-map.json` and already generate questions. The scaffold is built - it just has no
NCERT chapter behind it, which is exactly the kind of hole this app exists to fill.

### Duplicated

| New Class 9 | Repeated in |
|---|---|
| Ch8 Sequences and Progressions (AP **and** GP) | Class 10 Ch5 (AP), Class 11 Ch8 (GP) |
| Ch7 Introduction to Probability | Class 10 Ch14 |
| Ch1 Use of Coordinates | Class 10 Ch7 |

### Suggested product

A **Class 9 to 10 bridge pack**: three skills with no NCERT chapter behind them
(`surface-area-cuboid`, `volume-cuboid`, `solids-advanced`) plus `triangle-similarity`
scaffolding from `triangle-congruence`. Small, specific, dated, and it applies to the
whole 2026-27 Class 10 cohort.

---

## 2. Chapters with no matching skill

| Class | Chapter | Content | Proposed |
|---|---|---|---|
| 4 | Ch2 Hide and Seek | top / side / front views, perspective | `spatial-views` |
| 5 | Ch14 Maps and Locations | maps, direction, position | `maps-location` |
| 8 P2 | Ch4 Exploring Some Geometric Themes | fractals, visualising solids, isometric projections | `spatial-views` (upper rung) |
| 8 P1 | Ch3 A Story of Numbers | early number systems, the idea of a base, positional notation | `number-bases` |
| 11 | Ch10 Conic Sections | circle, parabola, ellipse, hyperbola | `conic-sections` |
| 12 P1 | Ch2 Inverse Trigonometric Functions | basic concepts and properties | `inverse-trig` |

### Spatial reasoning is a deliberate NCERT ladder with no counterpart here

Class 3 Ch2 position words, Class 4 Ch2 views, Class 5 Ch14 maps, Class 8 Part 2 Ch4
isometric projections. Four chapters across six years. The geometry strand in
`skill-map.json` goes `shapes-2d` -> `shapes-3d` -> `lines-rays` with nothing in between
for visualisation. This is the largest single strand gap.

---

## 3. Entry points that sit too high

| Skill | Currently | NCERT introduces it |
|---|---|---|
| `patterns` | L6, class 4-5 | Class 1 Ch9, Class 4 Ch3, Class 5 Ch7, Class 6 Ch1 |
| `constructions` | L9, class 6-10 | Class 6 Ch8 *and* Class 7 P2 Ch6 - two distinct levels |
| `rounding` ("Rounding and estimation") | L6, class 5-6 | estimation as a strategy from Class 3 Ch3 |

`patterns` is one node covering four chapters across five years. It needs a ladder:
visual pattern -> number pattern -> algebraic rule.

`rounding` conflates two different things. "Guess how many bangles" (Class 3) is not
"round 4,738 to the nearest hundred" (Class 5). Proposed split: `estimate-quantity`.

---

## 4. Missing prerequisite: number bonds

Class 1 Ch4 *Making 10* and Class 3 Ch4 *Vacation with My Nani Maa* are both built on the
same idea - `15` total, `12` visible, how many hidden. `skill-map.json` has
`add-within-10` and `add-within-20`, but nothing for `7 + __ = 12`.

This is a classic gap generator. A child who can compute `7 + 5` will still stall on
`7 + __ = 12`, and every later missing-value problem inherits the stall. Two NCERT
chapters, no skill.

Proposed: `number-bonds` (missing addend within 20), prereq `add-within-10`, unlocked
before `sub-within-20`.

---

## 5. Smaller gaps

| Tag | Where | Note |
|---|---|---|
| `line-orientation` | Class 2 Ch5 | horizontal / vertical / slanting; `lines-rays` is L6, too high |
| `tiling` | Class 5 Ch11, Class 7 P2 Ch6 | tessellation has no skill; mapped to `symmetry` as a stand-in |
| `co-primes` | Class 6 Ch5 | not covered by `factors` or `hcf` |
| `inverse-proportion` | Class 8 P2 Ch3 | `proportion-unitary` covers direct only |

---

## 6. Level 6 is overloaded

```
skills per level:  1:5  2:7  3:12  4:7  5:8  6:23  7:13  8:19  9:23  10:16  11:11  12:11
```

Level 6 holds 23 skills - 15% of the map - spanning `fraction-concept` (class 3-4) to
`hcf` (class 6). Within a level, `skill_map.dart:202` falls back to alphabetical id:

```dart
final byLevel = skills[a]!.level.compareTo(skills[b]!.level);
```

So a Class 3-4 study plan can order `bodmas` and `divisibility-rules` **before**
`fraction-concept`, because "b" and "d" sort before "f". Sequencing inside Level 6 is
alphabetical, not pedagogical.

The prerequisite graph itself is sound - `fraction-concept` correctly requires
`div-concept`, which matches NCERT putting *Fair Share* (Class 3 Ch8) after sharing and
grouping. It is the level numbers that are blunt.

Proposed: split Level 6 into early fractions / number theory / late fractions. No code
change needed.

---

## 7. Skills no NCERT chapter names

Eight skills are not referenced by any chapter in `ncert-nep.json`:

```
decimal-fraction-convert  decimal-rounding  fraction-simplify  linear-eq-word
muldiv-wordproblem        profit-loss       simple-interest    time-work-speed
```

These are not errors. Every one of them is taught *inside* a chapter rather than as a
chapter - `profit-loss` and `simple-interest` live inside Class 8 Part 2 Ch1
*Fractions in Disguise*, `fraction-simplify` inside Class 6 Ch7. They are listed here only
so the absence is on the record and not mistaken for missing coverage later.

---

## Proposed new skills, in priority order

| Id | Strand | Why |
|---|---|---|
| `number-bonds` | addsub | two chapters, classic gap generator, foundation level |
| `spatial-views` | geometry | four chapters across six years, whole ladder missing |
| `estimate-quantity` | number | taught from Class 3, currently conflated with rounding |
| `patterns-visual` | algebra | splits the single overloaded `patterns` node |
| `maps-location` | geometry | Class 5 Ch14 |
| `number-bases` | numtheory | Class 8 P1 Ch3 |
| `tiling` | geometry | Class 5 Ch11, Class 7 P2 Ch6 |
| `inverse-proportion` | ratio | Class 8 P2 Ch3 |
| `conic-sections` | advanced | Class 11 Ch10 |
| `inverse-trig` | trig | Class 12 P1 Ch2 |

The first four sit in the Class 1-8 band where the app's gap-finding actually operates.
The last two are Class 11-12 completeness and can wait.
