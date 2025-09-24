import Foundation
import StreamingCSV

// UNIQUE ID, FIRST NAME, LAST NAME, STREET 1, STREET 2, CITY, STATE, ZIP CODE, COUNTRY, REGION, MED CLASS, MED DATE, MED EXP DATE, BASIC MED COURSE DATE, BASIC MED CMEC DATE,

@CSVRowDecoderBuilder
struct AirmanBasicRow {
  @Field var uniqueID: String
  @Field var firstName: String?
  @Field var lastName: String?
  @Field var street1: String?
  @Field var street2: String?
  @Field var city: String?
  @Field var state: String?
  @Field var zipCode: String?
  @Field var country: String?
  @Field var region: String?
  @Field var medicalClassRaw: String?
  @Field var medicalDateRaw: String?
  @Field var medicalExpirationDateRaw: String?
  @Field var basicMedCourseDateRaw: String?
  @Field var basicMedCMECDateRaw: String?

  // Computed properties for parsed values
  var medicalClass: MedicalClass? {
    guard let raw = medicalClassRaw?.trimmingCharacters(in: .whitespacesAndNewlines),
      !raw.isEmpty
    else { return nil }
    return MedicalClass(rawValue: raw)
  }

  var medicalDate: DateComponents? {
    guard let raw = medicalDateRaw else { return nil }
    return DateComponents(csvString: raw)
  }

  var medicalExpirationDate: DateComponents? {
    guard let raw = medicalExpirationDateRaw else { return nil }
    return DateComponents(csvString: raw)
  }

  var basicMedCourseDate: DateComponents? {
    guard let raw = basicMedCourseDateRaw else { return nil }
    return DateComponents(csvString: raw)
  }

  var basicMedCMECDate: DateComponents? {
    guard let raw = basicMedCMECDateRaw else { return nil }
    return DateComponents(csvString: raw)
  }

  enum MedicalClass: String {
    case first = "1"
    case second = "2"
    case third = "3"
    case unknown8 = "8"
  }
}
