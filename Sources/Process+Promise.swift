import Foundation
#if !PMKCocoaPods
import PromiseKit
#endif

#if os(macOS)

/**
 To import the `Process` category:

    use_frameworks!
    pod "PromiseKit/Foundation"

 Or `Process` is one of the categories imported by the umbrella pod:

    use_frameworks!
    pod "PromiseKit"
 
 And then in your sources:

    import PromiseKit
 */
extension Process {
    /**
     Launches the receiver and resolves when it exits.
     
         let proc = Process()
         proc.launchPath = "/bin/ls"
         proc.arguments = ["/bin"]
         proc.launch(.promise).flatMap { std in
             String(data: std.out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
         }.then { stdout in
             print(str)
         }
     */
    public func launch(_: PMKNamespacer) -> Promise<(out: Pipe, err: Pipe)> {
        let (stdout, stderr) = (Pipe(), Pipe())

        do {
            standardOutput = stdout
            standardError = stderr

            #if swift(>=4.0)
                if #available(OSX 10.13, *) {
                    try run()
                } else if let path = launchPath, FileManager.default.isExecutableFile(atPath: path) {
                    launch()
                } else {
                    throw PMKError.notExecutable(launchPath)
                }
            #else
                guard let path = launchPath, FileManager.default.isExecutableFile(atPath: path) else {
                    throw PMKError.notExecutable(launchPath)
                }
                launch()
            #endif
        } catch {
            return Promise(error: error)
        }

        return DispatchQueue.global().async(.promise) {
            self.waitUntilExit()

            guard self.terminationReason == .exit, self.terminationStatus == 0 else {
                throw PMKError.execution(self)
            }

            return (stdout, stderr)
        }
    }

    /**
     The error generated by PromiseKit’s `Process` extension
     */
    public enum PMKError {
        /// NOT AVAILABLE ON 10.13 and above because Apple provide this error handling themselves
        case notExecutable(String?)
        case execution(Process)
    }
}


extension Process.PMKError: LocalizedError {
    public var errorDescription: String {
        switch self {
        case .notExecutable(let path?):
            return "File not executable: \(path)"
        case .notExecutable(nil):
            return "No launch path specified"
        case .execution(let task):
            return "Failed executing: `\(task)` (\(task.terminationStatus))."
        }
    }
}


extension Process {
    /// Provided because Foundation’s is USELESS
    open override var description: String {
        let launchPath = self.launchPath ?? "$0"
        var args = [launchPath]
        arguments.flatMap{ args += $0 }
        return args.map { arg in
            if arg.characters.contains(" ") {
                return "\"\(arg)\""
            } else if arg == "" {
                return "\"\""
            } else {
                return arg
            }
        }.joined(separator: " ")
    }
}

#endif
