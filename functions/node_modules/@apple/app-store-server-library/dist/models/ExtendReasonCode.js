"use strict";
// Copyright (c) 2023 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.ExtendReasonCodeValidator = exports.ExtendReasonCode = void 0;
const Validator_1 = require("./Validator");
/**
 * The code that represents the reason for the subscription-renewal-date extension.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/extendreasoncode extendReasonCode}
 */
var ExtendReasonCode;
(function (ExtendReasonCode) {
    ExtendReasonCode[ExtendReasonCode["UNDECLARED"] = 0] = "UNDECLARED";
    ExtendReasonCode[ExtendReasonCode["CUSTOMER_SATISFACTION"] = 1] = "CUSTOMER_SATISFACTION";
    ExtendReasonCode[ExtendReasonCode["OTHER"] = 2] = "OTHER";
    ExtendReasonCode[ExtendReasonCode["SERVICE_ISSUE_OR_OUTAGE"] = 3] = "SERVICE_ISSUE_OR_OUTAGE";
})(ExtendReasonCode || (exports.ExtendReasonCode = ExtendReasonCode = {}));
class ExtendReasonCodeValidator extends Validator_1.NumberValidator {
}
exports.ExtendReasonCodeValidator = ExtendReasonCodeValidator;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiRXh0ZW5kUmVhc29uQ29kZS5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uL21vZGVscy9FeHRlbmRSZWFzb25Db2RlLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiI7QUFBQSw0REFBNEQ7OztBQUU1RCwyQ0FBOEM7QUFFOUM7Ozs7R0FJRztBQUNILElBQVksZ0JBS1g7QUFMRCxXQUFZLGdCQUFnQjtJQUN4QixtRUFBYyxDQUFBO0lBQ2QseUZBQXlCLENBQUE7SUFDekIseURBQVMsQ0FBQTtJQUNULDZGQUEyQixDQUFBO0FBQy9CLENBQUMsRUFMVyxnQkFBZ0IsZ0NBQWhCLGdCQUFnQixRQUszQjtBQUVELE1BQWEseUJBQTBCLFNBQVEsMkJBQWU7Q0FBRztBQUFqRSw4REFBaUUiLCJzb3VyY2VzQ29udGVudCI6WyIvLyBDb3B5cmlnaHQgKGMpIDIwMjMgQXBwbGUgSW5jLiBMaWNlbnNlZCB1bmRlciBNSVQgTGljZW5zZS5cblxuaW1wb3J0IHsgTnVtYmVyVmFsaWRhdG9yIH0gZnJvbSBcIi4vVmFsaWRhdG9yXCI7XG5cbi8qKlxuICogVGhlIGNvZGUgdGhhdCByZXByZXNlbnRzIHRoZSByZWFzb24gZm9yIHRoZSBzdWJzY3JpcHRpb24tcmVuZXdhbC1kYXRlIGV4dGVuc2lvbi5cbiAqXG4gKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvZXh0ZW5kcmVhc29uY29kZSBleHRlbmRSZWFzb25Db2RlfVxuICovXG5leHBvcnQgZW51bSBFeHRlbmRSZWFzb25Db2RlIHtcbiAgICBVTkRFQ0xBUkVEID0gMCxcbiAgICBDVVNUT01FUl9TQVRJU0ZBQ1RJT04gPSAxLFxuICAgIE9USEVSID0gMixcbiAgICBTRVJWSUNFX0lTU1VFX09SX09VVEFHRSA9IDMsXG59XG5cbmV4cG9ydCBjbGFzcyBFeHRlbmRSZWFzb25Db2RlVmFsaWRhdG9yIGV4dGVuZHMgTnVtYmVyVmFsaWRhdG9yIHt9Il19