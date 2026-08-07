# Engine changes to port back to mathroot

`engine/` here started as a copy of `mathroot/engine` taken on 2026-08-07, while
the MathGap Android app was inside a release freeze. Nothing in this list has
been applied to `mathroot`.

Once the app upgrade has shipped, work down this list and port each item
deliberately. Every change below alters what questions students see, which is
exactly why they were not made in `mathroot` directly.

Baseline when copied: 24 tests passing. Now: 32.

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

## 5. Stacked sums, the way an Indian exercise book sets them out

`lib/src/worksheet.dart`

Sums were printed as a line of text - "75 + 26 = ?" - with ruled lines under
them. Indian primary sheets stack the two numbers right aligned, put the
operator to the left of the lower one, and rule underneath. That rule *is* the
answer line, so the extra ruled lines were in the way.

`ColumnSum.tryParse` recognises a bare `a + b`, `a - b` or `a x b` and nothing
else. Every parse is checked against the answer the generator produced: if the
sum read off the prompt does not give that answer, the prompt is not the sum it
appears to be and the question falls back to the ordinary layout. A sheet is
all one shape or all the other, since a boxed column sum beside a line of prose
reads like a mistake.

Division is deliberately excluded. It is written under a division bracket, not
stacked, and long division needs the ruled working lines anyway.

`answerSpace` scales with the operator: 22pt for a sum or difference, but a
two-digit multiplier gets 52pt, because the child writes a partial product per
digit and then adds them. A card sized for one answer sends that working into
the margin.

The name row became a band with Name, Date and a boxed Score.

Three tests cover the parser, including that it rejects division, word
problems, and any sum that disagrees with its own answer key.

## 6. Counting sheets printed nothing to count

`lib/src/worksheet.dart`, `lib/src/question.dart` (no change), test added

`count_objects` writes its objects into the prompt as U+25CF dots. The PDF's
built-in font covers CP1252 and drops everything outside it **silently** - no
exception, no warning - so every printed counting sheet read:

    1.  How many do you see?
    2.  How many do you see?

eight times, with nothing to see and nothing to answer. On screen the app
renders with a real font, so this only ever showed up in print.

**This affects the shipped app's worksheet export.** It is the worst of the
bugs found here, because it fails in the hands of a five-year-old and reports
nothing to anyone.

`PictureCount.tryParse` now recognises those questions and the worksheet draws
the objects as vector circles, sized for a young child to count with a finger
and immune to whatever the font does or does not contain. It only triggers when
the number of dots equals the answer, so a question that merely mentions a dot
is left alone.

The same reasoning answers whether emoji could be used for the younger classes:
not through the font - they have no glyph here at all, and on the mono printers
these sheets are actually printed on they would come out as grey mush. Drawn
shapes are both printable and controllable.

**Guard added:** `unprintableInPdf(String)` plus a test that runs every
generator at every difficulty and fails if anything it would typeset cannot be
drawn. It immediately found a second case, `real-numbers` emitting a raw root
sign; that one was already handled by `pdfSafe`, which the test now applies
before checking. Port this test with the fix - it is what stops the class of
bug, not just this instance.

## 7. Printed in black and white

Worksheets are printed at home or at a corner shop, and almost always in mono.
The navy rules, tan question numbers and pale blue band all read well on screen
and turned to indistinct grey on a laser printer.

The palette is now greyscale throughout, chosen at the grey values rather than
left to the printer to derive. Verified: every ink colour in a generated sheet
has R = G = B.

## 8. Short questions get an answer box, not two ruled lines

`lib/src/worksheet.dart`

Anything that was not a bare sum fell to full-page-width prompts with two ruled
lines under each. For "Which is greater: 4/5 or 7/2?" that is a pair of
150mm rules under a one-word answer, nine questions to a page, and it looks
like a photocopy of a photocopy.

Short questions now go in cards two across, each with a bordered answer box the
full width of the card - some answers are one digit and some are
"1, 2, 3, 4, 6, 12". A Class 6 fractions sheet went from 9 questions over three
pages to 16 on one.

`needsWorkingSpace` decides, and is public so a caller offering the choice knows
what it would get by default:

- a prompt with a line break, or over 80 characters, means the sheet needs room
- `workingLines >= 3` means the teacher asked for room and gets it
- otherwise, answer boxes

One long question pulls the whole sheet over, because a sheet is all one shape
or all the other.

Long division keeps its ruled lines, which is the point of the rule.

**Watch for this if porting:** `CrossAxisAlignment.stretch` on the card row
looks right and throws. Inside a MultiPage the row height is unbounded, so
stretching asks for infinite height and the build fails.

## 9. Long division goes under a bracket

`lib/src/worksheet.dart`

"3378 / 17 = ?" on one line with two ruled lines under it is not long
division. The layout **is** the method: the quotient is written above the bar
and the working goes down the page, multiply, subtract, bring down. A sheet
that sets it out horizontally is asking for the answer without teaching the
procedure.

`LongDivision.tryParse` recognises a division and the worksheet draws the
bracket - divisor outside, dividend under the bar, blank space above it for the
quotient and blank space below for the working. Same rule as everywhere else:
it reconstructs the answer first (`divisor x quotient + remainder == dividend`,
and the remainder must be smaller than the divisor) and falls back rather than
print a sum that disagrees with its own key.

Working space scales with the dividend, because the number of
multiply-subtract-bring-down rounds is the number of digits: 7 into 42 needs
almost none, 17 into 3378 needs four. Both cards in a row take the taller one's
space - sized individually the row looks like a printing fault.

It also gets the instruction off the questions. The generator repeats "Give the
quotient and the remainder, like 7 R 3" inside every prompt; labelled
`Quotient` and `Remainder` blanks say it once per question in less room, and
exact divisions get only the quotient blank.

## 10. Four generators that could not fill a sheet

`lib/src/generators/geometry.dart`

These four are pointed at by 18 NCERT chapters between them and each had a
single question template, so a teacher asking for twenty got three.

| Generator | Distinct questions before | After | NCERT chapters |
|---|---|---|---|
| `symmetry` | 6 | 48 | 5 |
| `lines` | 3 | 396 | 3 |
| `shapes_2d` | 7 | 21 | 6 |
| `shapes_3d` | 13 | 31 | 4 |

**symmetry** had one template: lines of symmetry in six named shapes. It now
also asks about capital letters, which is how NCERT Class 6 introduces the
idea, plus order of rotational symmetry and the smallest angle of rotation. O
and Q are left out of the letters - how many lines they have depends entirely
on how they are written. A circle stays out of the shapes for the same class of
reason: infinitely many is not a whole number.

**lines** had three hardcoded facts about endpoints. It now also names the
figure from its property, counts the segments in a polygon, covers horizontal,
vertical and slanting from Class 2, names parallel, perpendicular and
intersecting, and computes AC from AB and BC for three points on a line - the
last of which is unbounded, hence 396.

**shapes_2d** and **shapes_3d** gained corner counts and naming from the
picture. Naming had to come from the picture rather than from a description,
because the existing "questions that need a picture have one" test requires it -
and it is right: a child who does not know what a heptagon looks like cannot
answer "which shape has 7 sides" either way. Naming a solid from its face,
edge and vertex counts was dropped for the same reason, and because a cube and
a cuboid share all three counts, so that question never had one answer.

Nine solids now carry full counts and three curved ones are asked only about
faces, since "how many edges has a cylinder" is a matter of convention rather
than of counting.

**Grammar:** these questions read "a octagon" and "a equilateral triangle" -
already true before this change. Added `_a()`, and a scan over every generator
at every difficulty confirms nothing now writes "a" before a vowel.

## 11. Removed, not ported

`engine/bin/sync_skill_map.dart` - copies the master skill map into
`app/assets/`. There is no app here. **Do not delete it from mathroot.**

---

## Still outstanding

14 skills still cannot fill a 20-question worksheet. Ranked by how many NCERT
chapters point at them (see `curriculum/ncert-nep.json`):

| Skill | Distinct questions | NCERT chapters |
|---|---|---|
| `constructions` | 3 | 3 |
| `triangle-congruence` | 4 | 1 |
| `data-piechart` | 6 | 1 |
| ...11 more, mostly Class 11-12 | 3-16 | 1-2 |

These need extra question templates rather than a wider number range, so each
one is real work rather than a one-line change.

`count-1-10` (8 questions) is a genuine ceiling - there are only ten numbers to
count to. Skills like it need the worksheet size capped rather than the
generator widened.
