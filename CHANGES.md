# Engine changes to port back to mathroot

`engine/` here started as a copy of `mathroot/engine` taken on 2026-08-07, while
the MathGap Android app was inside a release freeze. Nothing in this list has
been applied to `mathroot`.

Once the app upgrade has shipped, work down this list and port each item
deliberately. Every change below alters what questions students see, which is
exactly why they were not made in `mathroot` directly.

Baseline when copied: 24 tests passing. Now: 27.

---

## 1. Deduplication looked at the wrong field

`lib/src/engine_api.dart`

`generatePractice` decided two questions were the same by comparing
`q.prompt`. A bar-graph question keeps its numbers in `q.diagram` and asks the
same words every time, so every chart after the first two was thrown away.

- **Before:** asking for 20 `data-bargraph` questions returned **2**
- **After:** returns **20**

Added `questionIdentity(Question)`, which compares prompt plus diagram - what
the student actually sees. The answer is deliberately excluded: two questions
that look identical but expect different answers must never both reach one
sheet, and including the answer would let exactly that pair through.

Also documented on `generatePractice` that it can return fewer than `count`,
because for some skills that is unavoidable and callers were not checking.

**Test changed:** `practice sets avoid repeating the same question` used to
assert uniqueness by prompt - it encoded the same wrong assumption. It now
compares by `questionIdentity`.

**Test added:** `a skill with room for them returns the full count asked for`,
pinned to `data-bargraph`, so this cannot regress silently.

## 2. Four generators picked from hardcoded lists

Each of these had a genuinely unlimited domain but drew from a fixed list of
five to ten values, so a worksheet repeated itself.

| Generator | File | Distinct questions before | After |
|---|---|---|---|
| `factors` | `generators/number_theory.dart` | 10 | 32 |
| `prime_factorise` | `generators/number_theory.dart` | 10 | 63 |
| `circle_area` | `generators/mensuration.dart` | 10 | 26 |
| `pythagoras` | `generators/geometry.dart` | 14 | 66 |

The constraints those lists encoded were right and are all preserved:

- `circle_area` picks a **multiple of 7**, so both area and circumference stay
  whole numbers once pi is taken as 22/7. Now `7 * c.int_(1, ...)` instead of a
  list of five.
- `pythagoras` uses **only Pythagorean triples**, so no student meets a
  calculator. Now generated from Euclid's formula `(m^2-n^2, 2mn, m^2+n^2)`
  with a scale factor, via `_pythagoreanTriple`. Verified: 0 of 400 generated
  questions fail `a^2 + b^2 = c^2`.
- `factors` and `prime_factorise` use **smooth numbers**, so the task is
  factorising rather than primality testing. Enforced by `_largestUsefulPrime`
  (13) in `_pickComposite` and `_pickForPrimeFactorisation`.

That last constraint was **missed on the first attempt** and produced
`factors of 58 -> 1,2,29,58` and `prime-factorise 158 -> 2x79`. Both are
correct and both are bad questions. If this is ported, port the ceiling with
it.

`number_theory.dart` gained an import of `../gen_context.dart`, which it did
not previously need.

## 3. The two-column worksheet grid could not span a page

`lib/src/worksheet.dart` (copied from `app/lib/services/worksheet.dart`)

`_questionGrid` returned the whole grid as one `pw.Row`, and a Row cannot be
split across pages. Twenty-four questions with three working lines overflowed
A4 and the PDF threw rather than paginating:

    Widget won't fit into the page as its height (886.5) exceed a page
    height (773.9)

**This bug is in the shipped app too.** Any sheet long enough to need a second
page fails to build.

Replaced with `_questionRows`, which returns one widget per row so MultiPage
can break between them. Numbering now runs left to right then down, rather
than down one column and back up the other - reading order has to stay right
when a sheet spills onto page two.

Two tests added under a new `worksheets` group, one pinned to the 24-question
three-line case that used to throw.

## 4. WorksheetBuilder gained a heading

A chapter sheet draws on several skills, so titling it `skill.name` named it
after whichever skill came first - a Class 6 Chapter 7 sheet called itself
"Equivalent fractions". Added an optional `heading`, defaulting to the old
behaviour, plus `curriculumLabel` for the "Class 6 - Chapter 7" line that
replaces the `typical_class` hint when a chapter is known.

If this is ported, note the app has no curriculum file, so both stay null
there and nothing changes.

## 5. Removed, not ported

`engine/bin/sync_skill_map.dart` - copies the master skill map into
`app/assets/`. There is no app here. **Do not delete it from mathroot.**

---

## Still outstanding

18 skills still cannot fill a 20-question worksheet. Ranked by how many NCERT
chapters point at them (see `curriculum/ncert-nep.json`):

| Skill | Distinct questions | NCERT chapters |
|---|---|---|
| `shapes-2d` | 7 | 6 |
| `symmetry` | 6 | 5 |
| `shapes-3d` | 13 | 4 |
| `constructions` | 3 | 3 |
| `lines-rays` | 3 | 3 |
| `triangle-congruence` | 4 | 1 |
| `data-piechart` | 6 | 1 |
| ...11 more, mostly Class 11-12 | 3-16 | 1-2 |

These need extra question templates rather than a wider number range, so each
one is real work rather than a one-line change.

`count-1-10` (8 questions) is a genuine ceiling - there are only ten numbers to
count to. Skills like it need the worksheet size capped rather than the
generator widened.
