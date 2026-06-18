import AppKit
import Common

struct SplitCommand: Command {
    let args: SplitCmdArgs
    /*conforms*/ let shouldResetClosedWindowsCache = true

    func run(_ env: CmdEnv, _ io: CmdIo) -> BinaryExitCode {
        if config.enableNormalizationFlattenContainers {
            return .fail(io.err("'split' has no effect when 'enable-normalization-flatten-containers' normalization enabled. My recommendation: keep the normalizations enabled, and prefer 'join-with' over 'split'."))
        }
        guard let target = args.resolveTargetOrReportError(env, io) else { return .fail }
        guard let window = target.windowOrNil else {
            return .fail(io.err(noWindowIsFocused))
        }
        guard let parent = window.parent else { return .fail(io.err(bugPrompt())) }
        switch parent.cases {
            case .floatingWindowsContainer:
                // Nothing to do for floating and macOS native fullscreen windows
                return .fail(io.err("Can't split floating windows"))
            case .tilingContainer(let parent):
                let orientation: Orientation = switch args.arg.val {
                    case .vertical: .v
                    case .horizontal: .h
                    case .opposite: parent.orientation.opposite
                    // Auto-spiral: split along the focused window's longer side, so a
                    // wide window splits left/right and a tall window splits top/bottom.
                    // Fall back to the parent's opposite orientation if the window hasn't
                    // been laid out yet (no known rect).
                    case .auto:
                        if let rect = window.lastAppliedLayoutVirtualRect {
                            rect.width > rect.height ? .h : .v
                        } else {
                            parent.orientation.opposite
                        }
                }
                if parent.children.count == 1 {
                    parent.changeOrientation(orientation)
                } else {
                    let data = window.unbindFromParent()
                    let newParent = TilingContainer(
                        parent: parent,
                        adaptiveWeight: data.adaptiveWeight,
                        orientation,
                        .tiles,
                        index: data.index,
                    )
                    window.bind(to: newParent, adaptiveWeight: WEIGHT_AUTO, index: 0)
                }
                return .succ
            case .macosMinimizedWindowsContainer, .macosFullscreenWindowsContainer, .macosHiddenAppsWindowsContainer:
                return .fail(io.err("Can't split macos fullscreen, minimized windows and windows of hidden apps. This behavior may change in the future"))
            case .macosPopupWindowsContainer, .workspace:
                return .fail(io.err(bugPrompt())) // Impossible
        }
    }
}
