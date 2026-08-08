# Engine changes to port back to mathroot

`engine/` here started as a copy of `mathroot/engine` taken on 2026-08-07, while
the MathGap Android app was inside a release freeze. Nothing in this list has
been applied to `mathroot`.

Once the app upgrade has shipped, work down this list and port each item
deliberately. Every change below alters what questions students see, which is
exactly why they were not made in `mathroot` directly.

Baseline when copied: 24 tests passing. Now: 37.

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

`needsWorkingSpace` is now simply `workingLines >= 3` - the teacher decides,
and it is public so a caller offering the choice knows the default.

Guessing from the prompt was tried twice and does not work. "Through what
smallest angle can a rhombus be turned so that it looks exactly the same?" is
120 characters and needs no working at all, while a two-step word problem can
be shorter and need plenty; no threshold separates them. The first attempt
switched the whole sheet to ruled lines if any one prompt was long or contained
a line break, which turned a 20-question symmetry sheet into four pages. The
second sized the cards by the longest prompt on the sheet, which was the same
all-or-nothing failure moved one level down.

What works: **size each card by its own prompt.** Over 110 characters gets a
44pt box, over 60 gets 30pt, otherwise 21pt. The column count is still one
number for the whole grid, but it only drops to a single column past 150
characters, where half a page really is too narrow to read.

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

## 11. Counting objects vanished again on a mixed sheet

`lib/src/worksheet.dart`

The counting layout only runs when **every** question on the sheet is a
counting one. Class 1 chapter 3 is digit recognition and counting together, so
it took the ordinary card layout - and the U+25CF objects went straight back to
being dropped by the font, silently, exactly as before.

Found by an app test that builds a sheet for every chapter the form offers; the
PDF library logged `Unable to find a font to draw "●"` while the sheet built
happily.

An answer card now draws the objects itself when its question is a counting
one, so a counting question is safe wherever it lands. The all-or-nothing
layout choice stays, but nothing depends on it for correctness any more.

The lesson worth porting with it: a layout rule that decides how something is
drawn must not also decide whether it is drawn at all.

## 12. The worksheet never drew the pictures it asked about

`lib/src/worksheet_diagram.dart` (new), `lib/src/worksheet.dart`

`Question.diagram` has carried a spec since the engine was written -
`polygon:6`, `solid:pentagonal-prism`, `angle:115`, `bars:Mon=12,...`,
`pie:25`. `WorksheetBuilder` ignored the field entirely.

So a real Class 1 sheet went out reading **"What is the name of this shape?"**
with no shape on the page, twenty times over, and an answer key saying
"hexagonal prism". The bar-graph sheet was worse: the generator moved the
numbers out of the prompt and into the diagram on purpose, so the printed
question was "Books sold each day: how many were sold altogether?" with no
data anywhere on the sheet.

Five skills were affected - `shapes-2d`, `shapes-3d`, `angles-types`,
`data-bargraph`, `data-piechart` - every one of them a Class 1-3 chapter.

Diagrams are drawn with `pw.CustomPaint` rather than typeset, because the PDF's
built-in font has no glyph for a pentagonal prism and never will. Prisms and
pyramids are built from one flattened base polygon plus a rule that works out
which edges the body hides, so a new solid is a row in a map rather than a new
drawing. Hidden edges are dashed, the way a textbook draws them.

Two things had to change beyond the drawing itself:

- **Reflex angles ran off the card.** The vertex sat at a fixed spot, so a 269
  degree angle drew its second arm down through the answer box below. Nothing
  in a PDF clips it. Figures are now laid out in unit terms and fitted to the
  box afterwards (`_fitter`).
- **Bar charts showed values their own gridlines could not hit.** A bar at 37
  on a chart ruled every 5 asks a child to read a number that is not on the
  paper, and then the key marks them wrong for reading it correctly. The
  generator now produces multiples of one unit and the chart rules a line at
  the highest common factor of the bars.

**Tests added:** `every picture a generator asks for is one the worksheet can
draw` (an unknown spec is a silently blank question, so it fails the build) and
`a bar chart only ever shows values its own gridlines can hit`.

## 13. Powers printed as carets

`lib/src/worksheet.dart`

`pdfSafe` kept `¹²³` as characters because those three have CP1252 glyphs, and
turned everything else into `^4`. One sheet therefore printed `x²` a centimetre
from `x^4` - two spellings of the same idea, and a child has to work out that
they are the same idea. `(6x + 4)^2` and `8^5 / 8^2 = 8^?` printed with the
carets showing.

Every superscript now comes back to `^n` form, and `mathSpans` raises it with a
smaller font on a lifted baseline (`pw.TextSpan(baseline:)`). Real notation,
drawn rather than depending on a glyph the font does not have. Handles `^2`,
`^-3`, `^?` in a fill-the-blank, `^n`, and the bracketed `^(n-1)` a geometric
progression needs.

## 14. The level a teacher picked changed nothing, for 43 skills of 155

`lib/src/gen_context.dart` and every generator file

`c.band(easy, hard)` scales a **number**. A large class of skills has no number
to scale: "how many faces does this solid have?" is as hard as the solid is.
Those generators picked from the full list every time, so **Easiest and Hardest
produced the identical twenty questions** - measured, not guessed: 43 of the
155 skills with generators.

Added `pickByLevel<T>(List<T>)`, which takes a list **written easiest first**
and slides a window along it with the level. The window is wider than a fifth
of the list and neighbouring levels overlap, because a sheet still has to be
varied - a Hardest window of one item prints the same question twenty times.
`variantByLevel(n)` is the same thing for choosing which question shape to ask.

Applying it meant ordering a lot of lists by difficulty, which is the actual
content work: a cube before a hexagonal prism, `sin 0` before `sin 45`, SSS
before RHS, folding a letter down the middle before the letters that do not
fold at all. Where a skill's range is pinned by the skill itself
(`add-2digit-carry` is always two digits) the level moves the numbers up the
range instead.

**Two mistakes worth recording, both caught by measuring capacity afterwards:**

- Narrowing by variant emptied the easy levels of skills whose easy variants
  are single fixed facts. `circle-theorems` and `probability-events` dropped to
  **2 distinct questions** at Easiest. Both now offer every variant at every
  level and put the level in the numbers instead.
- `shapes-2d` capped at 19 rather than 20, because seven shapes cannot be both
  narrowed enough to separate the levels and wide enough to fill a sheet. Fixed
  by adding nonagon and decagon at the hard end - which is real content, not a
  workaround.

`probability-events` went from 3 distinct questions to 9 on the way past (any
dice total, not only seven) and `constructions` from 3 to 8.

**Test added:** `the level a teacher picks changes the questions, for every
skill` - it re-runs the measurement and names any skill that goes flat.

## 15. Worked solutions were generated for every question, then binned

`lib/src/worksheet.dart`

`Question.steps` has existed since the engine was written, and the doc comment
says why: *"A student who gets stuck must never hit a dead end - that is the
difference between practice that builds confidence and practice that kills
it."* Every question carries a full worked solution and most carry a hint.

`worksheet.dart` referenced `.steps`, `.hint` and `.choices` **zero times**.
The answer key printed the bare answer, so a child who got it wrong learnt
only that they were wrong.

`includeSolutions` adds a "Worked solutions" section: the question repeated so
the page stands alone, the steps, the answer, and the hint labelled *"Hint to
give"* for a teacher marking at the desk. Off by default - it is several more
pages and a teacher photocopying thirty of these pays for the paper.

Three things that only showed up on the printed page:

- **A solution split across a page break** left `Answer: 17/12` alone at the
  top of the next page with no question and no number above it. Each solution
  is wrapped in a `Stack`, which is not a `SpanningWidget`, so `MultiPage`
  moves the whole thing rather than cutting it.
- **The hint repeated twelve times.** Hints are written per skill, not per
  question, so a sheet of unlike-fraction sums printed "You cannot add until
  the bottom numbers match" on every one. Twelve identical italic lines read as
  decoration and then get skipped. A hint is now suppressed when it repeats the
  one above it.
- **Counting questions** keep their objects in the prompt as U+25CF, so the
  solutions page uses `PictureCount`'s stripped wording, as the cards do.

**Test changed:** `nothing a generator prints is silently dropped by the PDF
font` now checks steps and hints too. Nothing had ever put them on paper, so
nothing had ever checked they could be printed.

**Test added:** `worked solutions are printed, and only when asked for`, which
also asserts every question in the sample has a non-empty `steps` - a skill
with no solution would otherwise produce blank pages that nothing notices.

The app test that walks **every** chapter the form offers now builds with
solutions on, so the steps of every reachable skill get put on paper once per
run. That is what catches a dropped glyph: the PDF library warns and builds the
sheet quite happily.

## 16. Removed, not ported

`engine/bin/sync_skill_map.dart` - copies the master skill map into
`app/assets/`. There is no app here. **Do not delete it from mathroot.**

---

## Still outstanding

19 of 149 offered chapters still cannot fill a 20-question worksheet at some
level. Item 14 improved several of them (`data-piechart` 6 -> 20,
`probability-events` 3 -> 9, `constructions` 3 -> 8) and made two chapters
slightly narrower at Easiest, on purpose: a Class 1 sheet at the easiest level
should not be reaching for the digit 9.

The ones left are mostly Class 11-12, where the generator has three question
templates and no amount of level-sliding makes a fourth:

| Skill | Distinct questions | NCERT chapters |
|---|---|---|
| `definite-integrals` | 3-7 | 2 |
| `differential-equations` | 3-8 | 1 |
| `constructions` | 8 | 3 |
| `probability-events` | 9 | 1 |
| `binomial-theorem` | 4-16 | 1 |

These need extra question templates rather than a wider number range, so each
one is real work rather than a one-line change.

`count-1-10` (8 questions) is a genuine ceiling - there are only ten numbers to
count to. Skills like it need the worksheet size capped rather than the
generator widened.
