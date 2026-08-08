import 'dart:math';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Draws the pictures that questions are about.
///
/// [Question.diagram] has always carried a spec - "polygon:6", "solid:cube",
/// "bars:Mon=12,..." - and the worksheet has always ignored it. That is not a
/// missing nicety. "What is the name of this shape?" printed with no shape is
/// an unanswerable question, and a sheet of them went out with an answer key
/// saying "hexagonal prism" to a child who was shown nothing at all.
///
/// So these are drawn, not typeset. The PDF's built-in font has no glyph for a
/// pentagonal prism, and drawing with lines means the same spec prints at any
/// size, in plain black that survives a mono photocopier.

/// Ink weights. Solid black for what the child can see, a lighter dash for the
/// edges hidden round the back - the convention every school textbook uses, and
/// the thing that makes a flat drawing read as a solid.
const _ink = PdfColor.fromInt(0xFF000000);
const _hidden = PdfColor.fromInt(0xFF9A9A9A);
const _shade = PdfColor.fromInt(0xFFD9D9D9);
const _axis = PdfColor.fromInt(0xFF5A5A5A);
const _grid = PdfColor.fromInt(0xFFD0D0D0);

/// How much room a spec needs, so a card can be laid out before it is drawn.
class DiagramSize {
  const DiagramSize(this.width, this.height, {this.wantsFullWidth = false});

  final double width;
  final double height;

  /// A bar chart with five labelled bars and a scale cannot be read at half
  /// the page width, so a sheet containing one drops to a single column.
  final bool wantsFullWidth;
}

/// The space [spec] needs, or null if it is not a picture this can draw.
///
/// Returning null rather than drawing a placeholder is deliberate: an unknown
/// spec means the question is still incomplete, and [diagramWidget] callers
/// treat that as a question to leave out rather than one to print blind.
DiagramSize? diagramSize(String? spec) {
  if (spec == null) return null;
  final kind = spec.split(':').first;
  return switch (kind) {
    'polygon' => const DiagramSize(96, 74),
    'solid' => const DiagramSize(112, 84),
    'angle' => const DiagramSize(124, 74),
    'pie' => const DiagramSize(96, 92),
    // Deliberately wider than any card. CustomPaint shrinks to the room it is
    // given, so this asks for the whole column and takes what there is.
    'bars' => const DiagramSize(460, 176, wantsFullWidth: true),
    _ => null,
  };
}

/// The picture for [spec], or null if there is nothing this can draw.
pw.Widget? diagramWidget(String? spec) {
  final size = diagramSize(spec);
  if (size == null) return null;
  final body = spec!.substring(spec.indexOf(':') + 1);
  final kind = spec.split(':').first;

  void paint(PdfGraphics canvas, PdfPoint box) {
    switch (kind) {
      case 'polygon':
        _drawPolygon(canvas, box, body);
      case 'solid':
        _drawSolid(canvas, box, body);
      case 'angle':
        _drawAngle(canvas, box, int.tryParse(body) ?? 90);
      case 'pie':
        _drawPie(canvas, box, int.tryParse(body) ?? 50);
      case 'bars':
        _drawBars(canvas, box, body);
    }
  }

  return pw.CustomPaint(
    size: PdfPoint(size.width, size.height),
    painter: paint,
  );
}

// --------------------------------------------------------------- flat shapes

/// A regular polygon, or the rectangle that "polygon:rect" asks for.
///
/// Drawn with a side flat along the bottom rather than a vertex, because that
/// is how every textbook prints a hexagon and a child matching a picture to a
/// word should not have to mentally rotate it first.
void _drawPolygon(PdfGraphics canvas, PdfPoint box, String body) {
  canvas
    ..setLineWidth(1.5)
    ..setStrokeColor(_ink)
    ..setLineJoin(PdfLineJoin.round);

  if (body == 'rect') {
    final w = box.x * 0.82;
    final h = box.y * 0.54;
    canvas
      ..drawRect((box.x - w) / 2, (box.y - h) / 2, w, h)
      ..strokePath(close: true);
    return;
  }

  final n = int.tryParse(body) ?? 4;
  final pts = _regularPolygon(n, box.x * 0.40, box.x / 2, box.y / 2);
  _polyline(canvas, pts, close: true);
  canvas.strokePath(close: true);
}

/// A regular [n]-gon of radius [r] about ([cx], [cy]).
///
/// [offset] is where the first vertex sits, in radians from due east. The
/// default puts a flat edge along the bottom: half a step round from straight
/// down for an even-sided shape, and a vertex straight up for an odd-sided one,
/// which comes to the same thing. A pentagon has to be point-up - drawn
/// upside down it reads as an arrowhead, and the child is being asked to
/// recognise it on sight.
List<PdfPoint> _regularPolygon(
  int n,
  double r,
  double cx,
  double cy, {
  double? offsetOverride,
}) {
  final offset =
      offsetOverride ?? (n.isEven ? -pi / 2 + pi / n : pi / 2);
  return [
    for (var i = 0; i < n; i++)
      PdfPoint(
        cx + r * cos(offset + 2 * pi * i / n),
        cy + r * sin(offset + 2 * pi * i / n),
      ),
  ];
}

// -------------------------------------------------------------------- solids

/// How flat a base circle or polygon looks when the solid is seen from just
/// above. Textbook drawings sit near a third; much less and a hexagonal prism
/// reads as a rectangle.
const _squash = 0.36;

void _drawSolid(PdfGraphics canvas, PdfPoint box, String name) {
  canvas
    ..setLineWidth(1.4)
    ..setLineJoin(PdfLineJoin.round);

  switch (name) {
    case 'cube':
      _drawBox(canvas, box, cube: true);
    case 'cuboid':
      _drawBox(canvas, box, cube: false);
    case 'cylinder':
      _drawCylinder(canvas, box);
    case 'cone':
      _drawCone(canvas, box);
    case 'sphere':
      _drawSphere(canvas, box);
    default:
      final base = _baseSides(name);
      if (base == null) return;
      if (name.endsWith('pyramid')) {
        _drawPyramid(canvas, box, base);
      } else {
        _drawPrism(canvas, box, base);
      }
  }
}

/// How many sides the base of a named prism or pyramid has.
int? _baseSides(String name) => switch (name.split('-').first) {
      'triangular' => 3,
      'square' => 4,
      'pentagonal' => 5,
      'hexagonal' => 6,
      _ => null,
    };

/// A cube or cuboid, drawn the way it is drawn on a blackboard: a face square
/// to the reader and a second one offset behind it.
void _drawBox(PdfGraphics canvas, PdfPoint box, {required bool cube}) {
  final w = box.x * (cube ? 0.52 : 0.62);
  final h = cube ? w : w * 0.60;
  final d = w * 0.34;
  final left = (box.x - w - d) / 2;
  final bottom = (box.y - h - d) / 2;

  PdfPoint f(double x, double y) => PdfPoint(left + x, bottom + y);
  final fbl = f(0, 0), fbr = f(w, 0), ftr = f(w, h), ftl = f(0, h);
  final bbl = f(d, d), bbr = f(w + d, d), btr = f(w + d, h + d), btl = f(d, h + d);

  // The back-bottom-left corner is the one the solid hides. Its three edges
  // are what a dashed line is for.
  _strokeHidden(canvas, [
    [bbl, bbr],
    [bbl, btl],
    [bbl, fbl],
  ]);

  _strokeVisible(canvas, [
    [fbl, fbr], [fbr, ftr], [ftr, ftl], [ftl, fbl],
    [btl, btr], [btr, bbr],
    [ftl, btl], [ftr, btr], [fbr, bbr],
  ]);
}

/// A prism: the same polygon top and bottom, joined by vertical edges.
void _drawPrism(PdfGraphics canvas, PdfPoint box, int sides) {
  final r = box.x * 0.30;
  final h = box.y * 0.44;
  final cx = box.x / 2;
  final bottom = _flatBase(sides, r, cx, box.y / 2 - h / 2);
  final top = [for (final p in bottom) PdfPoint(p.x, p.y + h)];

  final back = _backPath(bottom);
  final visible = <List<PdfPoint>>[];
  final hiddenEdges = <List<PdfPoint>>[];

  for (var i = 0; i < sides; i++) {
    final j = (i + 1) % sides;
    // The top face is seen from above, so all of it shows. The bottom face
    // only shows where the body does not stand in front of it.
    visible.add([top[i], top[j]]);
    (back.edges.contains(i) ? hiddenEdges : visible).add([bottom[i], bottom[j]]);
    (back.vertices.contains(i) ? hiddenEdges : visible).add([bottom[i], top[i]]);
  }

  _strokeHidden(canvas, hiddenEdges);
  _strokeVisible(canvas, visible);
}

/// A pyramid: one polygon base and an apex above its centre.
void _drawPyramid(PdfGraphics canvas, PdfPoint box, int sides) {
  final r = box.x * 0.30;
  final h = box.y * 0.52;
  final cx = box.x / 2;
  final baseY = box.y / 2 - h / 2;
  final base = _flatBase(sides, r, cx, baseY);
  final apex = PdfPoint(cx, baseY + h);

  final back = _backPath(base);
  final visible = <List<PdfPoint>>[];
  final hiddenEdges = <List<PdfPoint>>[];

  for (var i = 0; i < sides; i++) {
    final j = (i + 1) % sides;
    (back.edges.contains(i) ? hiddenEdges : visible).add([base[i], base[j]]);
    (back.vertices.contains(i) ? hiddenEdges : visible).add([base[i], apex]);
  }

  _strokeHidden(canvas, hiddenEdges);
  _strokeVisible(canvas, visible);
}

/// A polygon base seen from slightly above: the same shape, squashed.
///
/// Turned the other way up from a flat drawing on purpose. A base points its
/// vertex towards the reader, not away, so a triangular prism shows the edge
/// nearest the eye rather than hiding it round the back.
List<PdfPoint> _flatBase(int sides, double r, double cx, double cy) => [
      for (final p in _regularPolygon(sides, r, cx, cy,
          offsetOverride: -pi / 2 + (sides.isEven ? pi / sides : 0)))
        PdfPoint(p.x, cy + (p.y - cy) * _squash),
    ];

/// Which parts of a base polygon the solid stands in front of.
///
/// Seen from above and in front, the widest point on each side is where the
/// outline turns; everything on the far side of that line is behind the body.
/// Working it out from the drawn points means one rule covers a triangular
/// prism and a hexagonal one, instead of a table of special cases that would
/// be wrong the first time a new solid was added.
({Set<int> edges, Set<int> vertices}) _backPath(List<PdfPoint> base) {
  var leftmost = 0, rightmost = 0;
  for (var i = 1; i < base.length; i++) {
    if (base[i].x < base[leftmost].x) leftmost = i;
    if (base[i].x > base[rightmost].x) rightmost = i;
  }

  final edges = <int>{};
  final vertices = <int>{};
  // Walk from the right-hand turning point to the left-hand one. Exactly one
  // of the two ways round is the back; it is the one that goes up the page.
  var i = rightmost;
  final walk = <int>[];
  while (i != leftmost) {
    walk.add(i);
    i = (i + 1) % base.length;
  }
  final goesBehind = walk.isEmpty
      ? false
      : walk
              .map((e) => base[(e + 1) % base.length].y)
              .reduce((a, b) => a > b ? a : b) >
          base[rightmost].y;
  if (!goesBehind) {
    walk.clear();
    var j = leftmost;
    while (j != rightmost) {
      walk.add(j);
      j = (j + 1) % base.length;
    }
  }
  for (final e in walk) {
    edges.add(e);
    // The turning points themselves are on the silhouette, so their upright
    // edges are seen even though the edges between them are not.
    final next = (e + 1) % base.length;
    if (next != leftmost && next != rightmost) vertices.add(next);
  }
  return (edges: edges, vertices: vertices);
}

void _drawCylinder(PdfGraphics canvas, PdfPoint box) {
  final rx = box.x * 0.26;
  final h = box.y * 0.46;
  final cx = box.x / 2;
  final bottomY = box.y / 2 - h / 2;
  final ry = rx * _squash;

  _strokeHidden(canvas, [_arc(cx, bottomY, rx, ry, 0, pi)]);
  _strokeVisible(canvas, [
    _arc(cx, bottomY, rx, ry, pi, 2 * pi),
    _arc(cx, bottomY + h, rx, ry, 0, 2 * pi),
    [PdfPoint(cx - rx, bottomY), PdfPoint(cx - rx, bottomY + h)],
    [PdfPoint(cx + rx, bottomY), PdfPoint(cx + rx, bottomY + h)],
  ]);
}

void _drawCone(PdfGraphics canvas, PdfPoint box) {
  final rx = box.x * 0.27;
  final h = box.y * 0.56;
  final cx = box.x / 2;
  final bottomY = box.y / 2 - h / 2;
  final ry = rx * _squash;
  final apex = PdfPoint(cx, bottomY + h);

  _strokeHidden(canvas, [_arc(cx, bottomY, rx, ry, 0, pi)]);
  _strokeVisible(canvas, [
    _arc(cx, bottomY, rx, ry, pi, 2 * pi),
    [PdfPoint(cx - rx, bottomY), apex],
    [PdfPoint(cx + rx, bottomY), apex],
  ]);
}

void _drawSphere(PdfGraphics canvas, PdfPoint box) {
  final r = min(box.x, box.y) * 0.30;
  final cx = box.x / 2;
  final cy = box.y / 2;
  // The circle alone is a circle. The equator round it is what says "ball".
  _strokeHidden(canvas, [_arc(cx, cy, r, r * _squash, 0, pi)]);
  _strokeVisible(canvas, [
    _arc(cx, cy, r, r, 0, 2 * pi),
    _arc(cx, cy, r, r * _squash, pi, 2 * pi),
  ]);
}

/// An ellipse arc as a polyline. Sampled rather than drawn with bezier curves
/// because a dashed half-arc has to be one path, and sampling makes the
/// visible and hidden halves the same kind of thing.
List<PdfPoint> _arc(
  double cx,
  double cy,
  double rx,
  double ry,
  double from,
  double to,
) {
  const steps = 48;
  return [
    for (var i = 0; i <= steps; i++)
      PdfPoint(
        cx + rx * cos(from + (to - from) * i / steps),
        cy + ry * sin(from + (to - from) * i / steps),
      ),
  ];
}

// -------------------------------------------------------------------- angles

void _drawAngle(PdfGraphics canvas, PdfPoint box, int degrees) {
  final theta = degrees * pi / 180;
  const markR = 0.28;

  // Drawn about the origin at unit length first, then fitted to the box.
  //
  // Placing the vertex at a fixed spot does not work: a 269 degree angle sends
  // its second arm straight down, and with the vertex a third of the way up
  // the card the arm ran out of the picture and across the answer box below.
  // Nothing in a PDF clips it - it just draws over whatever is there.
  final arms = [
    [PdfPoint.zero, const PdfPoint(1, 0)],
    [PdfPoint.zero, PdfPoint(cos(theta), sin(theta))],
  ];
  // The arc goes on the inside of the angle being named. For a reflex angle
  // that is the long way round - which is the entire point of the word, and an
  // arc drawn on the short side would be teaching the opposite.
  //
  // A right angle gets a square instead. Every textbook marks it that way, and
  // a child learns to recognise the symbol before they trust the number.
  final mark = degrees == 90
      ? const [
          PdfPoint(markR * 0.7, 0),
          PdfPoint(markR * 0.7, markR * 0.7),
          PdfPoint(0, markR * 0.7),
        ]
      : _arc(0, 0, markR, markR, 0, theta);

  final fit = _fitter([...arms.expand((a) => a), ...mark], box, padding: 7);
  canvas
    ..setLineJoin(PdfLineJoin.round)
    ..setLineCap(PdfLineCap.round);
  _strokeVisible(canvas, [for (final a in arms) a.map(fit).toList()]);

  canvas
    ..setLineWidth(0.9)
    ..setStrokeColor(_axis);
  _polyline(canvas, mark.map(fit).toList());
  canvas.strokePath();
}

/// A transform that scales and centres [points] inside [box].
///
/// Lets a figure be worked out in whatever units suit the maths and only then
/// be made to fit, instead of every drawing carrying its own guess about how
/// much room its worst case needs.
PdfPoint Function(PdfPoint) _fitter(
  List<PdfPoint> points,
  PdfPoint box, {
  double padding = 6,
}) {
  var minX = points.first.x, maxX = points.first.x;
  var minY = points.first.y, maxY = points.first.y;
  for (final p in points) {
    minX = min(minX, p.x);
    maxX = max(maxX, p.x);
    minY = min(minY, p.y);
    maxY = max(maxY, p.y);
  }
  final w = max(maxX - minX, 1e-6);
  final h = max(maxY - minY, 1e-6);
  final scale = min((box.x - 2 * padding) / w, (box.y - 2 * padding) / h);
  final dx = (box.x - w * scale) / 2 - minX * scale;
  final dy = (box.y - h * scale) / 2 - minY * scale;
  return (p) => PdfPoint(p.x * scale + dx, p.y * scale + dy);
}

// -------------------------------------------------------------- charts

void _drawPie(PdfGraphics canvas, PdfPoint box, int percent) {
  final r = min(box.x, box.y) * 0.40;
  final cx = box.x / 2;
  final cy = box.y / 2;
  final sweep = 2 * pi * percent / 100;

  // Shaded, not coloured. These sheets are photocopied in black and white, and
  // a slice picked out in blue comes back the same grey as the rest of the pie.
  canvas.setFillColor(_shade);
  _polyline(canvas, [
    PdfPoint(cx, cy),
    ..._arc(cx, cy, r, r, pi / 2, pi / 2 - sweep),
  ], close: true);
  canvas.fillPath();

  canvas
    ..setLineWidth(1.3)
    ..setStrokeColor(_ink);
  _polyline(canvas, _arc(cx, cy, r, r, 0, 2 * pi), close: true);
  canvas.strokePath(close: true);
  _strokeVisible(canvas, [
    [PdfPoint(cx, cy), PdfPoint(cx, cy + r)],
    [
      PdfPoint(cx, cy),
      PdfPoint(cx + r * cos(pi / 2 - sweep), cy + r * sin(pi / 2 - sweep)),
    ],
  ]);
}

/// A bar chart with a scale that can actually be read off.
///
/// The question asks the child to total the bars or subtract the smallest from
/// the largest, so every bar has to land on a gridline. That is a constraint on
/// the data as much as on the drawing, and the generator now produces multiples
/// of the step for exactly this reason.
void _drawBars(PdfGraphics canvas, PdfPoint box, String body) {
  final entries = <MapEntry<String, int>>[];
  for (final part in body.split(',')) {
    final bits = part.split('=');
    if (bits.length != 2) continue;
    entries.add(MapEntry(bits[0], int.tryParse(bits[1]) ?? 0));
  }
  if (entries.isEmpty) return;

  final maxV = entries.map((e) => e.value).reduce(max);
  final step = _gridStep(entries.map((e) => e.value).toList());
  final top = ((maxV / step).ceil()) * step;

  const leftPad = 26.0;
  const bottomPad = 16.0;
  const topPad = 8.0;
  final plotW = box.x - leftPad - 6;
  final plotH = box.y - bottomPad - topPad;
  double yFor(num v) => bottomPad + plotH * v / top;

  // Gridlines first, so the bars sit on top of them and the outline stays
  // crisp where the two meet.
  canvas
    ..setLineWidth(0.5)
    ..setStrokeColor(_grid);
  for (var v = step; v <= top; v += step) {
    _polyline(canvas, [
      PdfPoint(leftPad, yFor(v)),
      PdfPoint(leftPad + plotW, yFor(v)),
    ]);
    canvas.strokePath();
  }

  canvas
    ..setLineWidth(1.0)
    ..setStrokeColor(_axis);
  _polyline(canvas, [
    PdfPoint(leftPad, yFor(top)),
    PdfPoint(leftPad, bottomPad),
    PdfPoint(leftPad + plotW, bottomPad),
  ]);
  canvas.strokePath();

  final font = canvas.defaultFont;
  if (font == null) return;
  canvas.setFillColor(_axis);
  for (var v = 0; v <= top; v += step) {
    final label = '$v';
    final metrics = font.stringMetrics(label) * 7;
    canvas.drawString(
      font,
      7,
      label,
      leftPad - 4 - metrics.width,
      yFor(v) - 2.4,
    );
  }

  final slot = plotW / entries.length;
  final barW = slot * 0.52;
  for (var i = 0; i < entries.length; i++) {
    final x = leftPad + slot * i + (slot - barW) / 2;
    final h = plotH * entries[i].value / top;
    canvas
      ..setFillColor(_shade)
      ..drawRect(x, bottomPad, barW, h)
      ..fillPath()
      ..setStrokeColor(_ink)
      ..setLineWidth(0.9)
      ..drawRect(x, bottomPad, barW, h)
      ..strokePath(close: true);

    final label = entries[i].key;
    final metrics = font.stringMetrics(label) * 7.5;
    canvas
      ..setFillColor(_ink)
      ..drawString(
        font,
        7.5,
        label,
        x + barW / 2 - metrics.width / 2,
        bottomPad - 10,
      );
  }
}

/// A gridline spacing that every bar top lands on.
///
/// The highest common factor of the values, not a round number chosen for the
/// look of it. A chart ruled every 5 with a bar at 37 asks the child to read a
/// value that is not on the paper - and the answer key still says 37, so they
/// are marked wrong for reading the chart they were given. The generator keeps
/// the values to a common unit precisely so this can hold.
int _gridStep(List<int> values) {
  var step = values.first;
  for (final v in values.skip(1)) {
    step = _hcf(step, v);
  }
  if (step < 1) return 1;
  // Too fine a step is its own kind of unreadable. Double it until the sheet
  // has a countable number of lines; bar tops still land on every other one.
  final maxV = values.reduce(max);
  while (maxV ~/ step > 14) {
    step *= 2;
  }
  return step;
}

int _hcf(int a, int b) => b == 0 ? a : _hcf(b, a % b);

// ------------------------------------------------------------------- drawing

void _polyline(PdfGraphics canvas, List<PdfPoint> pts, {bool close = false}) {
  if (pts.isEmpty) return;
  canvas.moveTo(pts.first.x, pts.first.y);
  for (final p in pts.skip(1)) {
    canvas.lineTo(p.x, p.y);
  }
  if (close) canvas.closePath();
}

void _strokeVisible(PdfGraphics canvas, List<List<PdfPoint>> paths) {
  canvas
    ..setLineDashPattern()
    ..setStrokeColor(_ink)
    ..setLineWidth(1.4);
  for (final p in paths) {
    _polyline(canvas, p);
    canvas.strokePath();
  }
}

void _strokeHidden(PdfGraphics canvas, List<List<PdfPoint>> paths) {
  canvas
    ..setLineDashPattern(const [2, 2])
    ..setStrokeColor(_hidden)
    ..setLineWidth(1.0);
  for (final p in paths) {
    _polyline(canvas, p);
    canvas.strokePath();
  }
  canvas.setLineDashPattern();
}
