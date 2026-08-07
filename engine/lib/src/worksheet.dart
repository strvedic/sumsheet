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


// The sheet's colours, kept together so a whole worksheet can be restyled in
// one place rather than hunted through the widget tree.
const _rule = PdfColor.fromInt(0xFF1F3864);
const _bandFill = PdfColor.fromInt(0xFFF2F5FA);
const _bandEdge = PdfColor.fromInt(0xFFD6DEEA);
const _numberLabel = PdfColor.fromInt(0xFFB8945A);
const _cardEdge = PdfColor.fromInt(0xFFDCE0E6);

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
                color: PdfColors.blueGrey800,
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
