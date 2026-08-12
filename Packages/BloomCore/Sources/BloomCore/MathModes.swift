import Foundation

public enum AngleMode: String, Sendable, Equatable {
    case radians
    case degrees

    public var shortLabel: String {
        self == .degrees ? "DEG" : "RAD"
    }
}

public struct ComplexValue: Equatable, Sendable {
    public let re: Double
    public let im: Double

    public init(_ re: Double, _ im: Double) {
        self.re = re
        self.im = im
    }

    public var isReal: Bool {
        abs(im) < 1e-12
    }
}

public struct FractionValue: Equatable, Sendable {
    public let num: Int
    public let den: Int

    public init(num: Int, den: Int) {
        self.num = num
        self.den = den
    }

    public var decimal: Double {
        den == 0 ? Double.nan : Double(num) / Double(den)
    }
}

public enum TrigFunction: String, CaseIterable, Sendable {
    case sin
    case cos
    case tan
    case asin
    case acos
    case atan
}

public enum FractionOp: String, CaseIterable, Sendable {
    case add = "+"
    case subtract = "−"
    case multiply = "×"
    case divide = "÷"
}

public enum PythSide: String, Sendable {
    case hypotenuse
    case legA
    case legB
}

public enum MathModes {
    // Quadratic a x^2 + b x + c = 0. Returns discriminant and one or two roots (real or complex).
    public static func quadratic(a: Double, b: Double, c: Double) -> (discriminant: Double, roots: [ComplexValue])? {
        if a == 0 {
            if b == 0 { return nil }
            return (Double.nan, [ComplexValue(-c / b, 0)])
        }
        let d = b * b - 4 * a * c
        if d >= 0 {
            let s = d.squareRoot()
            let r1 = (-b + s) / (2 * a)
            let r2 = (-b - s) / (2 * a)
            return (d, [ComplexValue(r1, 0), ComplexValue(r2, 0)])
        } else {
            let s = (-d).squareRoot()
            let re = -b / (2 * a)
            let im = s / (2 * a)
            return (d, [ComplexValue(re, im), ComplexValue(re, -im)])
        }
    }

    // 2x2 system: a1 x + b1 y = c1 ; a2 x + b2 y = c2. Cramer's rule; nil when no unique solution.
    public static func linearSystem(a1: Double, b1: Double, c1: Double, a2: Double, b2: Double, c2: Double) -> (x: Double, y: Double)? {
        let det = a1 * b2 - a2 * b1
        if det == 0 { return nil }
        let x = (c1 * b2 - c2 * b1) / det
        let y = (a1 * c2 - a2 * c1) / det
        return (x, y)
    }

    // Pythagorean: pass exactly two of a, b (legs), c (hypotenuse); the nil one is solved for.
    public static func pythagorean(a: Double?, b: Double?, c: Double?) -> (side: PythSide, value: Double)? {
        if let a, let b, c == nil {
            return (.hypotenuse, (a * a + b * b).squareRoot())
        }
        if let a, let c, b == nil {
            let sq = c * c - a * a
            guard sq >= 0 else { return nil }
            return (.legB, sq.squareRoot())
        }
        if let b, let c, a == nil {
            let sq = c * c - b * b
            guard sq >= 0 else { return nil }
            return (.legA, sq.squareRoot())
        }
        return nil
    }

    public static func gcd(_ x: Int, _ y: Int) -> Int {
        // `abs(Int.min)` traps - there is no positive Int.min. `magnitude` is
        // UInt, so it cannot, and every intermediate here stays non-negative.
        var a = x.magnitude
        var b = y.magnitude
        while b != 0 {
            (a, b) = (b, a % b)
        }
        return a == 0 ? 1 : Int(clamping: a)
    }

    public static func simplify(num: Int, den: Int) -> FractionValue? {
        if den == 0 { return nil }
        // Negating Int.min traps (its positive has no Int). Unrepresentable, so
        // it takes the same "no answer" path an invalid fraction already takes.
        guard num > Int.min, den > Int.min else { return nil }
        var n = num
        var d = den
        if d < 0 {
            n = -n
            d = -d
        }
        let g = gcd(n, d)
        return FractionValue(num: n / g, den: d / g)
    }

    // Int arithmetic TRAPS on overflow, and both operands are digits she typed -
    // two 10-digit denominators are enough to blow past Int64 on the cross
    // multiply. This function is already Optional-returning, so an
    // unrepresentable result is simply "no answer" instead of a crash.
    private static func mul(_ a: Int, _ b: Int) -> Int? {
        let (v, overflow) = a.multipliedReportingOverflow(by: b)
        return overflow ? nil : v
    }

    private static func addOrNil(_ a: Int, _ b: Int) -> Int? {
        let (v, overflow) = a.addingReportingOverflow(b)
        return overflow ? nil : v
    }

    private static func subOrNil(_ a: Int, _ b: Int) -> Int? {
        let (v, overflow) = a.subtractingReportingOverflow(b)
        return overflow ? nil : v
    }

    public static func fraction(_ n1: Int, _ d1: Int, _ op: FractionOp, _ n2: Int, _ d2: Int) -> FractionValue? {
        guard d1 != 0, d2 != 0 else { return nil }
        let n: Int
        let d: Int
        switch op {
        case .add:
            guard let left = mul(n1, d2), let right = mul(n2, d1),
                  let sum = addOrNil(left, right), let den = mul(d1, d2) else { return nil }
            n = sum
            d = den
        case .subtract:
            guard let left = mul(n1, d2), let right = mul(n2, d1),
                  let diff = subOrNil(left, right), let den = mul(d1, d2) else { return nil }
            n = diff
            d = den
        case .multiply:
            guard let num = mul(n1, n2), let den = mul(d1, d2) else { return nil }
            n = num
            d = den
        case .divide:
            if n2 == 0 { return nil }
            guard let num = mul(n1, d2), let den = mul(d1, n2) else { return nil }
            n = num
            d = den
        }
        return simplify(num: n, den: d)
    }

    public static func trig(_ fn: TrigFunction, _ value: Double, mode: AngleMode) -> Double {
        switch fn {
        case .sin:
            return sin(toRadians(value, mode))
        case .cos:
            return cos(toRadians(value, mode))
        case .tan:
            return tan(toRadians(value, mode))
        case .asin:
            return fromRadians(asin(value), mode)
        case .acos:
            return fromRadians(acos(value), mode)
        case .atan:
            return fromRadians(atan(value), mode)
        }
    }

    static func toRadians(_ v: Double, _ mode: AngleMode) -> Double {
        mode == .degrees ? v * Double.pi / 180 : v
    }

    static func fromRadians(_ v: Double, _ mode: AngleMode) -> Double {
        mode == .degrees ? v * 180 / Double.pi : v
    }
}
