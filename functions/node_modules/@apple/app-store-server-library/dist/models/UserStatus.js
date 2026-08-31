"use strict";
// Copyright (c) 2023 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.UserStatusValidator = exports.UserStatus = void 0;
const Validator_1 = require("./Validator");
/**
 * The status of a customer’s account within your app.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/userstatus userStatus}
 */
var UserStatus;
(function (UserStatus) {
    UserStatus[UserStatus["UNDECLARED"] = 0] = "UNDECLARED";
    UserStatus[UserStatus["ACTIVE"] = 1] = "ACTIVE";
    UserStatus[UserStatus["SUSPENDED"] = 2] = "SUSPENDED";
    UserStatus[UserStatus["TERMINATED"] = 3] = "TERMINATED";
    UserStatus[UserStatus["LIMITED_ACCESS"] = 4] = "LIMITED_ACCESS";
})(UserStatus || (exports.UserStatus = UserStatus = {}));
class UserStatusValidator extends Validator_1.NumberValidator {
}
exports.UserStatusValidator = UserStatusValidator;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiVXNlclN0YXR1cy5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uL21vZGVscy9Vc2VyU3RhdHVzLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiI7QUFBQSw0REFBNEQ7OztBQUU1RCwyQ0FBOEM7QUFFOUM7Ozs7R0FJRztBQUNILElBQVksVUFNWDtBQU5ELFdBQVksVUFBVTtJQUNsQix1REFBYyxDQUFBO0lBQ2QsK0NBQVUsQ0FBQTtJQUNWLHFEQUFhLENBQUE7SUFDYix1REFBYyxDQUFBO0lBQ2QsK0RBQWtCLENBQUE7QUFDdEIsQ0FBQyxFQU5XLFVBQVUsMEJBQVYsVUFBVSxRQU1yQjtBQUVELE1BQWEsbUJBQW9CLFNBQVEsMkJBQWU7Q0FBRztBQUEzRCxrREFBMkQiLCJzb3VyY2VzQ29udGVudCI6WyIvLyBDb3B5cmlnaHQgKGMpIDIwMjMgQXBwbGUgSW5jLiBMaWNlbnNlZCB1bmRlciBNSVQgTGljZW5zZS5cblxuaW1wb3J0IHsgTnVtYmVyVmFsaWRhdG9yIH0gZnJvbSBcIi4vVmFsaWRhdG9yXCI7XG5cbi8qKlxuICogVGhlIHN0YXR1cyBvZiBhIGN1c3RvbWVy4oCZcyBhY2NvdW50IHdpdGhpbiB5b3VyIGFwcC5cbiAqXG4gKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvdXNlcnN0YXR1cyB1c2VyU3RhdHVzfVxuICovXG5leHBvcnQgZW51bSBVc2VyU3RhdHVzIHtcbiAgICBVTkRFQ0xBUkVEID0gMCxcbiAgICBBQ1RJVkUgPSAxLFxuICAgIFNVU1BFTkRFRCA9IDIsXG4gICAgVEVSTUlOQVRFRCA9IDMsXG4gICAgTElNSVRFRF9BQ0NFU1MgPSA0LFxufVxuXG5leHBvcnQgY2xhc3MgVXNlclN0YXR1c1ZhbGlkYXRvciBleHRlbmRzIE51bWJlclZhbGlkYXRvciB7fVxuIl19