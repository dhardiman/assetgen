//
//  AssetCatalog.swift
//  AssetGen
//
//  Created by David Hardiman on 30/09/2019.
//

import Foundation

class AssetGroup: CustomStringConvertible {
    let parent: AssetGroup?
    let namespace: String
    private(set) var groups: [AssetGroup]?
    let images: [ImageAsset]?

    let providesNamespace: Bool

    let url: URL

    let bundleNameClass: String

    init(url: URL, parent: AssetGroup?) {
        self.url = url
        self.parent = parent
        namespace = parent == nil ? "" : url.lastPathComponent
        bundleNameClass = parent == nil ? url.deletingPathExtension().lastPathComponent + "Bundle" : parent!.bundleNameClass
        providesNamespace = parent == nil ? false : contentsAtURLProvidesNamespace(url)
        let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
        images = contents?.filter { $0.pathExtension == "imageset" }
            .map { ImageAsset(name: $0.deletingPathExtension().lastPathComponent) }
        groups = contents?.filter { $0.isImageSet == false && $0.isGroupDirectory }
            .map { AssetGroup(url: $0, parent: self) }
    }

    var description: String {
        var heirarchy = [AssetGroup]()
        var currentParent = parent
        while currentParent != nil {
            heirarchy.append(currentParent!)
            currentParent = currentParent?.parent
        }
        heirarchy.append(self)
        let namespaceString = heirarchy.compactMap { $0.providesNamespace ? $0 : nil }
            .map { $0.namespace }
            .sorted()
            .joined(separator: "/")
        let imageOutput = images?.map { $0.stringRepresentation(for: namespaceString, bundleNameClass: bundleNameClass) }
            .sorted()
            .joined(separator: "\n\n") ?? ""
        let groupsOutput = groups?.map { "\($0)" }.joined(separator: "\n\n") ?? ""
        let template: String
        if parent != nil {
            template = """
            enum \(namespace.replacingOccurrences(of: " ", with: "")) {
            {content}
            }
            """
        } else {
            let assetCatalogueName = url.deletingPathExtension().lastPathComponent
            template = """
            /* \(assetCatalogueName).swift auto-generated from \(url.lastPathComponent) */
            import UIKit

            // swiftlint:disable type_body_length file_length superfluous_disable_command
            enum \(assetCatalogueName) {
            {content}
            }

            private class \(bundleNameClass) {}
            // swiftlint:enable type_body_length file_length superfluous_disable_command
            """
        }
        let content = """
        \(imageOutput)

        \(groupsOutput)
        """
        return template.replacingOccurrences(of: "{content}", with: content)
    }
}

struct ImageAsset {
    let name: String

    private static let splitChars = ["_", "-", " ", "&"]

    var swiftName: String {
        let containsSplitChars = ImageAsset.splitChars.map { name.contains($0) }
            .contains(true)
        guard containsSplitChars else { return name.lowercasedFirstLetter }
        let split = name.split { ImageAsset.splitChars.contains(String($0)) }
            .map { String($0) }
        return split.enumerated()
            .map { $0.offset > 0 ? $0.element.capitalized : $0.element.lowercasedFirstLetter }
            .joined()
    }

    private func qualifiedName(for namespace: String) -> String {
        guard namespace.isEmpty == false else { return name }
        return "\(namespace)/\(name)"
    }

    func stringRepresentation(for namespace: String, bundleNameClass: String) -> String {
        return """
        static var \(swiftName): UIImage? {
            return UIImage(named: "\(qualifiedName(for: namespace))", in: Bundle(for: \(bundleNameClass).self), compatibleWith: nil)
        }
        """
    }
}

private extension String {
    var lowercasedFirstLetter: String {
        return prefix(1).lowercased() + dropFirst()
    }
}

private func contentsAtURLProvidesNamespace(_ url: URL) -> Bool {
    let config = url.appendingPathComponent("Contents.json")
    guard let data = try? Data(contentsOf: config) else { return false }
    let decoder = JSONDecoder()
    let contents = try? decoder.decode(AssetContents.self, from: data)
    return contents?.properties.providesNamespace ?? false
}

private struct AssetContents: Decodable {
    struct Info: Decodable {
        let version: Int
        let author: String
    }

    struct Properties: Decodable {
        let providesNamespace: Bool
        enum CodingKeys: String, CodingKey {
            case providesNamespace = "provides-namespace"
        }
    }

    let info: Info
    let properties: Properties
}

private extension URL {
    var isDirectory: Bool {
        var isDir: ObjCBool = ObjCBool(false)
        FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        return isDir.boolValue
    }

    var isImageSet: Bool {
        return pathExtension == "imageset" || pathExtension == "appiconset"
    }

    var isAsset: Bool {
        return pathExtension.hasSuffix("set")
    }

    var isGroupDirectory: Bool {
        return isDirectory && isAsset == false
    }
}
