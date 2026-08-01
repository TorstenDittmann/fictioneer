import AppKit
import Testing
@testable import Fictioneer

struct GhostColorTests {
    /// Regression: the streaming ghost (display alpha 1) must stay visibly
    /// muted. The original bug used tertiaryLabelColor.withAlphaComponent(1),
    /// which discarded the intrinsic muting and rendered like normal text.
    @Test func ghostAtFullDisplayAlphaIsStillMuted() {
        let color = GhostTextPresenter.ghostColor(alpha: 1)
        #expect(color.alphaComponent < 0.5)
        #expect(color.alphaComponent > 0.2)
    }

    @Test func fadeReducesAlphaFurther() {
        let full = GhostTextPresenter.ghostColor(alpha: 1)
        let fading = GhostTextPresenter.ghostColor(alpha: 0.35)
        #expect(fading.alphaComponent < full.alphaComponent)
    }
}
