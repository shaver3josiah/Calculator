import XCTest
@testable import BloomCore

final class XLSXTests: XCTestCase {

    // MARK: - Little-endian byte readers (test-side ZIP inspection)

    private func u16(_ b: [UInt8], _ i: Int) -> Int {
        Int(b[i]) | (Int(b[i + 1]) << 8)
    }

    private func u32(_ b: [UInt8], _ i: Int) -> Int {
        Int(b[i]) | (Int(b[i + 1]) << 8) | (Int(b[i + 2]) << 16) | (Int(b[i + 3]) << 24)
    }

    /// Walk STORED local file headers, returning (name, raw payload) per entry.
    private func readEntries(_ b: [UInt8]) -> [(name: String, payload: [UInt8])] {
        var out: [(name: String, payload: [UInt8])] = []
        var pos = 0
        while pos + 30 <= b.count, b[pos] == 0x50, b[pos + 1] == 0x4B, b[pos + 2] == 0x03, b[pos + 3] == 0x04 {
            let comp = u32(b, pos + 18)
            let nameLen = u16(b, pos + 26)
            let extraLen = u16(b, pos + 28)
            let nameStart = pos + 30
            let name = String(bytes: b[nameStart..<nameStart + nameLen], encoding: .utf8) ?? ""
            let dataStart = nameStart + nameLen + extraLen
            let payload = Array(b[dataStart..<dataStart + comp])
            out.append((name, payload))
            pos = dataStart + comp
        }
        return out
    }

    // MARK: - CRC-32 known-answer

    func testCRC32KnownAnswer() {
        XCTAssertEqual(XLSXZip.crc32(Data("123456789".utf8)), 0xCBF4_3926)
        XCTAssertEqual(XLSXZip.crc32(Data([])), 0)
    }

    // MARK: - ZIP structure (hand-walked 2-entry example)

    // entries ("a","A"), ("bb","BB"):
    //   local a  : header 31 + data 1 = 32 bytes at offset 0
    //   local bb : header 32 + data 2 = 34 bytes at offset 32   (total local = 66)
    //   central a 47 + central bb 48  = 95                       (cdOffset = 66)
    //   EOCD 22                        → total 183, EOCD at 161
    func testZipStructureHandExample() {
        let data = XLSXZip.zipArchive(entries: [
            (name: "a", data: Data("A".utf8)),
            (name: "bb", data: Data("BB".utf8))
        ])
        let b = [UInt8](data)

        XCTAssertEqual(b.count, 183, "total archive size")

        // Local file header magic (PK\03\04) at 0 and at 32
        XCTAssertEqual(Array(b[0..<4]), [0x50, 0x4B, 0x03, 0x04])
        XCTAssertEqual(Array(b[32..<36]), [0x50, 0x4B, 0x03, 0x04])

        // First entry stored sizes: compressed (offset 18) and uncompressed (22) both == 1
        XCTAssertEqual(u32(b, 18), 1)
        XCTAssertEqual(u32(b, 22), 1)

        // Central directory (PK\01\02) begins at 66
        XCTAssertEqual(Array(b[66..<70]), [0x50, 0x4B, 0x01, 0x02])

        // EOCD (PK\05\06) at tail (161)
        XCTAssertEqual(Array(b[161..<165]), [0x50, 0x4B, 0x05, 0x06])
        XCTAssertEqual(u16(b, 161 + 10), 2, "EOCD total records")
        XCTAssertEqual(u32(b, 161 + 12), 95, "EOCD central directory size")
        XCTAssertEqual(u32(b, 161 + 16), 66, "EOCD central directory offset")

        // Reader round-trips names + payloads
        let entries = readEntries(b)
        XCTAssertEqual(entries.map { $0.name }, ["a", "bb"])
        XCTAssertEqual(entries[0].payload, Array("A".utf8))
        XCTAssertEqual(entries[1].payload, Array("BB".utf8))
    }

    // MARK: - Workbook

    private func fixtureDB() -> BudgetDB {
        // Single income, one category whose name and item contain characters
        // that MUST be XML-escaped.
        let cat = BudgetCategory(n: "Toys & Games", open: true, goal: 500, items: [
            BudgetRow(n: "Board <game>", a: 30, sel: false)
        ])
        let month = BudgetMonth(
            inc2On: false,
            inc: [
                BudgetIncome(label: "Paycheck", gross: 4000, tax: 20, ret: 5, oth: 0),
                BudgetIncome(label: "Income 2", gross: 0, tax: 0, ret: 0, oth: 0)
            ],
            cats: [cat]
        )
        return BudgetDB(v: 2, cur: "2026-07", months: ["2026-07": month])
    }

    private func part(_ data: Data, _ name: String) -> String {
        guard let e = readEntries([UInt8](data)).first(where: { $0.name == name }) else {
            XCTFail("\(name) missing")
            return ""
        }
        return String(bytes: e.payload, encoding: .utf8) ?? ""
    }

    func testWorkbookPackageParts() {
        let data = BudgetXLSX.workbook(db: fixtureDB())
        let b = [UInt8](data)
        XCTAssertEqual(Array(b[0..<4]), [0x50, 0x4B, 0x03, 0x04])
        XCTAssertEqual(u16(b, b.count - 22 + 10), 8, "workbook should hold 8 parts")
        let names = Set(readEntries(b).map { $0.name })
        for name in ["[Content_Types].xml", "_rels/.rels", "docProps/core.xml", "docProps/app.xml",
                     "xl/workbook.xml", "xl/_rels/workbook.xml.rels", "xl/styles.xml", "xl/worksheets/sheet1.xml"] {
            XCTAssertTrue(names.contains(name), name)
        }
        // Every part a relationship or content type points at must exist.
        let types = part(data, "[Content_Types].xml")
        XCTAssertTrue(types.contains("/xl/styles.xml"))
        XCTAssertTrue(part(data, "xl/_rels/workbook.xml.rels").contains("Target=\"styles.xml\""))
        let wb = part(data, "xl/workbook.xml")
        XCTAssertTrue(wb.contains("name=\"July 2026\""), "sheet is named for the month")
        XCTAssertTrue(wb.contains("fullCalcOnLoad=\"1\""))
        XCTAssertTrue(part(data, "docProps/core.xml").contains("Hannah&apos;s Budget \u{2014} July 2026"))
    }

    func testSheetEscapesText() {
        let xml = part(BudgetXLSX.workbook(db: fixtureDB()), "xl/worksheets/sheet1.xml")
        XCTAssertTrue(xml.contains("Toys &amp; Games"), "ampersand escaped")
        XCTAssertTrue(xml.contains("Board &lt;game&gt;"), "angle brackets escaped")
        XCTAssertTrue(xml.contains("Hannah&apos;s Budget"), "apostrophe escaped")
        XCTAssertFalse(xml.contains("Toys & Games"), "no raw ampersand in text")
        XCTAssertTrue(xml.contains("July 2026"))
    }

    func testSheetIsFormulaDrivenWithCachedValues() {
        let xml = part(BudgetXLSX.workbook(db: fixtureDB()), "xl/worksheets/sheet1.xml")
        // Rates are stored as fractions under a % format; take-home is a formula
        // over them, with the app's own figure cached: 4000 * (1 - .25) = 3000.
        XCTAssertTrue(xml.contains("<v>0.2</v>"), "tax 20% stored as 0.2")
        XCTAssertTrue(xml.contains("<f>MAX(0,C8*(1-MIN(1,D8+E8+F8)))</f><v>3000</v>"))
        XCTAssertTrue(xml.contains("<f>SUM(G8:G8)</f><v>3000</v>"), "take-home total")
        // Category total is a SUBTOTAL so the grand total can sweep the column.
        XCTAssertTrue(xml.contains("<f>SUBTOTAL(9,G14:G14)</f><v>30</v>"))
        XCTAssertTrue(xml.contains("<f>SUBTOTAL(9,G13:G14)</f><v>30</v>"), "total planned")
        XCTAssertTrue(xml.contains("<v>500</v>"), "goal")
        // No giving passed: bottom line is take-home minus planned.
        XCTAssertFalse(xml.contains("Give first"))
        XCTAssertTrue(xml.contains("<v>2970</v>"), "left to grow 3000 - 30")
        // Comparison operators inside formulas are escaped.
        XCTAssertTrue(xml.contains("IF(G9&gt;0"))
    }

    func testGivingRowsAreRatesTimesGross() {
        let giving = BudgetGiving(tithePct: 10, feastPct: 0, poorPct: 5, flat: 100)
        let xml = part(BudgetXLSX.workbook(db: fixtureDB(), giving: giving), "xl/worksheets/sheet1.xml")
        XCTAssertTrue(xml.contains("Give first"))
        XCTAssertTrue(xml.contains("Of gross"))
        XCTAssertTrue(xml.contains("<f>F13*C9</f><v>400</v>"), "tithe = 10% of 4000 gross")
        XCTAssertTrue(xml.contains("<f>F15*C9</f><v>200</v>"), "poor = 5% of gross")
        XCTAssertTrue(xml.contains("<f>SUM(G13:G16)</f><v>700</v>"), "given first incl. $100 flat")
        // 3000 take-home - 700 giving - 30 planned
        XCTAssertTrue(xml.contains("<v>2270</v>"), "left to grow after giving")
    }

    func testTakeHomeIncomeSkipsTheRates() {
        var db = fixtureDB()
        db.months["2026-07"]?.inc[0].net = true
        let xml = part(BudgetXLSX.workbook(db: db), "xl/worksheets/sheet1.xml")
        XCTAssertTrue(xml.contains("<f>MAX(0,C8)</f><v>4000</v>"))
        XCTAssertTrue(xml.contains("\u{2014}"), "dormant rates shown as a dash")
    }

    func testStylesMatchTheStyleTable() {
        let styles = part(BudgetXLSX.workbook(db: fixtureDB()), "xl/styles.xml")
        let xfCount = BudgetXLSX.Style.allCases.count
        XCTAssertTrue(styles.contains("<cellXfs count=\"\(xfCount)\">"))
        let cellXfs = styles.components(separatedBy: "<cellXfs")[1].components(separatedBy: "</cellXfs>")[0]
        XCTAssertEqual(cellXfs.components(separatedBy: "<xf ").count - 1, xfCount, "one xf per Style case")
        XCTAssertTrue(styles.contains("numFmtId=\"164\""))
    }

    /// CI writes a realistic month here (test.yml sets BLOOM_XLSX_SAMPLE_DIR and
    /// uploads it), so the formatting can be opened and judged, not just asserted.
    func testWriteSampleForReview() throws {
        guard let dir = ProcessInfo.processInfo.environment["BLOOM_XLSX_SAMPLE_DIR"] else {
            throw XCTSkip("set BLOOM_XLSX_SAMPLE_DIR to write a sample workbook")
        }
        var m = BudgetDefaults.month()
        m.cats[0].goal = 1500
        let db = BudgetDB(v: 2, cur: "2026-10", months: ["2026-10": m])
        let giving = BudgetGiving(tithePct: 10, feastPct: 10, poorPct: 10, flat: 100)
        let url = URL(fileURLWithPath: dir).appendingPathComponent(BudgetXLSX.fileName(for: db.cur))
        try BudgetXLSX.workbook(db: db, giving: giving).write(to: url)
    }

    func testFileName() {
        XCTAssertEqual(BudgetXLSX.fileName(for: "2026-07"), "Hannah's Budget 2026-07 July.xlsx")
        XCTAssertEqual(BudgetXLSX.fileName(for: "2026-12"), "Hannah's Budget 2026-12 December.xlsx")
        XCTAssertEqual(BudgetXLSX.fileName(for: "bad/key"), "Hannah's Budget bad-key.xlsx")
    }
}
