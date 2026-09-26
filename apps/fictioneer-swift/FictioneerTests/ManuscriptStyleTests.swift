import Testing
@testable import Fictioneer

struct ManuscriptStyleTests {
    @Test func romanNumerals() {
        #expect(RomanNumeral.format(1) == "I")
        #expect(RomanNumeral.format(2) == "II")
        #expect(RomanNumeral.format(4) == "IV")
        #expect(RomanNumeral.format(9) == "IX")
        #expect(RomanNumeral.format(14) == "XIV")
        #expect(RomanNumeral.format(40) == "XL")
        #expect(RomanNumeral.format(1989) == "MCMLXXXIX")
    }

    @Test func nonPositiveIsEmpty() {
        #expect(RomanNumeral.format(0) == "")
        #expect(RomanNumeral.format(-3) == "")
    }

    @Test func numberingPrefixIsStripped() {
        #expect(ManuscriptTitle.strippingNumbering("I. The Visitor") == "The Visitor")
        #expect(ManuscriptTitle.strippingNumbering("II. The Investigation") == "The Investigation")
        #expect(ManuscriptTitle.strippingNumbering("12. Departure") == "Departure")
        #expect(ManuscriptTitle.strippingNumbering("IV — The Storm") == "The Storm")
        #expect(ManuscriptTitle.strippingNumbering("3) Aftermath") == "Aftermath")
        #expect(ManuscriptTitle.strippingNumbering("2: Homecoming") == "Homecoming")
    }

    @Test func titlesWithoutNumberingPrefixAreUnchanged() {
        #expect(ManuscriptTitle.strippingNumbering("The Visitor") == "The Visitor")
        // A leading word that happens to be a Roman numeral is not numbering.
        #expect(ManuscriptTitle.strippingNumbering("I Am Legend") == "I Am Legend")
        // A bare numeral title has nothing left to show — keep it.
        #expect(ManuscriptTitle.strippingNumbering("IV") == "IV")
        #expect(ManuscriptTitle.strippingNumbering("Chapter 1: Homecoming") == "Chapter 1: Homecoming")
        #expect(ManuscriptTitle.strippingNumbering("") == "")
    }
}
