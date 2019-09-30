import Foundation
import Discourse

let handler = CommandHandler()
handler.register(AssetGenCommand())

do {
    try handler.run()
} catch {
    print("\(error.localizedDescription)")
    exit(6)
}
