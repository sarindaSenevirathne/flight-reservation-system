import ballerina/log;
import ballerina/http;

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    resource function get passenger/[string passportNo]() returns Passenger?|error {

        PassengerProfile? profile = findByPassportNo(passportNo);
        if profile is () {
            log:printWarn("unable to find passenger", passportNo = passportNo);
            return ();
        }
        return profile.personalDetails;
    }

    resource function post passenger(@http:Payload Passenger passenger) returns Passenger|error {
        PassengerProfile profile = {
            id: profiles.nextKey(),
            personalDetails: passenger,
            bookingRecords: table []
        };

        profiles.put(profile);
        return profile.personalDetails;
    }

    resource function get passenger/[string passportNo]/bookings(string status = PENDING) returns BookingRecord[]|error {
        PassengerProfile? profile = findByPassportNo(passportNo);
        if profile is () {
            return error("unable to find passenger", passportNo = passportNo);
        }

        BookingRecord[] bookings = from BookingRecord br in profile.bookingRecords
            where br.status == status
            select br;

        return bookings;
    }

    resource function post passenger/[string passportNo]/bookings/[int bookingId]() returns BookingRecord|error {
        PassengerProfile? profile = findByPassportNo(passportNo);
        if profile is () {
            return error("unable to find passenger", passportNo = passportNo);
        }

        BookingRecord? booking = profile.bookingRecords[bookingId];
        if !(booking is ()) {
            return error("booking already exists", existingBooking = booking);
        }
        BookingRecord latest = {
            flyingMiles: 0,
            bookingId: bookingId,
            status: PENDING
        };
        profile.bookingRecords.put(latest);
        return latest;
    }

    resource function patch passenger/[string passportNo]/bookings/[int bookingId](@http:Payload BookingRecord payload) returns BookingRecord|error {
        PassengerProfile? profile = findByPassportNo(passportNo);
        if profile is () {
            return error("unable to find passenger", passportNo = passportNo);
        }

        BookingRecord? booking = profile.bookingRecords[bookingId];
        if booking is () {
            return error("booking does not exist", passportNo = passportNo, bookingId = bookingId);
        }
        booking.status = payload.status;
        booking.flyingMiles = payload.flyingMiles;
        return booking;
    }

}

function findByPassportNo(string passportNo) returns PassengerProfile? {
    PassengerProfile[] found = from PassengerProfile pp in profiles
        where pp.personalDetails.passportNumber == passportNo
        limit 1
        select pp;

    if found.length() == 0 {
        return ();
    } else {
        return found[0];
    }
}

table<PassengerProfile> key(id) profiles = table [
        {
            personalDetails: {firstName: "Jane", lastName: "Smith", passportNumber: "N1111"},
            id: 1,
            bookingRecords: table [{
                        bookingId: 3433,
                        status: COMPLETED,
                        flyingMiles: 8000
                    }
    ]
        },
        {
            personalDetails: {firstName: "Adam", lastName: "Green", passportNumber: "N1112"},
            id: 2,
            bookingRecords: table [{
                        bookingId: 3434,
                        status: COMPLETED,
                        flyingMiles: 2000
                    }
    ]
        },
        {
            personalDetails: {firstName: "Ramith", lastName: "Jayasinghe", passportNumber: "N1113"},
            id: 3,
            bookingRecords: table [{
                        bookingId: 3434,
                        status: COMPLETED,
                        flyingMiles: 2000
                    }
    ]
        }

    ];

type Passenger record {
    string firstName;
    string lastName;
    string passportNumber;
};

type PassengerProfile record {
    readonly int id;
    Passenger personalDetails;
    table<BookingRecord> key(bookingId) bookingRecords = table [];
};

type BookingRecord record {
    readonly int bookingId;
    BookingStatus status;
    int flyingMiles;
};

enum BookingStatus {
    COMPLETED,
    PENDING
}
