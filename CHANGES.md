# Engine changes to port back to mathroot

`engine/` here started as a copy of `mathroot/engine` taken on 2026-08-07, while
the MathGap Android app was inside a release freeze. Nothing in this list has
been applied to `mathroot`.

Once the app upgrade has shipped, work down this list and port each item
deliberately. Every change below alters what questions students see, which is
exactly why they were not made in `mathroot` directly.

Baseline when copied: 24 tests passing. Now: 45.

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

## 16. Four generators that knew one sentence

`generators/ratio_algebra.dart`, `mensuration.dart`, `arithmetic.dart`,
`advanced.dart`

Measured first, and the measurement changed the plan. Counting *skills per
chapter* says nothing: Class 2 "Decoration for Festival" has four skills and
still only two question shapes, because all four write `a + b = ?`. Counting
**templates** - the prompt with its numbers blanked out - finds the real thing.

And most of what that flagged is not a fault. Twenty of `68 + 48 = ?` is what a
Class 2 addition sheet is *for*, and it prints as a grid of stacked column
sums. Only four skills were genuinely a whole chapter's topic asked as one
question:

| Skill | Templates before | After |
|---|---|---|
| `patterns` | 1 | 5 |
| `relations-functions` | 1 | 3 |
| `time-calc` | 1 | 3 |
| `bodmas` | 1 | 2 |

- **`patterns`** only ever asked "what is the next term?". Added the gap in the
  middle (has to be worked from both sides, which is what shows the rule rather
  than the habit), naming the rule, and the term *before* the first - which
  means undoing the rule instead of repeating it. Sequences now also count
  down, from difficulty 3.
- **`time-calc`** only asked for the arrival time. A timetable gives you two of
  {start, duration, end}: finding the end is an addition, finding the duration
  is a subtraction across the hour, finding the start is working backwards. All
  three now appear on every sheet, and the **level controls the carry across
  60** instead of which question gets asked - because finding a duration is not
  harder than finding an arrival, it is a different question. Measured: minutes
  cross the hour in 0% of questions at level 1, 31% at 3, 72% at 5.
- **`bodmas`** always printed `a + b x d - e / f`, so a child could score
  twenty out of twenty by always multiplying first and never once meet a
  bracket that overrides it - the rule the chapter is named after. `(a + b) x d`
  is now available from the easiest level, deliberately: the same numbers with
  and without a bracket *is* the lesson.
- **`functions`** only substituted into `f(x)`. Added solving `f(k) = n`
  backwards, composition `f(g(x))` (where the difficulty is that g runs first
  though f is written first), and the domain of `1/(x-a)`.

**Two bugs found while doing it, both by tests rather than by reading:**

- The existing `a question never prints its own answer` test caught
  `"How long is the journey? (like 2h 30m)"` on a question whose answer *was*
  2h 30m - the same fault the remainder questions had with "like 9 R 2". Added
  `formatExample(answer, options)`, which picks a worked example that is never
  the answer it illustrates, and applied it to the `(like 7:30)` prompts too,
  where `clock` and `time_calc` could both collide.
- Journeys **crossed midnight**: `startH` went to 20 and `durH` to 5, and the
  clock wrapped, so a train left at 20:50 and "arrived" at 1:30. Correct
  arithmetic, awful question - and much worse once the sheet started asking how
  long that journey took. `startH` is now bounded by the duration.

**Tests added:** `chapters whose topic has several ideas ask about more than
one` (a named list, since repetition is right for drill skills) and `a time
question never runs past midnight`.

Every `bodmas` prompt was also re-evaluated by an independent
recursive-descent parser honouring brackets and precedence - 1500 checked, 0
disagreed with their own answer.

## 17. "1x" and "x^1"

`lib/src/question.dart` and four generator files

Generators built algebraic terms by interpolating the coefficient straight in -
`'${a}x + $b'` - so whenever it came out 1 the sheet printed `1x^2 + 7x`,
`Solve 2x + 1 = 1x + 11`, `Integrate 4x^1`, and an answer key reading
`1x+10y`. Every one is correct arithmetic and none of it is how the textbook
the child is working from writes it.

Measured before fixing: **11 skills**, reaching the prompt, the answer, the
worked solution *and* the multiple-choice options.

`term(coefficient, variable, {power})` now builds them - 70 call sites - and
takes any `Object`, because `Fraction(2, 2)` reduces to 1 and "1x^2 + C" is as
wrong coming out of an integral as anywhere else. A coefficient of 0 is
deliberately not dropped: a vanishing term has to be left out by whoever builds
the expression, since removing it inside the helper would leave a dangling "+"
mid-line.

**Two false positives worth recording**, both found by looking at what the scan
flagged rather than trusting it:

- `time-calc` answers "1h 30m", which is the correct way to write an hour and a
  half.
- `vectors` and `pythagoras` write multiplication as `x` between two values, so
  `(-1x-5)` is -1 times -5. Those two lines were left alone - and then given
  **spaces** round the sign, because closed up `(1x-2)` genuinely reads as the
  algebraic 1x - 2.

**Answer matching was widened, not narrowed.** `_normalise` now drops a
coefficient of 1 before a letter, so a student who writes `1x+8y` is still
right, and every answer key printed before this change still matches. The
lookbehind matters: the 1 in `21x` is part of twenty-one.

Two smaller things the change exposed:

- `Integrate 4x^1` and `dy/dx = kx^1` - an exponent of 1 is not written either,
  so `term` takes a `power`.
- `linear-eq-multistep` then read "x = 4, so x = 4 / 1 = 4" - a step that does
  nothing, spelled out. It now divides only when there is something to divide
  by.

**Tests added:** `algebra is written the way algebra is written`, which checks
prompt, answer, steps, hint and choices across every skill at every level, and
`a coefficient of 1 typed in is still marked correct`, which pins both
directions of the matching including the `21x` case.

## 18. Class 9: one question per chapter, twenty times

`generators/geometry.dart`, `ratio_algebra.dart`, `data_trig.dart`

Reported by parents, not found by a test: the senior sheets were the same
question over and over with only the numbers changed, and students switched
off. Measuring it agreed - **21 of 47 Class 9-12 chapters had 2 or fewer
question shapes, and 11 had exactly one.**

A shape is the prompt with its numbers blanked out. That distinction is the
whole point: changing the numbers does not make it a different question.

This is a different fault from the junior classes, where twenty near-identical
sums is correct - that is drill, and it prints as a grid of column sums. A
Class 9 concept has several faces, and asking one face teaches a shortcut
rather than the concept.

Class 9 first, by request. Four of its eight chapters were thin:

| Skill | Shapes before | After | What was missing |
|---|---|---|---|
| `coordinate-basics` | 1 | 6 | on an axis, reflection, distance from an axis, the line through them |
| `distance-section` | 1 | 4 | midpoint, working back from a midpoint, and the **section formula the skill is named after** |
| `algebra-identities` | 1 | 4 | a^2-b^2, (x+p)(x+q), using an identity on actual numbers |
| `circle-basics` | 2 | 5 | naming the parts, longest chord, perpendicular from the centre |
| `probability-basic` | 3 | 6 | the complement, certain/impossible, a pack of cards |

Chapter totals: ch1 **2 -> 11**, ch4 5 -> 9, ch5 5 -> 13, ch7 4 -> 8.

**Four bad questions caught by reading the output rather than trusting it:**

- `divides PQ in the ratio 2 : 2` - the midpoint in a disguise, and nobody
  writes a ratio unsimplified. Ratios now come from a coprime list.
- `Use an identity to work out 7 x 7` - which makes the method look like a
  waste of time, the exact opposite of why it is taught. Bases now start at 30,
  so it is 87^2 and 98^2.
- `Expand (x + 7)(x + 7)` - anyone would write that as a square, and the square
  is the variant above it. The two numbers now differ.
- Reflecting `(-4, -2)` answers `4,-2`, and those digits sit inside the prompt
  - so the answer could be copied without reflecting anything. Caught by the
  existing `a question never prints its own answer` test. Reflections now start
  in the first quadrant, so the answer always carries a minus the prompt lacks.

**Verified independently:** 2262 coordinate and circle answers re-derived
straight from the printed prompt - distance by Pythagoras, midpoint by
averaging, the section formula recomputed, and every chord checked against
half-chord^2 + distance^2 = radius^2. Zero disagreed.

**Tests added:** `a Class 9 chapter asks about more than one thing` and `a
ratio is written in its simplest form`.

**Still to do:** Class 10, 12 and 11, on the same pattern. The worst remaining
is `heights-distances` (Class 10), where every question is a pole at 45
degrees - so a student learns "the answer is the distance" and never meets
tan 30 or tan 60. Then `determinants`, `matrices`, `vectors`,
`three-d-geometry`, `binomial-theorem`, `straight-line` and `lpp`, each of
which has exactly one question shape today.

## 19. Class 10, same treatment

`generators/data_trig.dart`, `senior.dart`, `mensuration.dart`, `geometry.dart`

Class 10 went from **6 thin chapters to 2**.

`heights-distances` was the worst generator in the app. Every question was a
pole at 45 degrees - and tan 45 is 1, so the answer was always the number
printed in the question. A student scored twenty out of twenty by copying it
across, never used a trig ratio, never met tan 30 or tan 60, and never saw an
angle of depression. It taught the shortcut instead of the chapter. Now four
shapes, with 30 and 60 kept exact by answering in the "k root 3" form the board
expects rather than making anyone fight 1.732.

| Skill | Before | After | Added |
|---|---|---|---|
| `heights-distances` | 1 | 4 | 60 degrees, 30 degrees the other way round, angle of depression |
| `arithmetic-progression` | 2 | 5 | name the common difference, which term is this, is this a term at all |
| `circle-area` | 2 | 4 | radius back from an area, and the area of a **sector** - in a chapter called Areas Related to Circles |
| `triangle-similarity` | 1 | 4 | areas scale by the square of the ratio, sides back from an area ratio, the shadow problem |

**Two bugs caught before they shipped:**

- The sector area truncated. It is `area x angle / 360`, and with pi as 22/7
  that is not whole for every pair - 154 x 90 / 360 is 38.5, and integer
  division would have printed **38** as the answer with nothing anywhere
  reporting it. Angles are now filtered to the ones that divide exactly for
  that circle.
- `triangle-similarity` offered the same multiple-choice option twice: at k = 2
  the "2k" distractor equals the k-squared answer. Caught by the existing
  duplicate-choices check.

Also `Write it as ${k}root3` was the answer itself, the third time that fault
has appeared. `formatExample` moved from `mensuration.dart` into
`question.dart` so every generator can reach it.

**Verified independently:** 5000 Class 10 answers re-derived from the printed
prompt - circle areas and circumferences recomputed from the radius, radii
recovered from areas, every sector checked for exactness, and every AP question
checked against a + (n-1)d.

**Still to do:** Class 11 (8 thin chapters) and Class 12 (11). The one-shape
generators left are `binomial-theorem`, `straight-line`, `three-d-geometry`,
`matrices`, `determinants`, `vectors`, `definite-integrals`,
`differential-equations` and `linear-programming`.

## 20. Class 11, same treatment

`generators/advanced.dart`, `senior.dart`

Class 11 went from **8 thin chapters to 0**. One of the eight fixed itself:
Sequences and Series shares `arithmetic-progression` with Class 10, so item 19
carried it over.

| Skill | Before | After | Added |
|---|---|---|---|
| `binomial-theorem` | 1 | 4 | how many terms (n+1, not n), a bare nCr, the constant term |
| `straight-line` | 1 | 5 | slope and intercept off y = mx + c, parallel and perpendicular, evaluate at x, x-intercept |
| `three-d-geometry` | 1 | 4 | a genuinely 3D distance, which octant, distance from a coordinate plane |
| `permutation-combination` | 2 | 5 | the multiplication principle, n!, and *which of the two is this* |
| `inequalities` | 2 | 4 | dividing by a negative flips the sign, smallest whole number that works |
| `grouped-data` | 1 | 3 | mean deviation, and an actual frequency table |
| `limits` | 1 | 3 | substitution with no 0/0, and a factorisation that is not a difference of squares |

Two of those were not just thin but **wrong in spirit**:

- `three-d-geometry` was not three-dimensional. dz was always 0, so every "3D
  distance" was a flat 2D one with a third number carried along unchanged.
  Fixed with Pythagorean quadruples - (2,3,6,7), (1,4,8,9), (2,6,9,11) - so the
  root stays whole with all three differences non-zero.
- `inequalities` solved every one exactly like an equation, which misses the
  single thing that makes an inequality different: dividing by a negative
  reverses the sign. That is the whole chapter and it never appeared.

`limits` was a difference of two squares over (x - a) every time, so a student
learnt "cancel and substitute" without ever having to decide whether there was
anything to cancel.

**Caught by an existing test:** the new nCr variant printed `the coefficient of
x^1`. Item 17's notation test found it immediately.

**Structure:** `straight_line`'s slope question builds its own multiple-choice
list by hand, because a slope is often negative and `choicesAround` works in
non-negatives. Rather than nest that special case inside a switch, the other
four questions live in a top-level `_lineExtras`.

**Verified independently:** 3898 Class 11 answers re-derived from their printed
prompts - every binomial coefficient recomputed, every 3D distance checked
against dx^2 + dy^2 + dz^2, and every negative-coefficient inequality checked
to confirm the printed sign really is the reversed one.

**Still to do:** Class 12, 11 thin chapters. Nine generators there still have
exactly one question shape: `matrices`, `determinants`, `vectors`,
`three-d-geometry` (Class 12 uses it too, so item 20 has already improved it),
`definite-integrals`, `differential-equations`, `linear-programming`,
`derivative-applications` and `integration`.

## 21. Class 12, and the end of the parent complaint

`generators/advanced.dart`

Class 12 went from **11 thin chapters to 0**, which closes out the whole
report. Two of the eleven had already fixed themselves: Continuity and
Differentiability shares `limits` with Class 11, and Three Dimensional
Geometry shares `three-d-geometry`.

| Skill | Before | After | Added |
|---|---|---|---|
| `matrices` | 1 | 5 | addition, scalar multiple, transpose, and **whether the product exists at all** |
| `determinants` | 1 | 4 | singular or not, solve for a missing entry, area of a triangle |
| `vectors` | 1 | 4 | magnitude, addition, and the perpendicular test |
| `linear-programming` | 1 | 3 | test every corner and pick the best, check a point against a constraint |
| `differential-equations` | 1 | 3 | order, and using an initial condition to find C |
| `definite-integrals` | 1 | 5 | a non-zero lower limit, a different integrand, a constant, area under a curve |
| `derivative-applications` | 2 | 4 | turning points, increasing or decreasing, rate of change |
| `probability-events` | 3 | 5 | the complement, a pack of cards |

Several were not merely repetitive:

- `linear-programming` handed the student one corner point. The method **is**
  testing every corner and taking the best, so the one question in the chapter
  never asked anyone to do the thing the chapter is about.
- `definite-integrals` always had a lower limit of 0, so the "subtract the
  bottom" step never did anything, and always integrated 2x, so the power rule
  was never exercised - a student could learn the single result x^2 instead of
  the rule.
- `matrices` never asked whether a product exists. That is the first thing the
  chapter teaches and a standard exam mark.

**A wrong answer caught by verification, not by reading.** The new singular
matrix question builds a second row as k times the first, then nudges it when
the answer should be "no". With a leading entry of **0** the whole first column
is zeros, so the determinant is 0 whatever the nudge does - and the generator
confidently answered "no" to a matrix that was singular. 19 of 7359 sampled
answers. The leading entry is now non-zero by construction.

**Verified independently:** 7359 Class 12 answers re-derived from their printed
prompts - every determinant recomputed as ad - bc, every solve-for-k
substituted back, every dot product and magnitude recomputed, every LPP corner
evaluated and compared, and every definite integral evaluated from its limits.

### Where the senior classes ended up

| Class | Thin chapters before | After |
|---|---|---|
| 9 | 4 | **0** |
| 10 | 6 | **0** |
| 11 | 8 | **0** |
| 12 | 11 | **0** |

**0 of 47 Class 9-12 chapters are thin.** The last two were Quadratic
Equations and Circles:

- `quadratic-formula` computed the discriminant and never used it for
  anything. What it is FOR is deciding the nature of the roots without
  solving - and the generator built every equation from two whole roots, so a
  **negative discriminant was unreachable** and "no real roots" could never be
  the answer. That case now has to be constructed deliberately. Also added
  finding k for equal roots, which is the discriminant used as an equation
  rather than as a number.
- `quadratic-factorise` only solved by factorising. The relationship between
  the roots and the coefficients - sum, product, and building the equation back
  up from its roots - is half of what the chapter is for.
- `circle-theorems` was two pieces of recall plus one angle. The Class 10
  Circles chapter is almost entirely about tangents, so the length of a tangent
  from an outside point and the angle between two tangents are in now.

**Tests added:** `a quadratic sheet can show roots that are equal, distinct or
absent`, which fails if the negative-discriminant case ever becomes unreachable
again, and `a quadratic root really satisfies its own equation`, which
substitutes every printed root back into its own printed equation.

## 22. Removed, not ported

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
