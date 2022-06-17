import ramithjayasingheznszn/passengerapi;
import ramithjayasingheznszn/bookingapi;
import ballerina/log;
import ballerina/http;
import ballerina/time;

configurable string clientId = ?;
configurable string clientSecret = ?;

type Reservation record {
    string passportNo;
    float fare;
    string flightNo;
    string flightDate;
    string origin;
    string destination;
    int id;
    int seats;
};

# A service representing a network-accessible API
# bound to port `9090`.
service /hello on new http:Listener(9090) {

    resource function post reserve(@http:Payload Reservation payload) returns Reservation|error? {

        log:printInfo("new reservation: " + payload.toJsonString());
        bookingapi:Client bookingapiEndpoint = check new ({auth: {clientId: clientId, clientSecret: clientSecret}});
        bookingapi:BookingRecord bookingRecord = {fare: payload.fare, flightDate: payload.flightDate, origin: payload.origin, destination: payload.destination, bookingDate: currentDate(), id: 0, seats: payload.seats, flightNumber: payload.flightNo, status: "NEW"};
        bookingapi:BookingRecord bookingResponse = check bookingapiEndpoint->postBooking(bookingRecord);
        passengerapi:Client passengerapiEndpoint = check new ({auth: {clientId: clientId, clientSecret: clientSecret}});
        passengerapi:BookingRecord postPassengerPassportnoBookingsBookingidResponse = check passengerapiEndpoint->postPassengerPassportnoBookingsBookingid(payload.passportNo, bookingResponse.id);
        payload.id = bookingResponse.id;
        return  payload;
    }
}

function currentDate() returns string {
    time:Civil civil = time:utcToCivil(time:utcNow());
    return string `${civil.year}/${civil.month}/${civil.day}`;
}

