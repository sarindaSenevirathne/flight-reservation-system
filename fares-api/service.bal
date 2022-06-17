import ballerina/log;
import ramithjayasingheznszn/inventoryapi;
import ballerina/http;

configurable ApiCredentials inventoryApi = ?;

# A service representing a network-accessible API
# bound to port `9090`.
service /fare on new http:Listener(9090) {

    resource function get calculate(string flightNumber, string flightDate, int numberOfSeats) returns Fare|error? {
        log:printInfo(string `request for a fare - flight number: ${flightNumber}, flight date: ${flightDate}, seats: ${numberOfSeats}`);
        inventoryapi:Client inventoryapiEndpoint = check new ({auth: {clientId: inventoryApi.clientId, clientSecret: inventoryApi.clientSecret}});
        inventoryapi:Inventory[] matchedInventoryItems = check inventoryapiEndpoint->getInventoryFlightnumber(flightNumber, flightDate = flightDate);

        if matchedInventoryItems.length() == 0 {
            return error(string `unable to find a jounery, flight number: ${flightNumber}, flight date: ${flightDate}`);
        }

        BaseFare? baseFare = baseFares[flightNumber, flightDate];
        if baseFare is () {
            return error(string `unable to find a base fare, flight number: ${flightNumber}, flight date: ${flightDate}`);
        }

        inventoryapi:Inventory inventory = matchedInventoryItems[0];

        decimal totalPrice = calculateFare(inventory.totalCapacity, inventory.available, baseFare.baseFare, numberOfSeats);
        log:printInfo(string `price calculation: fight number: ${flightNumber}, flight date: ${flightDate}, number of seats: ${numberOfSeats}, total price: ${totalPrice}`);
        return {
            flightNumber: flightNumber,
            flightDate: flightDate,
            price: totalPrice
        };
    }
}

function calculateFare(int totalCapacity, int available, decimal baseFare, int numberOfSeats) returns decimal {
    log:printInfo(string `calculating price - total capacity: ${totalCapacity}, available seats: ${available}, base fare: ${baseFare}, number of seats: ${numberOfSeats}`);
    decimal priceIncrementPerSeat = baseFare * (<decimal>(totalCapacity - available) / <decimal>totalCapacity);
    return (baseFare + priceIncrementPerSeat) * <decimal>numberOfSeats;
}

table<BaseFare> key(flightNumber, flightDate) baseFares = table [
        {
            flightNumber: "FL1",
            flightDate: "2022/02/10",
            baseFare: 3000
        },
        {
            flightNumber: "FL2",
            flightDate: "2022/02/10",
            baseFare: 4000
        },
        {
            flightNumber: "FL3",
            flightDate: "2022/02/10",
            baseFare: 2500
        },
        {
            flightNumber: "FL4",
            flightDate: "2022/02/10",
            baseFare: 4300
        }
    ];

type Fare record {
    string flightNumber;
    string flightDate;
    decimal price;
};

type BaseFare record {
    readonly string flightNumber;
    readonly string flightDate;
    decimal baseFare;
};

type ApiCredentials record {
    string clientId;
    string clientSecret;
};
