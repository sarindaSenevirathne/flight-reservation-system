import ballerina/http;
import ballerina/time;
import ballerina/log;

# A service representing a network-accessible API
# bound to port `9090`.
service /checkin on new http:Listener(9090) {

    resource function post checkin(@http:Payload CheckInRecord payload) returns CheckInRecord|error? {
        log:printInfo("making a new checkin: " + payload.toJsonString());
        time:Civil civil = time:utcToCivil(time:utcNow());
        payload.checkInTime = string `${civil.day}/${civil.month}/${civil.year}-${civil.hour}:${civil.minute}`;
        CheckInRecord saved = saveCheckInRecord(payload);
        return saved;
    }

    resource function get checkin/[int checkInId]() returns CheckInRecord|error? {
        return checkInEntries[checkInId];
    }
}

function saveCheckInRecord(CheckInRecord checkInRecord) returns CheckInRecord {
    int newId = 0;
    foreach var k in checkInEntries.keys() {
        if newId < k {
            newId = k;
        }
    }
    CheckInRecord saved = {
        firstName: checkInRecord.firstName,
        lastName: checkInRecord.lastName,
        flightDate: checkInRecord.flightDate,
        checkInTime: checkInRecord.checkInTime,
        id: newId + 1,
        seatNumber: checkInRecord.seatNumber,
        bookingId: checkInRecord.bookingId,
        flightNumber: checkInRecord.flightNumber
    };

    checkInEntries.add(saved);
    return saved;
}

table<CheckInRecord> key(id) checkInEntries = table [

];

type CheckInRecord record {
    readonly int id;
    string firstName;
    string lastName;
    string seatNumber;
    string checkInTime;
    string flightNumber;
    string flightDate;
    int bookingId;
};

