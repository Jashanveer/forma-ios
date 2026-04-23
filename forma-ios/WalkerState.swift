import Foundation
import CoreGraphics
import Observation
import QuartzCore
#if canImport(UIKit)
import UIKit
#endif

@Observable
class WalkerState {
    var positionProgress: CGFloat = 0.3
    var goingRight = true
    var isWalking = false
    var travelDistance: CGFloat = 500

    // Video timing (from lil-agents frame analysis for Bruce).
    // The standing buffers at both ends are padded beyond the raw frame
    // analysis so positionProgress only changes while the video is definitely
    // showing walking frames — absorbs the ~50–150ms latency between
    // `AVPlayer.play()` being called and the first walking frame actually
    // landing on screen. Without the pad, Bruce would drift sideways while
    // his legs were still in the standing pose ("sliding while standing").
    private let videoDuration: CFTimeInterval = 10.0
    private let accelStart: CFTimeInterval = 3.3
    private let fullSpeedStart: CFTimeInterval = 4.0
    private let decelStart: CFTimeInterval = 7.8
    private let walkStop: CFTimeInterval = 8.3

    private var walkStartTime: CFTimeInterval = 0
    private var walkStartPos: CGFloat = 0
    private var walkEndPos: CGFloat = 0
    #if canImport(UIKit)
    private var displayLink: CADisplayLink?
    private var displayLinkTarget: DisplayLinkTarget?
    #else
    private var frameTimer: Timer?
    #endif
    private var pauseWorkItem: DispatchWorkItem?

    deinit {
        stopTicking()
        pauseWorkItem?.cancel()
    }

    func start() {
        enterPause()
    }

    /// Fully halt the walker — stops ticking and cancels any pending walk
    /// cycle. `positionProgress` and `goingRight` stay where they are, so the
    /// character freezes on screen. Safe to call repeatedly.
    func pause() {
        stopTicking()
        pauseWorkItem?.cancel()
        pauseWorkItem = nil
        isWalking = false
    }

    /// Resume the idle → walk cycle from the current `positionProgress`.
    func resume() {
        guard !isWalking, pauseWorkItem == nil else { return }
        enterPause()
    }

    private func enterPause() {
        stopTicking()
        isWalking = false
        let delay = Double.random(in: 3.0...8.0)
        let work = DispatchWorkItem { [weak self] in self?.startWalk() }
        pauseWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func startWalk() {
        if positionProgress > 0.85 {
            goingRight = false
        } else if positionProgress < 0.15 {
            goingRight = true
        } else {
            goingRight = Bool.random()
        }

        walkStartPos = positionProgress

        let referenceWidth: CGFloat = 500
        let walkPixels = CGFloat.random(in: 0.25...0.5) * referenceWidth
        let walkAmount = travelDistance > 0 ? walkPixels / travelDistance : 0.3

        if goingRight {
            walkEndPos = min(walkStartPos + walkAmount, 1.0)
        } else {
            walkEndPos = max(walkStartPos - walkAmount, 0.0)
        }

        isWalking = true
        walkStartTime = CACurrentMediaTime()
        startTicking()
    }

    private func startTicking() {
        stopTicking()
        #if canImport(UIKit)
        let target = DisplayLinkTarget { [weak self] in self?.tick() }
        let link = CADisplayLink(target: target, selector: #selector(DisplayLinkTarget.fire))
        // Opt into ProMotion. The Info.plist key
        // `CADisableMinimumFrameDurationOnPhone` also has to be set,
        // otherwise iOS caps third-party apps at 60Hz regardless.
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        displayLinkTarget = target
        displayLink = link
        #else
        frameTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        #endif
    }

    private func stopTicking() {
        #if canImport(UIKit)
        displayLink?.invalidate()
        displayLink = nil
        displayLinkTarget = nil
        #else
        frameTimer?.invalidate()
        frameTimer = nil
        #endif
    }

    private func tick() {
        let elapsed = CACurrentMediaTime() - walkStartTime

        if elapsed >= videoDuration {
            stopTicking()
            positionProgress = walkEndPos
            enterPause()
            return
        }

        let walkNorm = movementPosition(at: elapsed)
        positionProgress = walkStartPos + (walkEndPos - walkStartPos) * walkNorm
    }

    private func movementPosition(at videoTime: CFTimeInterval) -> CGFloat {
        let dIn = fullSpeedStart - accelStart
        let dLin = decelStart - fullSpeedStart
        let dOut = walkStop - decelStart

        let v = 1.0 / (dIn / 2.0 + dLin + dOut / 2.0)

        if videoTime <= accelStart {
            return 0.0
        } else if videoTime <= fullSpeedStart {
            let t = videoTime - accelStart
            return CGFloat(v * t * t / (2.0 * dIn))
        } else if videoTime <= decelStart {
            let easeInDist = v * dIn / 2.0
            let t = videoTime - fullSpeedStart
            return CGFloat(easeInDist + v * t)
        } else if videoTime <= walkStop {
            let easeInDist = v * dIn / 2.0
            let linearDist = v * dLin
            let t = videoTime - decelStart
            return CGFloat(easeInDist + linearDist + v * (t - t * t / (2.0 * dOut)))
        } else {
            return 1.0
        }
    }
}

#if canImport(UIKit)
// CADisplayLink needs an @objc selector target. Keeping WalkerState a plain
// @Observable Swift class means we route the callback through this thin
// NSObject wrapper.
private final class DisplayLinkTarget: NSObject {
    private let closure: () -> Void
    init(_ closure: @escaping () -> Void) { self.closure = closure }
    @objc func fire() { closure() }
}
#endif
