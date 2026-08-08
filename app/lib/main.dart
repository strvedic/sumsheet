import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maths_engine/maths_engine.dart';
import 'package:printing/printing.dart';

import 'catalogue.dart';
import 'worksheet_request.dart';

void main() => runApp(const SumSheetApp());

const _ink = Color(0xFF1B2430);
const _accent = Color(0xFF2E5EAA);

class SumSheetApp extends StatelessWidget {
  const SumSheetApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SumSheet',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: _accent),
          scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        ),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Catalogue? _catalogue;
  Object? _loadError;

  String _classNumber = '3';
  Chapter? _chapter;
  int _count = 20;
  int _difficulty = 3;
  bool _answerKey = true;
  bool _solutions = false;
  bool _workingSpace = false;
  final _centre = TextEditingController();

  bool _busy = false;
  String? _note;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await Catalogue.load();
      if (!mounted) return;
      setState(() {
        _catalogue = c;
        _chapter = c.chaptersFor(_classNumber).firstOrNull;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e);
    }
  }

  @override
  void dispose() {
    _centre.dispose();
    super.dispose();
  }

  Future<void> _makeSheet() async {
    final c = _catalogue;
    final chapter = _chapter;
    if (c == null || chapter == null) return;
    setState(() {
      _busy = true;
      _note = null;
    });
    try {
      final skills = skillsForSelection(catalogue: c, chapter: chapter);
      final built = await buildWorksheet(
        WorksheetRequest(
          skills: skills,
          heading: chapter.title,
          curriculumLabel: 'Class ${chapter.classNumber}'
              '${chapter.part == null ? '' : ' Part ${chapter.part}'}'
              ' - Chapter ${chapter.number}',
          count: _count,
          difficulty: _difficulty,
          centreName: _centre.text.trim().isEmpty ? null : _centre.text.trim(),
          includeAnswerKey: _answerKey,
          includeSolutions: _solutions,
          workingLines: _workingSpace ? 4 : 2,
        ),
        seed: Random().nextInt(1000000),
      );
      await Printing.sharePdf(bytes: built.bytes, filename: built.filename);
      setState(() {
        // Some skills cannot make twenty different questions - counting to ten
        // has eight in it. Say so here, not at the photocopier.
        _note = built.questionCount < _count
            ? 'Downloaded with ${built.questionCount} questions. This chapter '
                'cannot make $_count different ones at this level.'
            : 'Downloaded ${built.filename}';
      });
    } catch (e) {
      setState(() => _note = 'Could not make that sheet: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Scaffold(
        body: Center(child: Text('Could not load the syllabus: $_loadError')),
      );
    }
    final c = _catalogue;
    if (c == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final chapters = c.chaptersFor(_classNumber);
    final skills = _chapter == null
        ? const <Skill>[]
        : skillsForSelection(catalogue: c, chapter: _chapter);
    // Measured the same way the sheet is built, so the slider cannot promise
    // more than the download delivers.
    final limit = skills.isEmpty
        ? 0
        : maxQuestionsFor(
            skills: skills, difficulty: _difficulty, ceiling: 40);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Masthead(),
                const SizedBox(height: 26),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Label('Class'),
                      const SizedBox(height: 8),
                      _ClassPicker(
                        value: _classNumber,
                        classes: c.curriculum.classes.map((e) => e.classNumber),
                        onChanged: (v) => setState(() {
                          _classNumber = v;
                          _chapter = c.chaptersFor(v).firstOrNull;
                          // The old filename is about the old chapter. Leaving
                          // it up reads as if this one downloaded too.
                          _note = null;
                        }),
                      ),
                      const SizedBox(height: 20),
                      _Label('Chapter'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Chapter>(
                        initialValue: _chapter,
                        isExpanded: true,
                        decoration: _fieldDecoration(),
                        items: [
                          for (final ch in chapters)
                            DropdownMenuItem(
                              value: ch,
                              child: Text(
                                '${ch.part == null ? '' : 'Part ${ch.part} '}'
                                '${ch.number}. ${ch.title}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() {
                          _chapter = v;
                          _note = null;
                        }),
                      ),
                      if (_chapter != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _chapter!.topic,
                          style: TextStyle(
                              fontSize: 13, color: _ink.withValues(alpha: 0.6)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Label('Questions'),
                      const SizedBox(height: 4),
                      _CountSlider(
                        value: _count,
                        limit: limit,
                        onChanged: (v) => setState(() => _count = v),
                      ),
                      const SizedBox(height: 18),
                      _Label('Level'),
                      const SizedBox(height: 8),
                      _DifficultyPicker(
                        value: _difficulty,
                        onChanged: (v) => setState(() => _difficulty = v),
                      ),
                      const SizedBox(height: 20),
                      _Label('Your name or your centre’s'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _centre,
                        decoration: _fieldDecoration(
                          hint: 'Printed at the top of every sheet',
                        ),
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _answerKey,
                        onChanged: (v) => setState(() => _answerKey = v),
                        title: const Text('Answer key on the last page'),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _solutions,
                        onChanged: (v) => setState(() => _solutions = v),
                        title: const Text('Worked solutions, step by step'),
                        subtitle: const Text(
                          'Every question worked through, with the hint to '
                          'give. Adds pages.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _workingSpace,
                        onChanged: (v) => setState(() => _workingSpace = v),
                        title: const Text('Ruled space to show working'),
                        subtitle: const Text(
                          'Off gives each question a box for the answer',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _busy || _chapter == null ? null : _makeSheet,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: _accent,
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Download the worksheet',
                          style: TextStyle(fontSize: 16)),
                ),
                if (_note != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _note!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: _ink.withValues(alpha: 0.7)),
                  ),
                ],
                const SizedBox(height: 30),
                Text(
                  'Every sheet is different. Print in black and white on A4.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 12.5, color: _ink.withValues(alpha: 0.45)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration({String? hint}) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD8DDE4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD8DDE4)),
      ),
    );

class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const Text('SumSheet',
              style: TextStyle(
                  fontSize: 34, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 6),
          Text(
            'Printable maths worksheets, chapter by chapter',
            style: TextStyle(fontSize: 15, color: _ink.withValues(alpha: 0.6)),
          ),
        ],
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E8ED)),
        ),
        child: child,
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: _ink),
      );
}

class _ClassPicker extends StatelessWidget {
  const _ClassPicker({
    required this.value,
    required this.classes,
    required this.onChanged,
  });

  final String value;
  final Iterable<String> classes;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final n in classes)
            ChoiceChip(
              label: Text(n),
              selected: n == value,
              onSelected: (_) => onChanged(n),
            ),
        ],
      );
}

class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const _names = {
    1: 'Easiest',
    2: 'Easier',
    3: 'Normal',
    4: 'Harder',
    5: 'Hardest',
  };

  @override
  Widget build(BuildContext context) => SegmentedButton<int>(
        segments: [
          for (final e in _names.entries)
            ButtonSegment(value: e.key, label: Text(e.value)),
        ],
        selected: {value},
        showSelectedIcon: false,
        onSelectionChanged: (s) => onChanged(s.first),
      );
}

class _CountSlider extends StatelessWidget {
  const _CountSlider({
    required this.value,
    required this.limit,
    required this.onChanged,
  });

  final int value;

  /// How many different questions this chapter can actually produce.
  final int limit;

  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    // Never offer more than the chapter can make. A teacher who slides to 40
    // and receives 8 finds out at the photocopier.
    final max = limit == 0 ? 40 : min(40, limit).clamp(4, 40);
    final shown = value.clamp(4, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Slider(
                value: shown.toDouble(),
                min: 4,
                max: max.toDouble(),
                divisions: max > 4 ? max - 4 : null,
                label: '$shown',
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
            SizedBox(
              width: 34,
              child: Text('$shown',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        if (limit > 0 && limit < 40)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              'This chapter has $limit different questions at this level.',
              style: TextStyle(fontSize: 12, color: _ink.withValues(alpha: 0.55)),
            ),
          ),
      ],
    );
  }
}
