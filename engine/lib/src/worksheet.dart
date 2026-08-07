import 'dart:typed_data';

import 'engine_api.dart';
import 'question.dart';
import 'skill_map.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Rewrites text so nothing is silently lost when the PDF is drawn.
///
/// The PDF's built-in font only covers CP1252, which has ¹ ² ³ but NOT ⁰ or
/// ⁴-⁹, and no √. Characters outside it are dropped **without any error**, so
/// "y = 5x⁴" would print as "y = 5x" - wrong maths, silently, on a sheet handed
/// to a child.
///
/// Runs made only of ¹²³ are kept, because those render properly and cover most
/// school maths. Anything else falls back to plain notation.
String pdfSafe(String s) {
  const supToDigit = {
    '⁰': '0', '¹': '1', '²': '2', '³': '3', '⁴': '4',
    '⁵': '5', '⁶': '6', '⁷': '7', '⁸': '8', '⁹': '9', '⁻': '-',
  };
  const renderable = {'¹', '²', '³'};

  final buf = StringBuffer();
  var i = 0;
  while (i < s.length) {
    final ch = s[i];
    if (!supToDigit.containsKey(ch)) {
      buf.write(ch == '√' ? 'root ' : ch);
      i++;
      continue;
    }
    // Grab the whole superscript run and decide once for all of it, so a
    // power never comes out half-raised like x²⁴.
    final run = StringBuffer();
    var allRenderable = true;
    while (i < s.length && supToDigit.containsKey(s[i])) {
      if (!renderable.contains(s[i])) allRenderable = false;
      run.write(s[i]);
      i++;
    }
    if (allRenderable) {
      buf.write(run);
    } else {
      buf.write('^');
      for (final r in run.toString().split('')) {
        buf.write(supToDigit[r]);
      }
    }
  }
  return buf.toString();
}


// Greyscale on purpose. These sheets are printed at home or at a corner shop,
// almost always in black and white, and a colour that reads well on screen
// turns into an indistinct grey on a mono laser printer. Choosing the greys
// here means the printed sheet looks the way it was designed to.
const _rule = PdfColor.fromInt(0xFF000000);
const _bandFill = PdfColor.fromInt(0xFFF2F2F2);
const _bandEdge = PdfColor.fromInt(0xFFC4C4C4);
const _numberLabel = PdfColor.fromInt(0xFF6E6E6E);
const _cardEdge = PdfColor.fromInt(0xFFB4B4B4);

/// One question written the way it is set out in an Indian exercise book: the
/// two numbers stacked and right aligned, the operator to the left of the lower
/// one, and a rule underneath for the answer.
///
/// Only a plain "a + b", "a - b" or "a x b" can be laid out this way. A word
/// problem, "which is greater", a fraction - none of those stack. Division is
/// excluded too: an Indian exercise book sets it out under a division bracket,
/// not stacked with a rule underneath, so it keeps the ordinary layout where
/// the ruled working lines suit it better anyway.
///
/// The parse is deliberately strict, and every result is checked against the
/// answer the generator produced before it is trusted: if the sum read off the
/// prompt does not give that answer, the prompt is not the sum it appears
/// to be.
class ColumnSum {
  const ColumnSum(this.left, this.op, this.right);

  final String left;
  final String op;
  final String right;

  /// How much blank space this sum needs under the rule, in points.
  ///
  /// One line is enough for a sum or a difference. Multiplying by a two-digit
  /// number is not one line: the child writes a partial product for each digit
  /// of the multiplier and then adds them, so a card sized for a single answer
  /// leaves them nowhere to work and they do it in the margin.
  double get answerSpace {
    if (op == '+' || op == '-') return 22;
    return 20 + 16.0 * right.length;
  }

  static final _pattern = RegExp(r'^(\d{1,6}) ([+\-x]) (\d{1,6}) = \?$');

  static ColumnSum? tryParse(Question q) {
    final m = _pattern.firstMatch(q.prompt.trim());
    if (m == null) return null;
    final a = int.parse(m.group(1)!);
    final b = int.parse(m.group(3)!);
    final op = m.group(2)!;
    final expected = int.tryParse(q.answer.trim());
    if (expected == null) return null;
    final got = switch (op) {
      '+' => a + b,
      '-' => a - b,
      'x' => a * b,
      _ => null,
    };
    if (got != expected) return null;
    return ColumnSum(m.group(1)!, op == 'x' ? '×' : op, m.group(3)!);
  }

  /// The widest operand, which decides how many fit across the page.
  int get width => left.length > right.length ? left.length : right.length;
}

/// Characters the PDF's built-in font cannot draw.
///
/// That font covers CP1252 and silently drops everything else - no exception,
/// no warning, just missing text on a sheet already handed to a child. Use this
/// to find out before printing rather than after.
String unprintableInPdf(String s) {
  // The scattered extras CP1252 puts in 0x80-0x9F, where Latin-1 has controls.
  const extras = '€‚ƒ„…†‡ˆ'
      '‰Š‹ŒŽ‘’“”•'
      '–—˜™š›œžŸ';
  final out = StringBuffer();
  for (final r in s.runes) {
    final ok = (r >= 0x20 && r <= 0x7e) ||
        (r >= 0xa0 && r <= 0xff) ||
        r == 0x0a ||
        r == 0x09 ||
        extras.runes.contains(r);
    if (!ok) out.writeCharCode(r);
  }
  return out.toString();
}

/// A division set out the way it is actually worked: the divisor outside the
/// bracket, the dividend inside it, blank space above the bar for the quotient
/// and blank space below for the working.
///
/// "3378 / 17 = ?" printed on one line with two ruled lines under it is not
/// long division. The layout *is* the method - the child writes the quotient
/// above the bar and subtracts down the page - so a sheet that does not set it
/// out that way is asking for the answer without teaching the procedure.
///
/// It also lets the instruction come off the questions. The generator repeats
/// "Give the quotient and the remainder, like 7 R 3" in every single prompt;
/// labelled blanks say the same thing once, per question, in less space.
class LongDivision {
  const LongDivision(this.dividend, this.divisor, this.wantsRemainder);

  final String dividend;
  final String divisor;

  /// Whether this one divides exactly. Exact sums get a quotient blank only.
  final bool wantsRemainder;

  /// Blank space to leave under the bracket, in points.
  ///
  /// Long division is worked down the page - multiply, subtract, bring down -
  /// so the number of those rounds is the number of digits in the dividend.
  /// A table fact like 7 into 42 needs almost none; 17 into 3378 needs four
  /// rounds and the room for them.
  double get workingSpace => 14.0 * dividend.length + 12;

  static final _pattern = RegExp(r'^(\d{2,7}) / (\d{1,4}) = \?');
  static final _answer = RegExp(r'^(\d+)(?: R (\d+))?$');

  static LongDivision? tryParse(Question q) {
    final m = _pattern.firstMatch(q.prompt.trim());
    if (m == null) return null;
    final a = _answer.firstMatch(q.answer.trim());
    if (a == null) return null;
    final dividend = int.parse(m.group(1)!);
    final divisor = int.parse(m.group(2)!);
    final quotient = int.parse(a.group(1)!);
    final remainder = int.tryParse(a.group(2) ?? '0') ?? 0;
    // Never lay out a division that does not reconstruct its own answer.
    if (divisor == 0) return null;
    if (divisor * quotient + remainder != dividend) return null;
    if (remainder >= divisor) return null;
    return LongDivision(
        m.group(1)!, m.group(2)!, a.group(2) != null);
  }
}

/// A counting question, with the objects to be counted.
///
/// The generator writes the objects as U+25CF dots straight into the prompt.
/// That works on screen, but the PDF's built-in font covers CP1252 only, and
/// characters outside it are dropped **silently** - so every counting sheet
/// printed "How many do you see?" with nothing to see, eight times over, and
/// nothing anywhere reported an error.
///
/// The fix is not another character. It is to stop relying on the font for
/// pictures and draw them: circles a five-year-old can actually count, at a
/// size a font would never give, in plain black that survives a mono printer.
/// The same reasoning rules out emoji, which have no glyph here at all and
/// would print as grey mush even where they do.
class PictureCount {
  const PictureCount(this.question, this.count);

  /// The words, with the row of dots taken out.
  final String question;

  /// How many objects to draw.
  final int count;

  static PictureCount? tryParse(Question q) {
    const dot = '●';
    final count = dot.allMatches(q.prompt).length;
    if (count == 0) return null;
    // Only when the objects ARE the answer. A question that happens to mention
    // a dot but asks something else must not be redrawn.
    if (int.tryParse(q.answer.trim()) != count) return null;
    final words = q.prompt
        .split(RegExp('[\r\n]+'))
        .where((line) => !line.contains(dot))
        .join(' ')
        .trim();
    if (words.isEmpty) return null;
    return PictureCount(words, count);
  }
}

/// Builds a printable worksheet PDF for one skill.
///
/// This is the teacher's tool, not the student's. A tuition teacher currently
/// writes these out by hand every week; the engine can produce an unlimited
/// supply, each one different, with the answer key already done.
class WorksheetBuilder {
  const WorksheetBuilder({
    required this.skill,
    required this.questions,
    this.centreName,
    this.heading,
    this.curriculumLabel,
    this.includeAnswerKey = true,
    this.workingLines = 2,
  });

  final Skill skill;
  final List<Question> questions;

  /// The tuition centre's name, printed at the top. Small thing, but it is
  /// what makes the sheet feel like the teacher's own rather than an app's.
  final String? centreName;

  /// What the sheet is called, printed largest. Defaults to the skill's name,
  /// which is right for a single-skill sheet and wrong for a chapter one - a
  /// chapter draws on several skills, so naming it after whichever came first
  /// tells the teacher the sheet is something narrower than it is.
  final String? heading;

  /// Where this sits in the syllabus, e.g. "Class 6 - Chapter 7 Fractions".
  ///
  /// The skill's own `typical_class` is a rough ability hint ("5-6") and says
  /// nothing a teacher can check against their timetable. When the sheet was
  /// built from a chapter, print the chapter.
  final String? curriculumLabel;

  final bool includeAnswerKey;

  /// Ruled lines printed under each question for the student to work in.
  ///
  /// A worksheet with nowhere to write is not a worksheet. Two lines suits
  /// straight sums; word problems and long division need four or five.
  final int workingLines;

  /// Generates a worksheet with [count] fresh questions for [skill].
  static List<Question> pick({
    required Skill skill,
    required int count,
    required int difficulty,
    int? seed,
  }) =>
      generatePractice(
        skill: skill,
        count: count,
        difficulty: difficulty,
        seed: seed ?? DateTime.now().millisecondsSinceEpoch % 1000000,
      );

  Future<Uint8List> build() async {
    final doc = pw.Document();
    final date = DateTime.now();
    final dateStr = '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(38, 34, 38, 34),
        header: (ctx) => ctx.pageNumber == 1
            ? pw.SizedBox()
            : pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Text(
                  skill.name,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (ctx) => [
          _title(dateStr),
          pw.SizedBox(height: 18),
          _nameRow(),
          pw.SizedBox(height: 20),
          // Two columns keeps a 20-question sheet on one page, which is what
          // a teacher photocopying for a class actually wants.
          ..._questionRows(),
        ],
      ),
    );

    if (includeAnswerKey) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(38, 34, 38, 34),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Answer key',
                style: pw.TextStyle(
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${heading ?? skill.name}  -  $dateStr',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 16),
              pw.Wrap(
                spacing: 26,
                runSpacing: 7,
                children: [
                  for (var i = 0; i < questions.length; i++)
                    pw.SizedBox(
                      width: 110,
                      child: pw.Text(
                        '${i + 1}.  ${pdfSafe(questions[i].answer)}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return doc.save();
  }

  pw.Widget _title(String dateStr) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (centreName != null && centreName!.trim().isNotEmpty) ...[
            pw.Text(
              centreName!.trim(),
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 3),
          ],
          pw.Text(
            heading ?? skill.name,
            style: pw.TextStyle(fontSize: 19, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            '${curriculumLabel ?? 'Class ${skill.typicalClass}'}'
            '  -  ${questions.length} questions  -  $dateStr',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 0.8, color: PdfColors.grey400),
        ],
      );

  /// Name, date and score, in a band across the top.
  ///
  /// Ruled rather than boxed, because a teacher writes the child's name here
  /// with a pen and a box a millimetre too small is worse than a line.
  pw.Widget _nameRow() => pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: pw.BoxDecoration(
          color: _bandFill,
          border: pw.Border.all(color: _bandEdge, width: 0.7),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _field('Name', flex: 5),
            pw.SizedBox(width: 20),
            _field('Date', flex: 3),
            pw.SizedBox(width: 20),
            pw.Text('Score',
                style: pw.TextStyle(
                    fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(width: 7),
            pw.Container(
              width: 46,
              height: 19,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: _rule, width: 0.7),
                borderRadius: pw.BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      );

  pw.Widget _field(String label, {required int flex}) => pw.Expanded(
        flex: flex,
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(width: 7),
            pw.Expanded(
              child: pw.Container(
                height: 13,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom:
                        pw.BorderSide(color: PdfColors.grey500, width: 0.6),
                  ),
                ),
              ),
            ),
          ],
        ),
      );


  /// Every question, laid out as a stacked sum, or null if even one of them
  /// cannot be. A sheet is all one shape or all the other - mixing a boxed
  /// column sum next to a line of prose looks like a mistake.
  List<ColumnSum>? get _asColumnSums {
    final out = <ColumnSum>[];
    for (final q in questions) {
      final s = ColumnSum.tryParse(q);
      if (s == null) return null;
      out.add(s);
    }
    return out;
  }

  /// Stacked sums in a card grid, the way an Indian exercise book sets them
  /// out. No ruled lines under the question: the rule beneath the sum is where
  /// the answer goes, so a second set of lines would only be in the way.
  List<pw.Widget> _columnCards(List<ColumnSum> sums) {
    // Four across is the usual textbook grid. Wide operands need more room, so
    // drop to three rather than let the digits crowd the card edge.
    final widest = sums.map((s) => s.width).reduce((a, b) => a > b ? a : b);
    final perRow = widest >= 5 ? 3 : 4;

    pw.Widget card(int i) {
      final s = sums[i];
      final digit = pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 1.4,
      );
      return pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(11, 7, 11, 9),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _cardEdge, width: 0.8),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '${i + 1}.',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _numberLabel,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(s.left, style: digit),
            ),
            pw.SizedBox(height: 3),
            pw.Row(
              children: [
                pw.Text(s.op, style: digit),
                pw.Expanded(
                  child: pw.Container(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(s.right, style: digit),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            // The answer line. Nothing is printed under it - that space is the
            // child's.
            pw.Container(height: 1.1, color: _rule),
            pw.SizedBox(height: s.answerSpace),
          ],
        ),
      );
    }

    return [
      for (var i = 0; i < sums.length; i += perRow)
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 11),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (var col = 0; col < perRow; col++) ...[
                if (col > 0) pw.SizedBox(width: 11),
                pw.Expanded(
                  child: i + col < sums.length ? card(i + col) : pw.SizedBox(),
                ),
              ],
            ],
          ),
        ),
    ];
  }

  /// The objects to be counted, drawn rather than typeset.
  pw.Widget _dots(int count) => pw.Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (var n = 0; n < count; n++)
            pw.Container(
              width: 13,
              height: 13,
              decoration: const pw.BoxDecoration(
                color: _rule,
                shape: pw.BoxShape.circle,
              ),
            ),
        ],
      );

  /// Every question as a counting picture, or null if any of them is not one.
  List<PictureCount>? get _asPictureCounts {
    final out = <PictureCount>[];
    for (final q in questions) {
      final p = PictureCount.tryParse(q);
      if (p == null) return null;
      out.add(p);
    }
    return out;
  }

  /// Counting cards: the words, the objects drawn large enough to count with a
  /// finger, and a box to write the number in.
  List<pw.Widget> _pictureCards(List<PictureCount> counts) {
    pw.Widget card(int i) {
      final p = counts[i];
      return pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(11, 7, 11, 10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _cardEdge, width: 0.8),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '${i + 1}.',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _numberLabel,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(pdfSafe(p.question),
                style: const pw.TextStyle(fontSize: 10.5)),
            pw.SizedBox(height: 9),
            _dots(p.count),
            pw.SizedBox(height: 11),
            pw.Row(
              children: [
                pw.Text('Answer',
                    style: const pw.TextStyle(fontSize: 9.5, color: _numberLabel)),
                pw.SizedBox(width: 7),
                pw.Container(
                  width: 34,
                  height: 22,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _rule, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Three across: ten dots plus a box needs more width than a two-digit sum.
    return [
      for (var i = 0; i < counts.length; i += 3)
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 11),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (var col = 0; col < 3; col++) ...[
                if (col > 0) pw.SizedBox(width: 11),
                pw.Expanded(
                  child:
                      i + col < counts.length ? card(i + col) : pw.SizedBox(),
                ),
              ],
            ],
          ),
        ),
    ];
  }

  /// True when the sheet is ruled for working rather than boxed for answers.
  /// Public because a caller offering the choice has to know the default.
  ///
  /// Only the teacher decides this now. Guessing from the prompt does not
  /// work: "Through what smallest angle can a rhombus be turned so that it
  /// looks exactly the same?" is 120 characters and needs no working at all,
  /// while a two-step word problem can be shorter and need plenty. Any
  /// threshold that catches the one catches the other.
  ///
  /// So the card layout takes long questions too, giving them a deeper box and
  /// the full width, instead of switching the whole sheet over.
  bool get needsWorkingSpace => workingLines >= 3;

  /// Questions in cards, each with a box to write the answer in.
  ///
  /// Two across fits a fraction or a "which is greater" comfortably and puts
  /// twenty on one page instead of nine. A long question means more to work
  /// out, so those get one card per row and a deeper box - the same card,
  /// scaled, rather than a different layout.
  List<pw.Widget> _answerCards() {
    // Sized per card, not per sheet. Sizing by the longest prompt let one
    // 120-character symmetry question turn all twenty into full-width cards
    // with a working box none of them needed - the same all-or-nothing that
    // switching layouts caused, just moved.
    double boxFor(Question q) => q.prompt.length > 110
        ? 44.0
        : q.prompt.length > 60
            ? 30.0
            : 21.0;

    // The grid still needs one column count. Only drop to a single column for
    // sheets that are word problems throughout, where half a page is genuinely
    // too narrow to read.
    final longest =
        questions.map((q) => q.prompt.length).reduce((a, b) => a > b ? a : b);
    final perRow = longest > 150 ? 1 : 2;

    pw.Widget card(int i) {
      final picture = PictureCount.tryParse(questions[i]);
      return pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(10, 6, 10, 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _cardEdge, width: 0.8),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 19,
                    child: pw.Text(
                      '${i + 1}.',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: _numberLabel,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // A counting question keeps its objects in the prompt
                        // as U+25CF, which this font cannot draw. On a sheet
                        // that is nothing but counting they get their own
                        // layout; on a mixed one they would silently vanish,
                        // so draw them here too.
                        pw.Text(
                          pdfSafe(picture?.question ?? questions[i].prompt),
                          style:
                              const pw.TextStyle(fontSize: 11, lineSpacing: 2),
                        ),
                        if (picture != null) ...[
                          pw.SizedBox(height: 8),
                          _dots(picture.count),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 7),
              // Full width rather than a small box: some answers are a single
              // digit and some are "1, 2, 3, 4, 6, 12".
              pw.Container(
                height: boxFor(questions[i]),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _rule, width: 0.7),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
              ),
            ],
          ),
      );
    }

    return [
      for (var i = 0; i < questions.length; i += perRow)
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 9),
          child: pw.Row(
            // Not stretch: inside a MultiPage the row height is unbounded, so
            // stretching asks for infinite height and the build throws.
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (var col = 0; col < perRow; col++) ...[
                if (col > 0) pw.SizedBox(width: 10),
                pw.Expanded(
                  child: i + col < questions.length
                      ? card(i + col)
                      : pw.SizedBox(),
                ),
              ],
            ],
          ),
        ),
    ];
  }

  /// Every question as a long division, or null if any of them is not one.
  List<LongDivision>? get _asLongDivisions {
    final out = <LongDivision>[];
    for (final q in questions) {
      final s = LongDivision.tryParse(q);
      if (s == null) return null;
      out.add(s);
    }
    return out;
  }

  /// Division brackets, two across, with the page to work down.
  List<pw.Widget> _divisionCards(List<LongDivision> sums) {
    final digit = pw.TextStyle(
      fontSize: 13,
      fontWeight: pw.FontWeight.bold,
      letterSpacing: 1.4,
    );

    pw.Widget blank(String label) => pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(label,
                style: const pw.TextStyle(fontSize: 9, color: _numberLabel)),
            pw.SizedBox(width: 5),
            pw.Expanded(
              child: pw.Container(
                height: 12,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: _rule, width: 0.7),
                  ),
                ),
              ),
            ),
          ],
        );

    // Both cards in a row get the taller one's working space. Sized
    // individually they come out uneven, and a row where one box is shorter
    // than its neighbour reads as a printing fault rather than as a smaller sum.
    pw.Widget card(int i, double space) {
      final s = sums[i];
      return pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(11, 7, 11, 9),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _cardEdge, width: 0.8),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '${i + 1}.',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _numberLabel,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Row(
              // Bottom aligned, so the divisor and the bracket sit on the
              // dividend's line while the quotient space rises above the bar.
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(s.divisor, style: digit),
                pw.SizedBox(width: 3),
                pw.Text(')', style: digit),
                pw.SizedBox(width: 1),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Where the quotient is written, above the bar.
                    pw.SizedBox(height: 17),
                    pw.Container(
                      padding: const pw.EdgeInsets.only(top: 2, right: 4),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(color: _rule, width: 1),
                        ),
                      ),
                      child: pw.Text(s.dividend, style: digit),
                    ),
                  ],
                ),
              ],
            ),
            // Multiply, subtract, bring down - that happens down the page, so
            // the page has to be there.
            pw.SizedBox(height: space),
            blank('Quotient'),
            if (s.wantsRemainder) ...[
              pw.SizedBox(height: 7),
              blank('Remainder'),
            ],
          ],
        ),
      );
    }

    final rows = <pw.Widget>[];
    for (var i = 0; i < sums.length; i += 2) {
      final space = sums
          .skip(i)
          .take(2)
          .map((s) => s.workingSpace)
          .reduce((a, b) => a > b ? a : b);
      rows.add(pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: card(i, space)),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: i + 1 < sums.length ? card(i + 1, space) : pw.SizedBox(),
            ),
          ],
        ),
      ));
    }
    return rows;
  }

  /// The questions, as separate widgets so a long sheet can flow onto page 2.
  ///
  /// Returning one widget for the whole grid used to throw: a two-column Row
  /// cannot be split, so 24 questions with three working lines overflowed the
  /// page and the PDF failed to build at all. Each row is now its own widget,
  /// and MultiPage breaks between them.
  ///
  /// Numbering therefore runs left to right, then down - 1 and 2 side by side -
  /// rather than all the way down one column and back up the other. Reading
  /// order has to stay right when a sheet spills onto a second page.
  List<pw.Widget> _questionRows() {
    final sums = _asColumnSums;
    if (sums != null) return _columnCards(sums);

    final pictures = _asPictureCounts;
    if (pictures != null) return _pictureCards(pictures);

    final divisions = _asLongDivisions;
    if (divisions != null) return _divisionCards(divisions);

    if (!needsWorkingSpace) return _answerCards();

    // Prompts that span multiple lines (word problems, ordering questions)
    // need the full width; short sums do not.
    final wide = questions.any((q) => q.prompt.length > 46);
    if (wide) {
      return [
        for (var i = 0; i < questions.length; i++) _questionBlock(i, 1),
      ];
    }
    return [
      for (var i = 0; i < questions.length; i += 2)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _questionBlock(i, 2)),
            pw.SizedBox(width: 22),
            pw.Expanded(
              child: i + 1 < questions.length
                  ? _questionBlock(i + 1, 2)
                  : pw.SizedBox(),
            ),
          ],
        ),
    ];
  }

  pw.Widget _questionBlock(int i, int columns) => pw.Container(
        margin: pw.EdgeInsets.only(bottom: columns == 1 ? 14 : 12),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 22,
              child: pw.Text(
                '${i + 1}.',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    pdfSafe(questions[i].prompt.replaceAll('\n\n', '\n')),
                    style: const pw.TextStyle(fontSize: 12, lineSpacing: 2.5),
                  ),
                  pw.SizedBox(height: 9),
                  // Somewhere to actually write. Light grey so the student's
                  // pencil stands out against it rather than competing.
                  for (var line = 0; line < workingLines; line++)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 13),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                            color: PdfColors.grey400,
                            width: 0.6,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}
