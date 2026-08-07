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

  pw.Widget _nameRow() => pw.Row(
        children: [
          pw.Text('Name: ', style: const pw.TextStyle(fontSize: 11)),
          pw.Expanded(
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                ),
              ),
              height: 15,
            ),
          ),
          pw.SizedBox(width: 26),
          pw.Text('Score: ', style: const pw.TextStyle(fontSize: 11)),
          pw.Container(
            width: 62,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
              ),
            ),
            height: 15,
          ),
        ],
      );

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
