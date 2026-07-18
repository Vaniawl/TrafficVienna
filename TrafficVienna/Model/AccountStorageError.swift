import Foundation
import Security

enum AccountStorageError: LocalizedError {
    case encodingFailed
    case keychain(OSStatus)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            String(localized: "Your account could not be saved securely.")
        case .keychain:
            String(localized: "Secure account storage is unavailable right now.")
        }
    }
}
