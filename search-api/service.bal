import ballerina/http;
import ballerina/log;
import ramithjayasingheznszn/faresapi;
import ramithjayasingheznszn/inventoryapi;
import ramithjayasingheznszn/itineraryapi;

configurable ApiSubscription credentials = ?;

# A service representing a network-accessible API
# bound to port `9090`.
service /search on new http:Listener(9090) {

    resource function get flights(string origin, string destination, string flightDate, int numberOfSeats) returns FlightData[]|error {
        log:printInfo("searching for flights", origin = origin, destination = destination, flightDate = flightDate, seats = numberOfSeats);

        itineraryapi:Client itineraryapiEndpoint = check new ({auth: {clientId: credentials.clientId, clientSecret: credentials.clientSecret}});
        itineraryapi:ItineraryItem[] itineraryItems = check itineraryapiEndpoint->getFlight(origin, destination, flightDate = flightDate);

        if itineraryItems.length() == 0 {
            log:printWarn("unable to find itinerary", origin = origin, destination = destination, flightDate = flightDate);
            return [];
        }

        FlightData[] flightDataList = [];

        inventoryapi:Client inventoryapiEndpoint = check new ({auth: {clientId: credentials.clientId, clientSecret: credentials.clientSecret}});

        faresapi:Client faresapiEndpoint = check new ({auth: {clientId: credentials.clientId, clientSecret: credentials.clientSecret}});
        foreach itineraryapi:ItineraryItem i in itineraryItems {
            inventoryapi:Inventory[] inventoryInfo = check inventoryapiEndpoint->getInventoryFlightnumber(i.flightNumber, i.flightDate);
            if inventoryInfo.length() == 0 {
                return error("unable to find inventory data", flightNumber = i.flightNumber, flightDate = i.flightDate);
            }

            if inventoryInfo[0].available < numberOfSeats {
                log:printWarn("unable to find required number of seats", flightNumber = i.flightNumber, flightDate = i.flightDate, requestedSeats = numberOfSeats, availableSeats = inventoryInfo[0].available);
                continue;
            }

            faresapi:Fare totalFare = check faresapiEndpoint->getCalculate(i.flightNumber, i.flightDate, numberOfSeats);

            FlightData data = {
                arrivalTime: i.arrivalTime,
                totalFare: totalFare.price,
                flightDate: i.flightDate,
                origin: i.origin,
                checkInTime: i.checkInTime,
                destination: i.destination,
                nummberOfSeats: numberOfSeats,
                arrivalDate: i.arrivalDate
            };
            flightDataList.push(data);
        }

        return flightDataList;
    }
}

type ApiSubscription record {
    string clientId;
    string clientSecret;
};

type FlightData record {
    string origin;
    string destination;
    string flightDate;
    string checkInTime;
    int nummberOfSeats;
    string arrivalDate;
    string arrivalTime;
    float totalFare;
};
