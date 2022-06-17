import ballerina/log;
import ballerina/http;
import ballerina/time;
import ramithjayasingheznszn/inventoryapi;

configurable ApiCredentials inventoryApi = ?;

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    resource function post booking(@http:Payload BookingRecord payload) returns BookingRecord|error? {

        log:printInfo("making a new booking: " + payload.toJsonString());

        log:printInfo(string `adjusting flight inventory: flight number = ${payload.flightNumber}, flight date = ${payload.flightDate}, seats = ${payload.seats}`);

        inventoryapi:Client inventoryapiEndpoint = check new ({auth: {clientId: inventoryApi.clientId, clientSecret: inventoryApi.clientSecret}});
        inventoryapi:SeatAllocation postInventoryAllocateResponse = check inventoryapiEndpoint->postInventoryAllocate({flightNumber: payload.flightNumber, flightDate: payload.flightDate, seats: payload.seats});
        payload.status = BOOKING_CONFIRMED;
        payload.bookingDate = currentDate();
        BookingRecord saved = saveBookingRecord(payload);
        return saved;
    }

    resource function get booking/[int id]() returns BookingRecord|error? {
        return bookingInventory[id];
    }

    resource function post booking/[int id]/status/[string bookingStatus]() returns error? {
        BookingRecord? bookingRecord = bookingInventory[id];
        if bookingRecord is () {
            return error(string `unable to find the booking record, id: ${id}, booking status: ${bookingStatus}`);
        }
        bookingRecord.status = <BookingStatus>bookingStatus;
    }
}

type ApiCredentials record {|
    string clientId;
    string clientSecret;
|};

enum BookingStatus {
    NEW,
    BOOKING_CONFIRMED,
    CHECKED_IN
}

type Fare record {
    string flightNumber;
    string flightDate;
    decimal fare;
};

type BookingRecord record {
    readonly int id;
    string flightNumber;
    string origin;
    string destination;
    string flightDate;
    string bookingDate;
    decimal fare;
    int seats;
    BookingStatus status;
};

type Passenger record {
    string firstName;
    string lastName;
    string passportNumber;
};

table<BookingRecord> key(id) bookingInventory = table [

];

function saveBookingRecord(BookingRecord bookingRecord) returns BookingRecord {

    BookingRecord saved = {
        id: bookingInventory.nextKey(),
        fare: bookingRecord.fare,
        flightDate: bookingRecord.flightDate,
        origin: bookingRecord.origin,
        destination: bookingRecord.destination,
        bookingDate: bookingRecord.bookingDate,
        flightNumber: bookingRecord.flightNumber,
        seats: bookingRecord.seats,
        status: BOOKING_CONFIRMED
    };
    bookingInventory.add(saved);

    return saved;
}

function currentDate() returns string {
    time:Civil civil = time:utcToCivil(time:utcNow());
    return string `${civil.year}/${civil.month}/${civil.day}`;
}

