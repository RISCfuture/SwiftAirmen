import Foundation

// UNIQUE ID, FIRST NAME, LAST NAME, STREET 1, STREET 2, CITY, STATE, ZIP CODE, COUNTRY, REGION, MED CLASS, MED DATE, MED EXP DATE, BASIC MED COURSE DATE, BASIC MED CMEC DATE,

struct AirmanBasicRow: Decodable {
    var uniqueID: String
    var firstName: String?
    var lastName: String?
    var street1: String?
    var street2: String?
    var city: String?
    var state: String?
    var zipCode:String?
    var country: String?
    var region: String?
    var medicalClass: MedicalClass?
    var medicalDate: DateComponents?
    var medicalExpirationDate: DateComponents?
    var basicMedCourseDate: DateComponents?
    var basicMedCMECDate: DateComponents?

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        uniqueID = try container.decode(String.self)
        firstName = trim(try container.decode(String.self))
        lastName = trim(try container.decode(String.self))
        street1 = trim(try container.decode(String.self))
        street2 = trim(try container.decode(String.self))
        city = trim(try container.decode(String.self))
        state = trim(try container.decode(String.self))
        zipCode = trim(try container.decode(String.self))
        country = trim(try container.decode(String.self))
        region = trim(try container.decode(String.self))

        medicalClass = try trim(try container.decodeIfPresent(String.self)).map { medClassStr in
            guard let medicalClass = MedicalClass(rawValue: medClassStr) else {
                throw Errors.unknownMedicalClass(medClassStr, uniqueID: uniqueID)
            }
            return medicalClass
        }

        medicalDate = try parseDate(try container.decodeIfPresent(String.self))
        medicalExpirationDate = try parseDate(try container.decodeIfPresent(String.self))
        basicMedCourseDate = try parseDate(try container.decodeIfPresent(String.self))
        basicMedCMECDate = try parseDate(try container.decodeIfPresent(String.self))
    }

    enum MedicalClass: String {
        case first = "1"
        case second = "2"
        case third = "3"
        case unknown8 = "8"
    }
    }
