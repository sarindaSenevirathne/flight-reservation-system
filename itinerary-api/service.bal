import ballerina/http;

# A service representing a network-accessible API
# bound to port `9090`.
service /itinerary on new http:Listener(9090) {

    resource function get flight(string origin, string destination, string? flightDate) returns ItineraryItem[]|error {
        
        if flightDate is () {
            return from ItineraryItem i in flightItineraries
                     where i.origin == origin && i.destination == destination select i;
        } else {
            return from ItineraryItem i in flightItineraries
                     where i.origin == origin && i.destination == destination && i.flightDate == flightDate select i;

        }
    }
}

table<ItineraryItem> key(id) flightItineraries = table [
        {
            id: 1,
            flightNumber: "FL1",
            origin: "SFO",
            destination: "NYC",
            flightDate: "2022/02/10",
            checkInTime: "08:30",
            arrivalDate: "2022/02/12",
            arrivalTime: "18:45",
            distanceInKMs: 7000
        },
        {
            id: 2,
            flightNumber: "FL2",
            origin: "CMB",
            destination: "DOH",
            flightDate: "2022/02/10",
            checkInTime: "08:30",
            arrivalDate: "2022/02/10",
            arrivalTime: "10:45",
            distanceInKMs: 3000
        },
        {
            id: 3,
            flightNumber: "FL3",
            origin: "CMB",
            destination: "LHR",
            flightDate: "2022/02/10",
            checkInTime: "10:30",
            arrivalDate: "2022/02/11",
            arrivalTime: "12:45",
            distanceInKMs: 12000
            
        },
        {
            id: 4,
            flightNumber: "FL4",
            origin: "BER",
            destination: "LHR",
            flightDate: "2022/02/10",
            checkInTime: "13:30",
            arrivalDate: "2022/02/11",
            arrivalTime: "20:45",
            distanceInKMs: 4000
        }
    ];



type ItineraryItem record {
    readonly int id;
	string flightNumber;
	string origin;
	string destination;
    string flightDate;
    string checkInTime;
    string arrivalDate;
    string arrivalTime;
    int distanceInKMs;
};