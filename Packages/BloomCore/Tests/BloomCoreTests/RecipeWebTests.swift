import XCTest
@testable import BloomCore

/// Fixtures are the real shapes recipe sites publish, shrunk to the bone. They
/// live here as strings on purpose: a test that reaches for the network is a test
/// that fails on a train.
final class RecipeWebTests: XCTestCase {

    private func page(_ jsonLD: String) -> String {
        return "<html><head><script type=\"application/ld+json\">"
            + jsonLD
            + "</script></head><body><p>ads</p></body></html>"
    }

    // MARK: - Node shapes

    func testGraphShape() {
        let html = page("""
        {"@context":"https://schema.org","@graph":[
          {"@type":"WebPage","name":"Not the recipe"},
          {"@type":"Recipe","name":"Lemon Cake","recipeYield":"8 slices",
           "totalTime":"PT45M","recipeIngredient":["2 cups flour","3 eggs"],
           "recipeInstructions":["Mix","Bake"]}
        ]}
        """)
        let r = RecipeParse.webRecipe(html: html)
        XCTAssertEqual(r?.name, "Lemon Cake")
        XCTAssertEqual(r?.serves, "8 slices")
        XCTAssertEqual(r?.time, "45 min")
        XCTAssertEqual(r?.ingredients, ["2 cups flour", "3 eggs"])
        XCTAssertEqual(r?.steps, ["Mix", "Bake"])
    }

    func testBareObjectShape() {
        let html = page("""
        {"@context":"https://schema.org","@type":"Recipe","name":"Pancakes",
         "recipeIngredient":["1 cup milk"],"recipeInstructions":["Whisk"]}
        """)
        XCTAssertEqual(RecipeParse.webRecipe(html: html)?.name, "Pancakes")
    }

    func testTopLevelArrayShape() {
        let html = page("""
        [{"@type":"Organization","name":"Site"},
         {"@type":"Recipe","name":"Soup","recipeIngredient":["1 onion"]}]
        """)
        XCTAssertEqual(RecipeParse.webRecipe(html: html)?.name, "Soup")
    }

    func testTypeAsArray() {
        let html = page("""
        {"@type":["Recipe","NewsArticle"],"name":"Chili",
         "recipeIngredient":["1 lb beef"],"recipeInstructions":["Simmer"]}
        """)
        XCTAssertEqual(RecipeParse.webRecipe(html: html)?.name, "Chili")
    }

    // MARK: - Instruction shapes

    func testHowToStepObjects() {
        let html = page("""
        {"@type":"Recipe","name":"Bread","recipeIngredient":["500 g flour"],
         "recipeInstructions":[
           {"@type":"HowToStep","text":"Knead the dough."},
           {"@type":"HowToStep","text":"Bake at 220C."}]}
        """)
        XCTAssertEqual(RecipeParse.webRecipe(html: html)?.steps,
                       ["Knead the dough.", "Bake at 220C."])
    }

    func testHowToSectionFlattensNestedSteps() {
        let html = page("""
        {"@type":"Recipe","name":"Tart","recipeIngredient":["1 crust"],
         "recipeInstructions":[
           {"@type":"HowToSection","name":"For the crust","itemListElement":[
             {"@type":"HowToStep","text":"Rub in the butter."},
             {"@type":"HowToStep","text":"Chill 30 min."}]},
           {"@type":"HowToSection","name":"For the filling","itemListElement":[
             {"@type":"HowToStep","text":"Whisk the custard."}]}]}
        """)
        // Section headings are not steps she performs — only the leaves survive.
        XCTAssertEqual(RecipeParse.webRecipe(html: html)?.steps,
                       ["Rub in the butter.", "Chill 30 min.", "Whisk the custard."])
    }

    func testPlainStringInstructionsSplit() {
        let html = page("""
        {"@type":"Recipe","name":"Tea","recipeIngredient":["1 bag"],
         "recipeInstructions":"Boil the water. Steep for 3 minutes. Serve."}
        """)
        XCTAssertEqual(RecipeParse.webRecipe(html: html)?.steps,
                       ["Boil the water.", "Steep for 3 minutes.", "Serve."])
    }

    func testPlainStringInstructionsKeepDecimalsIntact() {
        let html = page("""
        {"@type":"Recipe","name":"Syrup","recipeIngredient":["sugar"],
         "recipeInstructions":"Heat 1.5 cups of water. Stir."}
        """)
        XCTAssertEqual(RecipeParse.webRecipe(html: html)?.steps,
                       ["Heat 1.5 cups of water.", "Stir."])
    }

    func testStepsStripHtmlTags() {
        let html = page("""
        {"@type":"Recipe","name":"Rice","recipeIngredient":["1 cup rice"],
         "recipeInstructions":[{"@type":"HowToStep","text":"Rinse <b>well</b>."}]}
        """)
        XCTAssertEqual(RecipeParse.webRecipe(html: html)?.steps, ["Rinse well."])
    }

    func testBrTagsBecomeStepBreaks() {
        let html = page("""
        {"@type":"Recipe","name":"Eggs","recipeIngredient":["2 eggs"],
         "recipeInstructions":"Crack the eggs<br>Whisk them<br>Scramble"}
        """)
        XCTAssertEqual(RecipeParse.webRecipe(html: html)?.steps,
                       ["Crack the eggs", "Whisk them", "Scramble"])
    }

    // MARK: - Durations

    func testDurationMinutesOnly() {
        XCTAssertEqual(RecipeParse.humanDuration("PT45M"), "45 min")
    }

    func testDurationHoursAndMinutes() {
        XCTAssertEqual(RecipeParse.humanDuration("PT1H30M"), "1 hr 30 min")
    }

    func testDurationHoursOnly() {
        XCTAssertEqual(RecipeParse.humanDuration("PT2H"), "2 hr")
    }

    func testDurationNormalisesOverflowMinutes() {
        XCTAssertEqual(RecipeParse.humanDuration("PT90M"), "1 hr 30 min")
    }

    func testDurationRejectsJunk() {
        XCTAssertNil(RecipeParse.humanDuration("about an hour"))
        XCTAssertNil(RecipeParse.humanDuration("PT0M"))
        XCTAssertNil(RecipeParse.humanDuration(42))
    }

    func testTimeFallsBackToCookTime() {
        let html = page("""
        {"@type":"Recipe","name":"Stew","cookTime":"PT2H",
         "recipeIngredient":["1 lb lamb"]}
        """)
        XCTAssertEqual(RecipeParse.webRecipe(html: html)?.time, "2 hr")
    }

    // MARK: - Entities

    func testEntityDecoding() {
        let html = page("""
        {"@type":"Recipe","name":"Salt &amp; Pepper Chips",
         "recipeIngredient":["1 tbsp Maldon &#39;flaky&#39; salt","&frac12; cup oil"],
         "recipeInstructions":["Toss &#x27;em well."]}
        """)
        let r = RecipeParse.webRecipe(html: html)
        XCTAssertEqual(r?.name, "Salt & Pepper Chips")
        XCTAssertEqual(r?.ingredients, ["1 tbsp Maldon 'flaky' salt", "\u{00bd} cup oil"])
        XCTAssertEqual(r?.steps, ["Toss 'em well."])
    }

    func testLooseAmpersandSurvives() {
        XCTAssertEqual(RecipeParse.decodeEntities("salt & pepper"), "salt & pepper")
        XCTAssertEqual(RecipeParse.decodeEntities("R&D;"), "R&D;")
    }

    // MARK: - Yield

    func testYieldAsNumber() {
        let html = page("""
        {"@type":"Recipe","name":"Buns","recipeYield":12,
         "recipeIngredient":["1 cup flour"]}
        """)
        XCTAssertEqual(RecipeParse.webRecipe(html: html)?.serves, "12")
    }

    func testYieldAsArrayTakesFirst() {
        let html = page("""
        {"@type":"Recipe","name":"Buns","recipeYield":["6","6 servings"],
         "recipeIngredient":["1 cup flour"]}
        """)
        XCTAssertEqual(RecipeParse.webRecipe(html: html)?.serves, "6")
    }

    // MARK: - Nothing to read

    func testNoRecipeReturnsNil() {
        let html = page("""
        {"@type":"NewsArticle","name":"Ten best kitchens","articleBody":"..."}
        """)
        XCTAssertNil(RecipeParse.webRecipe(html: html))
    }

    func testRecipeWithoutIngredientsReturnsNil() {
        let html = page("""
        {"@type":"Recipe","name":"Vibes only","recipeInstructions":["Believe"]}
        """)
        XCTAssertNil(RecipeParse.webRecipe(html: html))
    }

    func testPageWithNoJsonLdReturnsNil() {
        XCTAssertNil(RecipeParse.webRecipe(html: "<html><body>just words</body></html>"))
    }

    func testMalformedJsonDoesNotCrash() {
        XCTAssertNil(RecipeParse.webRecipe(html: page("{\"@type\":\"Recipe\", oops")))
    }

    // MARK: - The old caller keeps working

    func testJsonLDIngredientsStillWorks() {
        let html = page("""
        {"@graph":[{"@type":"Recipe","name":"Cake","recipeIngredient":["2 eggs","1 cup sugar"]}]}
        """)
        XCTAssertEqual(RecipeParse.jsonLDIngredients(html: html), ["2 eggs", "1 cup sugar"])
    }
}
