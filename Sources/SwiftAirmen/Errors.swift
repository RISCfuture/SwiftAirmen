import Foundation

/**
 The errors that can be thrown by `Parser` during a parsing operation.
 */
public enum Errors : Swift.Error, LocalizedError {
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
    
    /// The localized error description.
    public var errorDescription: String? {
        switch self {
            case let .invalidDate(date): return "Invalid date '\(date)'"
            case let .certificateTypeNotGiven(uniqueID):
                return "No certificate type for record \(uniqueID)"
            case let .levelNotGiven(uniqueID):
                return "No certificate level for record \(uniqueID)"
            case let .expirationDateNotGiven(uniqueID):
                return "No certificate expiration date for record \(uniqueID)"
            case let .medicalWithoutDate(uniqueID):
                return "No medical expiration date for record \(uniqueID)"
            case let .unknownMedicalClass(`class`, uniqueID):
                return "Unknown medical class “\(`class`)” for record \(uniqueID)"
            case let .unknownCertificateType(type, uniqueID):
                return "Unknown certificate type “\(type)” for record \(uniqueID)"
            case let .unknownRating(rating, uniqueID):
                return "Unknown rating “\(rating)” for record \(uniqueID)"
            case let .unknownCertificateLevel(level, uniqueID):
                return "Unknown certificate level “\(level)” for record \(uniqueID)"
            case let .unknownRatingLevel(level, uniqueID):
                return "Unknown rating level “\(level)” for record \(uniqueID)"
            case let .invalidRating(string, uniqueID):
                return "Improperly formatted rating “\(string)” for record \(uniqueID)"
        }
    }
}
