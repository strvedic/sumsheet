/// Exact rational arithmetic.
///
/// Fractions must never be computed in floating point. 1/3 + 1/6 has to come
/// out as exactly 1/2, not 0.49999999999999994, or the app will mark a correct
/// student wrong - which is the single fastest way to lose their trust.
class Fraction implements Comparable<Fraction> {
  factory Fraction(int numerator, int denominator) {
    if (denominator == 0) {
      throw ArgumentError('Denominator cannot be zero');
    }
    var n = numerator;
    var d = denominator;
    if (d < 0) {
      n = -n;
      d = -d;
    }
    final g = _gcd(n.abs(), d);
    return Fraction._(g == 0 ? n : n ~/ g, g == 0 ? d : d ~/ g);
  }

  const Fraction._(this.num, this.den);

  final int num;
  final int den;

  static int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);
  static int gcd(int a, int b) => _gcd(a.abs(), b.abs());
  static int lcm(int a, int b) => (a * b).abs() ~/ gcd(a, b);

  Fraction operator +(Fraction o) =>
      Fraction(num * o.den + o.num * den, den * o.den);
  Fraction operator -(Fraction o) =>
      Fraction(num * o.den - o.num * den, den * o.den);
  Fraction operator *(Fraction o) => Fraction(num * o.num, den * o.den);
  Fraction operator /(Fraction o) {
    if (o.num == 0) throw ArgumentError('Division by zero fraction');
    return Fraction(num * o.den, den * o.num);
  }

  bool get isWhole => den == 1;
  bool get isProper => num.abs() < den;
  double get asDouble => num / den;

  @override
  int compareTo(Fraction o) => (num * o.den).compareTo(o.num * den);

  bool operator >(Fraction o) => compareTo(o) > 0;
  bool operator <(Fraction o) => compareTo(o) < 0;

  @override
  bool operator ==(Object other) =>
      other is Fraction && other.num == num && other.den == den;

  @override
  int get hashCode => Object.hash(num, den);

  /// "3/4", or "5" when whole.
  @override
  String toString() => den == 1 ? '$num' : '$num/$den';

  /// "2 1/3" mixed-number form.
  String toMixedString() {
    if (den == 1) return '$num';
    if (num.abs() < den) return toString();
    final whole = num ~/ den;
    final rem = (num % den).abs();
    return rem == 0 ? '$whole' : '$whole $rem/$den';
  }
}
