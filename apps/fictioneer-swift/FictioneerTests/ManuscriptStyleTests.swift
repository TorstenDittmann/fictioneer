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
}
