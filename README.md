# SumSheet

Printable maths worksheets for Indian classrooms, chapter by chapter.

Pick a class and a chapter, get an A4 PDF with an answer key. Every sheet is
different, and every sheet is black and white, because these get printed at
home or at a corner shop.

## What it does

- **155 NCERT chapters**, Class 1 to 12, mapped onto a board-independent skill
  graph. `curriculum/ncert-nep.json` is that mapping; `curriculum/GAPS.md` is
  what compiling it exposed.
- **Questions are generated, not stored.** Ask for the same chapter twice and
  the sheets differ.
- **Set out the way Indian exercise books set it out.** Sums stack, four across.
  Long division goes under a bracket with the quotient above the bar. Counting
  objects are drawn, not typed.
- **The teacher's name at the top**, so the sheet belongs to whoever handed it
  out.

## Layout

```
engine/        Pure Dart. Skill graph, question generators, and the A4
               worksheet itself. No Flutter dependency, so it tests fast.
  bin/worksheet.dart   Command line: one PDF, no browser needed.
app/           Flutter web front end.
curriculum/    The NCERT chapter mapping and the gap report.
skill-map.json The skill graph - 155 skills, LKG through Class 12.
CHANGES.md     Engine changes to port back to the MathGap app.
```

## Running it

```bash
cd engine && dart test
cd engine && dart run bin/worksheet.dart --class 6 --chapter 7 --count 20
cd app && flutter test
cd app && flutter run -d chrome
```

The command line covers everything the web form does:

```bash
dart run bin/worksheet.dart --list-chapters 6
dart run bin/worksheet.dart --skill long-division --count 8 --lines 4
dart run bin/worksheet.dart --class 3 --chapter 8 --centre "Sri Vidya Tuition"
```

`--seed N` reproduces an exact sheet, so a worksheet handed out last week can
be printed again.

## Hosting

Every push to `main` builds the web app and publishes it to GitHub Pages, which
serves it at the domain in `app/web/CNAME`.

Two things are tied together and will break the site quietly if they drift:

- **`app/web/CNAME`** holds the custom domain. It lives in `app/web/` rather
  than the repository root because the deploy publishes `app/build/web` as an
  artifact, and Flutter copies `web/` into that. A `CNAME` anywhere else is not
  in what gets published.
- **`--base-href` in `.github/workflows/deploy.yml`** must match where the site
  sits on that domain. It is `/` because the site is at the root of its own
  subdomain; it was `/sumsheet/` when the site was served from
  `strvedic.github.io/sumsheet/`. Get this wrong and the page loads, every
  asset 404s, and the result is a blank white screen.

DNS is a single `CNAME` record pointing the subdomain at `strvedic.github.io`.
It must be **DNS only**, not proxied - a proxy in front stops GitHub verifying
the domain, so the HTTPS certificate is never issued. If a proxy is turned on
later, its TLS mode has to be full/strict, or GitHub redirecting to HTTPS and
the proxy answering over HTTP loop against each other forever.

## Where the engine came from

`engine/` is a copy of the engine behind MathGap, taken while that app was in a
release freeze so that changes here could not alter what its students see.
`CHANGES.md` lists every change made since, with the reasoning, for porting back
once the app upgrade has shipped. Several of them are bugs the app still has.

## A note on the NCERT books

`curriculum/ncert-nep.json` records chapter numbers, titles and topics - a
curriculum index, which is fact. The textbooks themselves are copyrighted and
are not in this repository, and no question here is taken from them. The
mapping says which skills a chapter covers; the questions are the engine's own.
