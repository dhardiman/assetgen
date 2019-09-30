import Discourse
import Foundation

public class AssetGenCommand: Command {
    public let verb: String = "assetgen"

    public let description = "Generates a set of static constants for images in an asset catalog"

    @RequiredArgument(name: "target", usage: "The asset catalog to generate code for")
    var target: URL

    @OptionalArgument(name: "swiftVersion", usage: "The version of swift being targeted")
    var swiftVersion: String?

    @OptionalArgument(name: "swiftFormatPath", usage: "Path to the swift format binary")
    var swiftFormatPath: String?

    @OptionalArgument(name: "swiftFormatConfig", usage: "Path to the swift format config")
    var swiftFormatConfig: String?

    public init() {}

    public func run(outputStream: inout TextOutputStream) throws {
        outputStream.write("Generating code from \(target.lastPathComponent)")
        let rootCatalog = AssetGroup(url: target, parent: nil)

        outputStream.write("Writing temporary output to \(rootCatalog.temporaryURL.path)")
        try rootCatalog.description.write(to: rootCatalog.temporaryURL, atomically: true, encoding: .utf8)

        if let swiftFormatPath = swiftFormatPath {
            var options = [String: String]()
            options["--config"] = swiftFormatConfig
            options["--swiftversion"] = swiftVersion
            let args = options.flatMap { [$0.key, $0.value] }
            outputStream.write("Formatting temp file")
            runProcess(swiftFormatPath, with: [rootCatalog.temporaryURL.path, "--quiet"] + args)
        }
        outputStream.write("Reading files for diff")
        let formattedOutput = try Data(contentsOf: rootCatalog.temporaryURL)
        let existingOutput = try? Data(contentsOf: rootCatalog.outputURL)
        if formattedOutput != existingOutput {
            outputStream.write("Writing asset catalog output")
            do {
                try formattedOutput.write(to: rootCatalog.outputURL)
            } catch {
                outputStream.write("Failed to write output to \(rootCatalog.outputURL)")
                throw error
            }
        } else {
            outputStream.write("Asset catalog output hasn't changed, skipping write")
        }
        outputStream.write("Removing temp file")
        do {
            try FileManager.default.removeItem(at: rootCatalog.temporaryURL)
        } catch {
            outputStream.write("Failed to remove temp file: \(error)")
            throw error
        }
    }
}

private extension AssetGroup {
    var temporaryURL: URL {
        return outputURL.deletingPathExtension().appendingPathExtension("tmp").appendingPathExtension("swift")
    }

    var outputFileName: String {
        return url.appendingPathExtension("generated").appendingPathExtension("swift").lastPathComponent
    }

    var outputURL: URL {
        return url.deletingLastPathComponent().appendingPathComponent(outputFileName)
    }
}

@discardableResult
func runProcess(_ process: String, with arguments: [String], outputPipe: Pipe? = nil) -> [String] {
    guard FileManager.default.fileExists(atPath: process) else {
        print("Program is not installed - \(process)")
        return []
    }
    let task = Process()
    task.launchPath = process
    task.arguments = arguments
    let pipe = outputPipe ?? Pipe()
    task.standardOutput = pipe
    task.launch()
    task.waitUntilExit()

    guard outputPipe == nil else { return [] }
    var output: [String] = []
    let outdata = pipe.fileHandleForReading.readDataToEndOfFile()
    if var string = String(data: outdata, encoding: .utf8) {
        string = string.trimmingCharacters(in: .newlines)
        output = string.components(separatedBy: "\n")
    }
    return output
}
