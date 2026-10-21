import Foundation

private let xmlDecl = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"

// Minimal, dependency-free .xlsx writer. Pure Foundation, cross-platform (no
// Compression/CryptoKit/UIKit) so it builds and tests on Linux.
//
// ZIP entries are STORED (compression method 0) — valid per PKZIP APPNOTE and
// accepted by Excel/Numbers/LibreOffice. We hand-roll CRC-32 and the local /
// central-directory / EOCD records. DOS date-time is a fixed constant
// (determinism over accuracy): 1980-01-01 00:00:00.

// MARK: - ZIP layer

enum XLSXZip {
    // CRC-32, standard polynomial 0xEDB88320, table-driven.
    static let crcTable: [UInt32] = {
        (0..<256).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 {
                c = (c & 1) == 1 ? (0xEDB8_8320 ^ (c >> 1)) : (c >> 1)
            }
            return c
        }
    }()

    static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            let idx = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = (crc >> 8) ^ crcTable[idx]
        }
        return crc ^ 0xFFFF_FFFF
    }

    static func le16(_ v: UInt16) -> [UInt8] {
        [UInt8(v & 0xFF), UInt8((v >> 8) & 0xFF)]
    }

    static func le32(_ v: UInt32) -> [UInt8] {
        [UInt8(v & 0xFF), UInt8((v >> 8) & 0xFF), UInt8((v >> 16) & 0xFF), UInt8((v >> 24) & 0xFF)]
    }

    // Fixed DOS date/time (deterministic): 1980-01-01 00:00:00.
    // date bits: year-1980 (0) << 9 | month (1) << 5 | day (1) = 0x0021; time = 0.
    static let dosDate: UInt16 = 0x0021
    static let dosTime: UInt16 = 0x0000

    /// Build a STORED (uncompressed) ZIP archive from named entries.
    ///
    /// Worked example — two entries: ("a", "A"), ("bb", "BB"):
    ///   local header = 30 + nameLen + extra(0).
    ///   entry a: header 30+1 = 31, +data 1  → 32 bytes, local offset 0.
    ///   entry bb: header 30+2 = 32, +data 2 → 34 bytes, local offset 32.
    ///   total local = 66. central header = 46 + nameLen.
    ///   central a = 47, central bb = 48 → total central = 95, cdOffset = 66.
    ///   EOCD = 22. total file = 66 + 95 + 22 = 183, EOCD begins at 161.
    /// (XLSXTests walks these exact numbers.)
    static func zipArchive(entries: [(name: String, data: Data)]) -> Data {
        var local: [UInt8] = []
        var central: [UInt8] = []
        var offset: UInt32 = 0

        for entry in entries {
            let nameBytes = Array(entry.name.utf8)
            let crc = crc32(entry.data)
            let size = UInt32(entry.data.count)
            let localOffset = offset

            // Local file header (PK\03\04)
            var lh: [UInt8] = [0x50, 0x4B, 0x03, 0x04]
            lh += le16(20)                          // version needed
            lh += le16(0)                           // general-purpose flag
            lh += le16(0)                           // method: stored
            lh += le16(dosTime)
            lh += le16(dosDate)
            lh += le32(crc)
            lh += le32(size)                        // compressed size
            lh += le32(size)                        // uncompressed size
            lh += le16(UInt16(nameBytes.count))
            lh += le16(0)                           // extra field length
            lh += nameBytes
            local += lh
            local += Array(entry.data)
            offset += UInt32(lh.count) + size

            // Central directory header (PK\01\02)
            var ch: [UInt8] = [0x50, 0x4B, 0x01, 0x02]
            ch += le16(20)                          // version made by
            ch += le16(20)                          // version needed
            ch += le16(0)                           // flags
            ch += le16(0)                           // method
            ch += le16(dosTime)
            ch += le16(dosDate)
            ch += le32(crc)
            ch += le32(size)
            ch += le32(size)
            ch += le16(UInt16(nameBytes.count))
            ch += le16(0)                           // extra length
            ch += le16(0)                           // comment length
            ch += le16(0)                           // disk number start
            ch += le16(0)                           // internal attrs
            ch += le32(0)                           // external attrs
            ch += le32(localOffset)                 // offset of local header
            ch += nameBytes
            central += ch
        }

        let cdOffset = UInt32(local.count)
        let cdSize = UInt32(central.count)

        var out = local
        out += central

        // End of central directory record (PK\05\06)
        var eocd: [UInt8] = [0x50, 0x4B, 0x05, 0x06]
        eocd += le16(0)                             // this disk number
        eocd += le16(0)                             // disk with CD start
        eocd += le16(UInt16(entries.count))         // CD records on this disk
        eocd += le16(UInt16(entries.count))         // total CD records
        eocd += le32(cdSize)
        eocd += le32(cdOffset)
        eocd += le16(0)                             // comment length
        out += eocd

        return Data(out)
    }
}

// MARK: - Workbook layer

/// The give-first settings the budget tab applies on top of a month. Rates are
/// percents as she types them (10 = 10%); `flat` is the monthly pledge in dollars.
public struct BudgetGiving: Equatable, Sendable {
    public var tithePct: Double
    public var feastPct: Double
    public var poorPct: Double
    public var flat: Double
    /// True when any income is entered as take-home, so the rates apply to that
    /// entered amount and the sheet must not call it "gross".
    public var ofIncome: Bool

    public init(tithePct: Double, feastPct: Double, poorPct: Double, flat: Double, ofIncome: Bool = false) {
        self.tithePct = tithePct
        self.feastPct = feastPct
        self.poorPct = poorPct
        self.flat = flat
        self.ofIncome = ofIncome
    }

    public static let none = BudgetGiving(tithePct: 0, feastPct: 0, poorPct: 0, flat: 0)

    var isZero: Bool { tithePct == 0 && feastPct == 0 && poorPct == 0 && flat == 0 }
}

/// One month as a formula-driven, print-ready workbook.
///
/// Layout is a ledger with one spine: every section's money lands in column G, so
/// take-home, giving, planned and what's left read straight down the page. Inputs
/// (amounts and rates she can change) are shaded; everything else is a formula, and
/// every formula also carries its cached value so previews that never recalculate
/// (iOS Files, Mail, Quick Look) still show the right numbers.
public enum BudgetXLSX {
    /// "Hannah's Budget 2026-10 October.xlsx" — sorts by date in a folder, reads
    /// plainly in a share sheet. A malformed key degrades to the key itself.
    public static func fileName(for ymKey: String) -> String {
        let safeKey = String(ymKey.map { $0.isLetter || $0.isNumber || $0 == "-" ? $0 : "-" })
        let label = BudgetMath.monthLabel(ymKey)                 // "October 2026", or the key if malformed
        guard label != ymKey, let month = label.split(separator: " ").first else {
            return "Hannah's Budget \(safeKey).xlsx"
        }
        return "Hannah's Budget \(safeKey) \(month).xlsx"
    }

    public static func workbook(db: BudgetDB, giving: BudgetGiving = .none) -> Data {
        let m = db.months[db.cur] ?? BudgetDefaults.month()
        let label = BudgetMath.monthLabel(db.cur)
        let sheet = buildSheet(month: m, label: label, giving: giving)
        let title = "Hannah's Budget \u{2014} \(label)"

        let entries: [(name: String, data: Data)] = [
            ("[Content_Types].xml", Data(contentTypesXML.utf8)),
            ("_rels/.rels", Data(rootRelsXML.utf8)),
            ("docProps/core.xml", Data(coreXML(title: title).utf8)),
            ("docProps/app.xml", Data(appXML.utf8)),
            ("xl/workbook.xml", Data(workbookXML(sheetName: sheetName(label)).utf8)),
            ("xl/_rels/workbook.xml.rels", Data(workbookRelsXML.utf8)),
            ("xl/styles.xml", Data(stylesXML.utf8)),
            ("xl/worksheets/sheet1.xml", Data(sheet.xml(footer: title).utf8))
        ]
        return XLSXZip.zipArchive(entries: entries)
    }

    // MARK: Sheet construction

    private static func buildSheet(month m: BudgetMonth, label: String, giving: BudgetGiving) -> Sheet {
        var s = Sheet()

        // Masthead
        s.row(1, height: 10)
        s.row(2, height: 34).text(.B, "Hannah's Budget", .title)
        s.row(3, height: 18).text(.B, "\(label)  \u{00B7}  from Hannah's Calculator", .subtitle)
        s.row(4, height: 16).text(.B, "Shaded cells are yours to change. Every total recalculates.", .note)

        // Income
        var r = 6
        s.row(r, height: 24).text(.B, "Income", .section)
        r += 1
        s.row(r, height: 20)
            .text(.B, "Source", .head).text(.C, "Gross", .headNum).text(.D, "Tax", .headNum)
            .text(.E, "Retirement", .headNum).text(.F, "Other", .headNum).text(.G, "Take-home", .headNum)
        let incFirst = r + 1
        for (ix, inc) in m.inc.enumerated() {
            if ix == 1 && !m.inc2On { continue }
            if ix > 1 { break }   // the app only ever counts two
            r += 1
            let name = inc.label.trimmingCharacters(in: .whitespaces).isEmpty ? "Income \(ix + 1)" : inc.label
            let row = s.row(r, height: 20).text(.B, name, .label)
            if inc.net == true {
                // Entered as take-home: the amount IS the net, the rates are dormant.
                row.number(.C, max(0, inc.gross), .moneyIn)
                    .text(.D, "\u{2014}", .dash).text(.E, "\u{2014}", .dash).text(.F, "\u{2014}", .dash)
                    .formula(.G, "MAX(0,C\(r))", cached: BudgetMath.netOf(inc), .money)
            } else {
                row.number(.C, inc.gross, .moneyIn)
                    .number(.D, inc.tax / 100, .pctIn).number(.E, inc.ret / 100, .pctIn).number(.F, inc.oth / 100, .pctIn)
                    .formula(.G, "MAX(0,C\(r)*(1-MIN(1,D\(r)+E\(r)+F\(r))))", cached: BudgetMath.netOf(inc), .money)
            }
        }
        let incLast = r
        r += 1
        let incTotalRow = r
        let gross = (m.inc.first?.gross ?? 0) + (m.inc2On && m.inc.count > 1 ? m.inc[1].gross : 0)
        let takeHome = BudgetMath.takeHome(of: m)
        s.row(r, height: 22)
            .text(.B, "Monthly take-home", .totalLabel)
            .formula(.C, "SUM(C\(incFirst):C\(incLast))", cached: gross, .totalMoney)
            .blank(.D, .totalLabel).blank(.E, .totalLabel).blank(.F, .totalLabel)
            .formula(.G, "SUM(G\(incFirst):G\(incLast))", cached: takeHome, .totalMoney)
        let grossRef = "C\(incTotalRow)"
        let takeHomeRef = "G\(incTotalRow)"

        // Give first
        var givingRef: String?
        var givingTotal = 0.0
        if !giving.isZero {
            r += 2
            s.row(r, height: 24).text(.B, "Give first", .section)
            r += 1
            s.row(r, height: 20)
                .text(.B, "Gift", .head).blank(.C, .head).blank(.D, .head).blank(.E, .head)
                .text(.F, giving.ofIncome ? "Of income" : "Of gross", .headNum).text(.G, "Amount", .headNum)
            let gFirst = r + 1
            for (name, pct) in [("Tithe", giving.tithePct),
                                ("Feasting & Hospitality", giving.feastPct),
                                ("The Poor & Discipleship", giving.poorPct)] {
                r += 1
                let amount = gross * pct / 100
                givingTotal += amount
                s.row(r, height: 20).text(.B, name, .label)
                    .number(.F, pct / 100, .pctIn)
                    .formula(.G, "F\(r)*\(grossRef)", cached: amount, .money)
            }
            r += 1
            givingTotal += giving.flat
            s.row(r, height: 20).text(.B, "Innovation & Tools", .label)
                .text(.F, "flat", .dash)
                .number(.G, giving.flat, .moneyIn)
            let gLast = r
            r += 1
            s.row(r, height: 22)
                .text(.B, "Given first", .totalLabel)
                .blank(.C, .totalLabel).blank(.D, .totalLabel).blank(.E, .totalLabel).blank(.F, .totalLabel)
                .formula(.G, "SUM(G\(gFirst):G\(gLast))", cached: givingTotal, .totalMoney)
            givingRef = "G\(r)"
        }

        // Spending plan
        r += 2
        s.row(r, height: 24).text(.B, "Spending plan", .section)
        r += 1
        s.row(r, height: 20)
            .text(.B, "Category & item", .head).blank(.C, .head).blank(.D, .head)
            .text(.E, "Goal", .headNum).text(.F, "Of take-home", .headNum).text(.G, "Planned", .headNum)
        let spendFirst = r + 1
        for c in m.cats {
            r += 1
            let catRow = r
            let items = c.items.filter { !$0.n.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || $0.a != 0 }
            let total = BudgetMath.catTotal(c)
            let band = s.row(r, height: 22)
                .text(.B, c.n.isEmpty ? "Category" : c.n, .band)
                .blank(.C, .band).blank(.D, .band)
            if let goal = c.goal {
                band.number(.E, goal, .bandMoneyIn)
            } else {
                band.blank(.E, .band)
            }
            band.formula(.F, "IF(\(takeHomeRef)>0,G\(catRow)/\(takeHomeRef),0)",
                         cached: takeHome > 0 ? total / takeHome : 0, .bandPct)
            if items.isEmpty {
                band.number(.G, 0, .bandMoney)
                continue
            }
            for it in items {
                r += 1
                s.row(r, height: 19).text(.B, it.n, .item).number(.G, it.a, .moneyIn)
            }
            // SUBTOTAL, not SUM: the grand total below can then sweep the whole
            // column and skip these category lines instead of counting them twice.
            band.formula(.G, "SUBTOTAL(9,G\(catRow + 1):G\(r))", cached: total, .bandMoney)
        }
        let spendLast = r
        r += 1
        let planned = BudgetMath.planned(of: m)
        s.row(r, height: 22)
            .text(.B, "Total planned", .totalLabel)
            .blank(.C, .totalLabel).blank(.D, .totalLabel).blank(.E, .totalLabel)
            .formula(.F, "IF(\(takeHomeRef)>0,G\(r)/\(takeHomeRef),0)",
                     cached: takeHome > 0 ? planned / takeHome : 0, .totalPct)
            .formula(.G, "SUBTOTAL(9,G\(spendFirst):G\(max(spendFirst, spendLast)))", cached: planned, .totalMoney)
        let plannedRef = "G\(r)"

        // The bottom line
        r += 2
        s.row(r, height: 24).text(.B, "The bottom line", .section)
        r += 1
        let lineFirst = r
        s.row(r, height: 20).text(.B, "Take-home", .label).formula(.G, takeHomeRef, cached: takeHome, .money)
        if let givingRef {
            r += 1
            s.row(r, height: 20).text(.B, "Less: given first", .label)
                .formula(.G, "-\(givingRef)", cached: -givingTotal, .money)
        }
        r += 1
        s.row(r, height: 20).text(.B, "Less: planned spending", .label)
            .formula(.G, "-\(plannedRef)", cached: -planned, .money)
        let lineLast = r
        r += 1
        s.row(r, height: 28)
            .text(.B, "Left to grow", .grandLabel)
            .blank(.C, .grandLabel).blank(.D, .grandLabel).blank(.E, .grandLabel).blank(.F, .grandLabel)
            .formula(.G, "SUM(G\(lineFirst):G\(lineLast))", cached: takeHome - givingTotal - planned, .grandMoney)
        return s
    }

    /// Excel sheet names: ≤31 chars, none of : \ / ? * [ ]
    private static func sheetName(_ label: String) -> String {
        let bad: Set<Character> = [":", "\\", "/", "?", "*", "[", "]"]
        let clean = String(label.filter { !bad.contains($0) }.prefix(31))
        return clean.isEmpty ? "Budget" : clean
    }

    // MARK: Sheet model

    enum Col: Int {
        case A, B, C, D, E, F, G
        var letter: String { BudgetXLSX.colRef(rawValue) }
    }

    /// Cell styles, by their index in styles.xml's cellXfs. Order matters.
    enum Style: Int, CaseIterable {
        case plain = 0, title, subtitle, note, section, head, headNum, label, item
        case moneyIn, pctIn, money, dash
        case band, bandMoney, bandMoneyIn, bandPct
        case totalLabel, totalMoney, totalPct
        case grandLabel, grandMoney
        case rule   // an empty cell that only carries the row's hairline
    }

    fileprivate enum Value {
        case text(String)
        case number(Double)
        case formula(String, cached: Double)
        case blank
    }

    final class RowBuilder {
        fileprivate var cells: [(Col, Value, Style)] = []
        let height: Double?
        init(height: Double?) { self.height = height }

        @discardableResult func text(_ c: Col, _ s: String, _ st: Style) -> RowBuilder { cells.append((c, .text(s), st)); return self }
        @discardableResult func number(_ c: Col, _ v: Double, _ st: Style) -> RowBuilder { cells.append((c, .number(v), st)); return self }
        @discardableResult func formula(_ c: Col, _ f: String, cached: Double, _ st: Style) -> RowBuilder {
            cells.append((c, .formula(f, cached: cached), st)); return self
        }
        @discardableResult func blank(_ c: Col, _ st: Style) -> RowBuilder { cells.append((c, .blank, st)); return self }
    }

    struct Sheet {
        private var rows: [Int: RowBuilder] = [:]

        @discardableResult mutating func row(_ r: Int, height: Double? = nil) -> RowBuilder {
            if let existing = rows[r] { return existing }
            let b = RowBuilder(height: height)
            rows[r] = b
            return b
        }

        func xml(footer: String) -> String {
            let last = rows.keys.max() ?? 1
            var x = xmlDecl
            x += "<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" "
            x += "xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\">"
            x += "<sheetPr><pageSetUpPr fitToPage=\"1\"/></sheetPr>"
            x += "<dimension ref=\"A1:G\(last)\"/>"
            x += "<sheetViews><sheetView workbookViewId=\"0\" showGridLines=\"0\" zoomScale=\"110\" zoomScaleNormal=\"110\">"
            x += "<selection activeCell=\"C8\" sqref=\"C8\"/></sheetView></sheetViews>"
            x += "<sheetFormatPr defaultRowHeight=\"18\"/>"
            x += "<cols>"
            for (i, w) in [3.0, 38.0, 14.0, 10.0, 12.0, 14.0, 16.0].enumerated() {
                x += "<col min=\"\(i + 1)\" max=\"\(i + 1)\" width=\"\(w)\" customWidth=\"1\"/>"
            }
            x += "</cols><sheetData>"
            for r in rows.keys.sorted() {
                guard let b = rows[r] else { continue }
                x += "<row r=\"\(r)\""
                if let h = b.height { x += " ht=\"\(Formatters.plain(h))\" customHeight=\"1\"" }
                x += ">"
                // Columns must be ascending within a row; last write to a column wins.
                var byCol: [Int: (Value, Style)] = [:]
                for (c, v, st) in b.cells { byCol[c.rawValue] = (v, st) }
                // A ruled row (income, gift, item, bottom-line) draws its hairline
                // across B…G, not just under the cells that happen to hold values.
                if let first = byCol[Col.B.rawValue], first.1 == .label || first.1 == .item {
                    for c in Col.C.rawValue...Col.G.rawValue where byCol[c] == nil {
                        byCol[c] = (.blank, .rule)
                    }
                }
                for c in byCol.keys.sorted() {
                    guard let (v, st) = byCol[c] else { continue }
                    let ref = "\(BudgetXLSX.colRef(c))\(r)"
                    switch v {
                    case .text(let s):
                        x += "<c r=\"\(ref)\" s=\"\(st.rawValue)\" t=\"inlineStr\"><is><t xml:space=\"preserve\">\(BudgetXLSX.esc(s))</t></is></c>"
                    case .number(let n):
                        x += "<c r=\"\(ref)\" s=\"\(st.rawValue)\"><v>\(BudgetXLSX.numStr(n))</v></c>"
                    case .formula(let f, cached: let cached):
                        x += "<c r=\"\(ref)\" s=\"\(st.rawValue)\"><f>\(BudgetXLSX.esc(f))</f><v>\(BudgetXLSX.numStr(cached))</v></c>"
                    case .blank:
                        x += "<c r=\"\(ref)\" s=\"\(st.rawValue)\"/>"
                    }
                }
                x += "</row>"
            }
            x += "</sheetData>"
            x += "<printOptions horizontalCentered=\"1\"/>"
            x += "<pageMargins left=\"0.5\" right=\"0.5\" top=\"0.6\" bottom=\"0.6\" header=\"0.3\" footer=\"0.3\"/>"
            x += "<pageSetup paperSize=\"1\" orientation=\"portrait\" fitToWidth=\"1\" fitToHeight=\"0\"/>"
            // &L / &R are header-footer section codes; "&&" would be a literal ampersand.
            let footerText = footer.replacingOccurrences(of: "&", with: "&&")
            x += "<headerFooter><oddFooter>\(BudgetXLSX.esc("&L&\"Arial,Regular\"&8\(footerText)&R&\"Arial,Regular\"&8Page &P of &N"))</oddFooter></headerFooter>"
            x += "</worksheet>"
            return x
        }
    }

    // MARK: Helpers

    /// Bijective base-26 column reference (0 -> A, 25 -> Z, 26 -> AA).
    static func colRef(_ col: Int) -> String {
        var c = col
        var s = ""
        repeat {
            let rem = c % 26
            s = String(Character(UnicodeScalar(UInt8(65 + rem)))) + s
            c = c / 26 - 1
        } while c >= 0
        return s
    }

    static func esc(_ s: String) -> String {
        var out = ""
        out.reserveCapacity(s.count)
        for ch in s {
            switch ch {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            case "'": out += "&apos;"
            default: out.append(ch)
            }
        }
        return out
    }

    // Clean decimal for <v> (no trailing ".0", no scientific for budget values).
    static func numStr(_ n: Double) -> String {
        n.isFinite ? Formatters.plain(n) : "0"
    }

    // MARK: Styles
    //
    // Bloom's ink: deep plum #8E1560 for structure, cherry #E2417F for the one
    // accent rule, wine #421527 for body text, muted mauve #8F5F7E (5.6:1 on
    // white) for secondary copy. Georgia carries the headings (a serif that echoes
    // the app's Playfair and exists on every Mac, PC and iPhone); Arial carries the
    // figures. Fills are blush tints, never gray.

    private static let numFmts =
        "<numFmts count=\"3\">" +
        "<numFmt numFmtId=\"164\" formatCode=\"&quot;$&quot;#,##0.00;(&quot;$&quot;#,##0.00);&quot;$&quot;0.00\"/>" +
        "<numFmt numFmtId=\"165\" formatCode=\"0.0%\"/>" +
        "<numFmt numFmtId=\"166\" formatCode=\"&quot;$&quot;#,##0.00;[Red](&quot;$&quot;#,##0.00);&quot;$&quot;0.00\"/>" +
        "</numFmts>"

    // 0 body, 1 title, 2 subtitle, 3 section, 4 header, 5 emphasis, 6 muted,
    // 7 grand figure, 8 note, 9 strong body
    private static let fonts =
        "<fonts count=\"10\">" +
        "<font><sz val=\"10\"/><color rgb=\"FF421527\"/><name val=\"Arial\"/><family val=\"2\"/></font>" +
        "<font><sz val=\"24\"/><color rgb=\"FF8E1560\"/><name val=\"Georgia\"/><family val=\"1\"/></font>" +
        "<font><i/><sz val=\"10\"/><color rgb=\"FF8F5F7E\"/><name val=\"Georgia\"/><family val=\"1\"/></font>" +
        "<font><b/><sz val=\"13\"/><color rgb=\"FF8E1560\"/><name val=\"Georgia\"/><family val=\"1\"/></font>" +
        "<font><b/><sz val=\"9\"/><color rgb=\"FF8E1560\"/><name val=\"Arial\"/><family val=\"2\"/></font>" +
        "<font><b/><sz val=\"10\"/><color rgb=\"FF8E1560\"/><name val=\"Arial\"/><family val=\"2\"/></font>" +
        "<font><sz val=\"10\"/><color rgb=\"FF8F5F7E\"/><name val=\"Arial\"/><family val=\"2\"/></font>" +
        "<font><b/><sz val=\"13\"/><color rgb=\"FF8E1560\"/><name val=\"Arial\"/><family val=\"2\"/></font>" +
        "<font><i/><sz val=\"9\"/><color rgb=\"FF8F5F7E\"/><name val=\"Arial\"/><family val=\"2\"/></font>" +
        "<font><b/><sz val=\"10\"/><color rgb=\"FF421527\"/><name val=\"Arial\"/><family val=\"2\"/></font>" +
        "</fonts>"

    // 0 none, 1 gray125 (both required by the spec), 2 header blush, 3 category
    // band, 4 input shade
    private static let fills =
        "<fills count=\"5\">" +
        "<fill><patternFill patternType=\"none\"/></fill>" +
        "<fill><patternFill patternType=\"gray125\"/></fill>" +
        "<fill><patternFill patternType=\"solid\"><fgColor rgb=\"FFFBE3ED\"/><bgColor indexed=\"64\"/></patternFill></fill>" +
        "<fill><patternFill patternType=\"solid\"><fgColor rgb=\"FFFDF1F6\"/><bgColor indexed=\"64\"/></patternFill></fill>" +
        "<fill><patternFill patternType=\"solid\"><fgColor rgb=\"FFFFF0F6\"/><bgColor indexed=\"64\"/></patternFill></fill>" +
        "</fills>"

    // 0 none, 1 cherry rule under headers, 2 blush row rule, 3 plum rule over
    // totals, 4 plum rule over + double under (the grand total)
    private static let borders =
        "<borders count=\"5\">" +
        "<border><left/><right/><top/><bottom/><diagonal/></border>" +
        "<border><left/><right/><top/><bottom style=\"medium\"><color rgb=\"FFE2417F\"/></bottom><diagonal/></border>" +
        "<border><left/><right/><top/><bottom style=\"thin\"><color rgb=\"FFF3D9E4\"/></bottom><diagonal/></border>" +
        "<border><left/><right/><top style=\"thin\"><color rgb=\"FF8E1560\"/></top><bottom/><diagonal/></border>" +
        "<border><left/><right/><top style=\"thin\"><color rgb=\"FF8E1560\"/></top><bottom style=\"double\"><color rgb=\"FF8E1560\"/></bottom><diagonal/></border>" +
        "</borders>"

    /// One <xf> per Style case, same order.
    private static let cellXfs: String = {
        func xf(_ numFmt: Int, _ font: Int, _ fill: Int, _ border: Int,
                h: String? = nil, indent: Int = 0) -> String {
            var a = "<xf numFmtId=\"\(numFmt)\" fontId=\"\(font)\" fillId=\"\(fill)\" borderId=\"\(border)\" xfId=\"0\""
            if numFmt != 0 { a += " applyNumberFormat=\"1\"" }
            if font != 0 { a += " applyFont=\"1\"" }
            if fill != 0 { a += " applyFill=\"1\"" }
            if border != 0 { a += " applyBorder=\"1\"" }
            a += " applyAlignment=\"1\"><alignment vertical=\"center\""
            if let h { a += " horizontal=\"\(h)\"" }
            if indent > 0 { a += " indent=\"\(indent)\"" }
            return a + "/></xf>"
        }
        let list = [
            xf(0, 0, 0, 0),                       // plain
            xf(0, 1, 0, 0, h: "left"),            // title
            xf(0, 2, 0, 0, h: "left"),            // subtitle
            xf(0, 8, 0, 0, h: "left"),            // note
            xf(0, 3, 0, 0, h: "left"),            // section
            xf(0, 4, 2, 1, h: "left"),            // head
            xf(0, 4, 2, 1, h: "right"),           // headNum
            xf(0, 0, 0, 2, h: "left"),            // label
            xf(0, 0, 0, 2, h: "left", indent: 1), // item
            xf(164, 0, 4, 2, h: "right"),         // moneyIn
            xf(165, 0, 4, 2, h: "right"),         // pctIn
            xf(164, 0, 0, 2, h: "right"),         // money
            xf(0, 6, 0, 2, h: "right"),           // dash
            xf(0, 5, 3, 0, h: "left"),            // band
            xf(164, 5, 3, 0, h: "right"),         // bandMoney
            xf(164, 0, 4, 0, h: "right"),         // bandMoneyIn
            xf(9, 6, 3, 0, h: "right"),           // bandPct
            xf(0, 9, 0, 3, h: "left"),            // totalLabel
            xf(164, 9, 0, 3, h: "right"),         // totalMoney
            xf(9, 6, 0, 3, h: "right"),           // totalPct
            xf(0, 3, 0, 4, h: "left"),            // grandLabel
            xf(166, 7, 0, 4, h: "right"),         // grandMoney
            xf(0, 0, 0, 2)                        // rule
        ]
        return "<cellXfs count=\"\(list.count)\">" + list.joined() + "</cellXfs>"
    }()

    private static let stylesXML =
        xmlDecl +
        "<styleSheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">" +
        numFmts + fonts + fills + borders +
        "<cellStyleXfs count=\"1\"><xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\"/></cellStyleXfs>" +
        cellXfs +
        "<cellStyles count=\"1\"><cellStyle name=\"Normal\" xfId=\"0\" builtinId=\"0\"/></cellStyles>" +
        "</styleSheet>"

    // MARK: Static package parts

    private static let contentTypesXML =
        xmlDecl +
        "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">" +
        "<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>" +
        "<Default Extension=\"xml\" ContentType=\"application/xml\"/>" +
        "<Override PartName=\"/xl/workbook.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/>" +
        "<Override PartName=\"/xl/worksheets/sheet1.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>" +
        "<Override PartName=\"/xl/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml\"/>" +
        "<Override PartName=\"/docProps/core.xml\" ContentType=\"application/vnd.openxmlformats-package.core-properties+xml\"/>" +
        "<Override PartName=\"/docProps/app.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.extended-properties+xml\"/>" +
        "</Types>"

    private static let rootRelsXML =
        xmlDecl +
        "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">" +
        "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"xl/workbook.xml\"/>" +
        "<Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties\" Target=\"docProps/core.xml\"/>" +
        "<Relationship Id=\"rId3\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties\" Target=\"docProps/app.xml\"/>" +
        "</Relationships>"

    private static func coreXML(title: String) -> String {
        xmlDecl +
        "<cp:coreProperties xmlns:cp=\"http://schemas.openxmlformats.org/package/2006/metadata/core-properties\" " +
        "xmlns:dc=\"http://purl.org/dc/elements/1.1/\">" +
        "<dc:title>\(esc(title))</dc:title><dc:creator>Hannah&apos;s Calculator</dc:creator>" +
        "</cp:coreProperties>"
    }

    private static let appXML =
        xmlDecl +
        "<Properties xmlns=\"http://schemas.openxmlformats.org/officeDocument/2006/extended-properties\">" +
        "<Application>Hannah&apos;s Calculator</Application></Properties>"

    private static func workbookXML(sheetName: String) -> String {
        xmlDecl +
        "<workbook xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\">" +
        "<sheets><sheet name=\"\(esc(sheetName))\" sheetId=\"1\" r:id=\"rId1\"/></sheets>" +
        // Cached values are already right; this just makes Excel re-derive them
        // from the formulas the moment she changes anything (and on open).
        "<calcPr calcId=\"191029\" fullCalcOnLoad=\"1\"/>" +
        "</workbook>"
    }

    private static let workbookRelsXML =
        xmlDecl +
        "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">" +
        "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet1.xml\"/>" +
        "<Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\" Target=\"styles.xml\"/>" +
        "</Relationships>"
}
