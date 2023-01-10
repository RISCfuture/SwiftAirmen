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
}

extension Errors: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .networkError:
                return t("Failed to download airmen data.", comment: "error description")
            default:
                return t("Failed to parse airmen data.", comment: "error description")
        }
    }
    
    public var failureReason: String? {
        switch self {
            case let .invalidDate(date):
                return t("Invalid date “%@”", comment: "failure reason",
                         date)
            case let .certificateTypeNotGiven(uniqueID):
                return t("No certificate type for record %@", comment: "failure reason",
                         uniqueID)
            case let .levelNotGiven(uniqueID):
                return t("No certificate level for record %@", comment: "failure reason",
                         uniqueID)
            case let .expirationDateNotGiven(uniqueID):
                return t("No certificate expiration date for record %@", comment: "failure reason",
                         uniqueID)
            case let .medicalWithoutDate(uniqueID):
                return t("No medical expiration date for record %@", comment: "failure reason",
                         uniqueID)
            case let .unknownMedicalClass(`class`, uniqueID):
                return t("Unknown medical class “%@” for record %@", comment: "failure reason",
                         `class`, uniqueID)
            case let .unknownCertificateType(type, uniqueID):
                return t("Unknown certificate type %@” for record %@", comment: "failure reason",
                         type, uniqueID)
            case let .unknownRating(rating, uniqueID):
                return t("Unknown rating “%@” for record %@", comment: "failure reason",
                         rating, uniqueID)
            case let .unknownCertificateLevel(level, uniqueID):
                return t("Unknown certificate level “%@” for record %@", comment: "failure reason",
                         level, uniqueID)
            case let .unknownRatingLevel(level, uniqueID):
                return t("Unknown rating level “%@” for record %@", comment: "failure reason",
                         level, uniqueID)
            case let .invalidRating(string, uniqueID):
                return t("Improperly formatted rating “%@” for record %@", comment: "failure reason",
                         string, uniqueID)
            case let .networkError(request, response):
                if let response = response as? HTTPURLResponse {
                    return t("HTTP response %d received when downloading from “%@”.", comment: "failure reason",
                             response.statusCode, request.url!.absoluteString)
                } else {
                    return t("Unexpected network error occurred when downloading from “%@”.", comment: "failure reason",
                             request.url!.absoluteString)
                }
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
            case let .networkError(request, _):
                return t("Verify that “%@” is accessible via your Internet connection.", comment: "recovery suggestion",
                         request.url!.absoluteString)
            default:
                return t("Verify that the CSV file is not corrupt. If it isn’t, the format may have changed, requiring an update to SwiftAirmen.", comment: "recovery suggestion")
        }
    }
}

fileprivate func t(_ key: String, comment: String, _ arguments: CVarArg...) -> String {
    let format = NSLocalizedString(key, bundle: Bundle.module, comment: comment)
    if arguments.isEmpty {
        return format
    } else {
        return String(format: format, arguments: arguments)
    }
}
