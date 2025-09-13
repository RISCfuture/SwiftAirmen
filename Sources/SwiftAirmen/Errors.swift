import Foundation

/**
 The errors that can be thrown by `Parser` during a parsing operation.
 */
public enum Errors: Swift.Error {
    /**
     A date was improperly formatted.
     
     - Parameter string: The unparsed date.
     */
    case invalidDate(_ string: String)

    /**
     A certificate did not have a type.
     
     - Parameter uniqueID: The airmen record ID.
     */
    case certificateTypeNotGiven(uniqueID: String)

    /**
     A certificate did not have a level.
     
     - Parameter uniqueID: The airmen record ID.
     */
    case levelNotGiven(uniqueID: String)

    /**
     An expiring certificate did not have an expiration date.
     
     - Parameter uniqueID: The airmen record ID.
     */
    case expirationDateNotGiven(uniqueID: String)

    /**
     A medical certificate did not have an expiration date.
     
     - Parameter uniqueID: The airmen record ID.
     */
    case medicalWithoutDate(uniqueID: String)

    /**
     An unknown medical class was encountered.
     
     - Parameter class: The unparsed medical class.
     - Parameter uniqueID: The airmen record ID.
     */
    case unknownMedicalClass(_ class: String, uniqueID: String)

    /**
     An unknown certificate type was encountered.
     
     - Parameter type: The unparsed certificate type.
     - Parameter uniqueID: The airmen record ID.
     */
    case unknownCertificateType(_ type: String, uniqueID: String)

    /**
     An unknown certificate rating was encountered.
     
     - Parameter rating: The unparsed rating.
     - Parameter uniqueID: The airmen record ID.
     */
    case unknownRating(_ rating: String, uniqueID: String)

    /**
     An unknown certificate level was encountered.
     
     - Parameter level: The unparsed certificate level.
     - Parameter uniqueID: The airmen record ID.
     */
    case unknownCertificateLevel(_ level: String, uniqueID: String)

    /**
     An unknown rating level was encountered.
     
     - Parameter level: The unparsed rating level.
     - Parameter uniqueID: The airmen record ID.
     */
    case unknownRatingLevel(_ level: String, uniqueID: String)

    /**
     An improperly-formatted rating was encountered.
     
     - Parameter rating: The unparsed rating.
     - Parameter uniqueID: The airmen record ID.
     */
    case invalidRating(_ rating: String, uniqueID: String)

    /**
     An error when attempting to download the airmen CSV data.
     
     - Parameter request: The failed request.
     - Parameter response: The failed response (may be an `HTTPURLResponse`).
     */
    case networkError(request: URLRequest, response: URLResponse)

    /**
     A file was not found.

     - Parameter url: The URL to the file.
     */
    case fileNotFound(url: URL)
}

extension Errors: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .networkError:
                return String(localized: "Failed to download airmen data.", comment: "error description")
            default:
                return String(localized: "Failed to parse airmen data.", comment: "error description")
        }
    }

    public var failureReason: String? {
        switch self {
            case let .invalidDate(date):
                return String(localized: "Invalid date “\(date)”", comment: "failure reason")
            case let .certificateTypeNotGiven(uniqueID):
                return String(localized: "No certificate type for record \(uniqueID)", comment: "failure reason")
            case let .levelNotGiven(uniqueID):
                return String(localized: "No certificate level for record \(uniqueID)", comment: "failure reason")
            case let .expirationDateNotGiven(uniqueID):
                return String(localized: "No certificate expiration date for record \(uniqueID)", comment: "failure reason")
            case let .medicalWithoutDate(uniqueID):
                return String(localized: "No medical expiration date for record \(uniqueID)", comment: "failure reason")
            case let .unknownMedicalClass(`class`, uniqueID):
                return String(localized: "Unknown medical class “\(`class`)” for record \(uniqueID)", comment: "failure reason")
            case let .unknownCertificateType(type, uniqueID):
                return String(localized: "Unknown certificate type “\(type)” for record \(uniqueID)", comment: "failure reason")
            case let .unknownRating(rating, uniqueID):
                return String(localized: "Unknown rating “\(rating)” for record \(uniqueID)", comment: "failure reason")
            case let .unknownCertificateLevel(level, uniqueID):
                return String(localized: "Unknown certificate level “\(level)” for record \(uniqueID)", comment: "failure reason")
            case let .unknownRatingLevel(level, uniqueID):
                return String(localized: "Unknown rating level “\(level)” for record \(uniqueID)", comment: "failure reason")
            case let .invalidRating(string, uniqueID):
                return String(localized: "Improperly formatted rating “\(string)” for record \(uniqueID)", comment: "failure reason")
            case let .networkError(request, response):
                if let response = response as? HTTPURLResponse {
                    return String(localized: "HTTP response \(response.statusCode) received when downloading from “\(request.url!.absoluteString)”.", comment: "failure reason")
                }
                return String(localized: "Unexpected network error occurred when downloading from “\(request.url!.absoluteString)”.", comment: "failure reason")
            case let .fileNotFound(url):
                return String(localized: "File not found: \(url.path())")
        }
    }

    public var recoverySuggestion: String? {
        switch self {
            case let .networkError(request, _):
                return String(localized: "Verify that “\(request.url!.absoluteString)” is accessible via your Internet connection.", comment: "recovery suggestion")
            case .fileNotFound:
                return String(localized: "Verify that the file was not moved or deleted.")
            default:
                return String(localized: "Verify that the CSV file is not corrupt. If it isn’t, the format may have changed, requiring an update to SwiftAirmen.", comment: "recovery suggestion")
        }
    }
}
