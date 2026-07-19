import XCTest
@testable import BloomCore

final class RecipeShareTests: XCTestCase {

    func testHTMLEscapeCoversAllFive() {
        XCTAssertEqual(RecipeShare.htmlEscape("Mom's B&B <\"pancakes\">"),
                       "Mom&#39;s B&amp;B &lt;&quot;pancakes&quot;&gt;")
    }

    func testHTMLEscapePlainTextUnchanged() {
        XCTAssertEqual(RecipeShare.htmlEscape("2 cups flour"), "2 cups flour")
    }

    func testSafeURLRejectsNonHTTP() {
        XCTAssertNil(RecipeShare.safeURL("javascript:alert(1)"))
        XCTAssertNil(RecipeShare.safeURL("data:text/html,<script>"))
        XCTAssertNil(RecipeShare.safeURL(""))
        XCTAssertEqual(RecipeShare.safeURL("https://example.com/r"), "https://example.com/r")
    }

    func testHostStripsWWW() {
        XCTAssertEqual(RecipeShare.host(of: "https://www.seriouseats.com/recipe"), "seriouseats.com")
        XCTAssertNil(RecipeShare.host(of: "notaurl"))
    }

    func testTextNumbersStepsAndBulletsIngredients() {
        let out = RecipeShare.text(
            name: "Cookies", serves: "24", time: "45 min",
            ingredients: ["1 cup butter", "  ", "2 eggs"],
            steps: ["Brown the butter\nuntil nutty", "", "Bake 11 min"],
            notes: "Chill overnight.", sourceUrl: "https://www.example.com/c")
        // blank ingredient/step dropped
        XCTAssertTrue(out.contains("•  1 cup butter"))
        XCTAssertTrue(out.contains("•  2 eggs"))
        XCTAssertFalse(out.contains("•  \n"))
        // steps numbered 1..2 (blank removed) and multiline flattened to one line
        XCTAssertTrue(out.contains("1. Brown the butter until nutty"))
        XCTAssertTrue(out.contains("2. Bake 11 min"))
        XCTAssertTrue(out.contains("INGREDIENTS"))
        XCTAssertTrue(out.contains("METHOD"))
        XCTAssertTrue(out.contains("NOTES"))
        XCTAssertTrue(out.contains("From example.com"))
    }

    func testTextEmptyRecipeStillHasTitle() {
        let out = RecipeShare.text(name: "", serves: "", time: "",
                                   ingredients: [], steps: [], notes: "", sourceUrl: "")
        XCTAssertTrue(out.hasPrefix("Recipe"))
        XCTAssertFalse(out.contains("INGREDIENTS"))   // no empty sections
        XCTAssertFalse(out.contains("From "))
    }
}
