"use strict";
// Copyright (c) 2023 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.ConsumptionStatusValidator = exports.ConsumptionStatus = void 0;
const Validator_1 = require("./Validator");
/**
 * A value that indicates the extent to which the customer consumed the in-app purchase.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/consumptionstatus consumptionStatus}
 */
var ConsumptionStatus;
(function (ConsumptionStatus) {
    ConsumptionStatus[ConsumptionStatus["UNDECLARED"] = 0] = "UNDECLARED";
    ConsumptionStatus[ConsumptionStatus["NOT_CONSUMED"] = 1] = "NOT_CONSUMED";
    ConsumptionStatus[ConsumptionStatus["PARTIALLY_CONSUMED"] = 2] = "PARTIALLY_CONSUMED";
    ConsumptionStatus[ConsumptionStatus["FULLY_CONSUMED"] = 3] = "FULLY_CONSUMED";
})(ConsumptionStatus || (exports.ConsumptionStatus = ConsumptionStatus = {}));
class ConsumptionStatusValidator extends Validator_1.NumberValidator {
}
exports.ConsumptionStatusValidator = ConsumptionStatusValidator;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiQ29uc3VtcHRpb25TdGF0dXMuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi9tb2RlbHMvQ29uc3VtcHRpb25TdGF0dXMudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IjtBQUFBLDREQUE0RDs7O0FBRTVELDJDQUE4QztBQUU5Qzs7OztHQUlHO0FBQ0gsSUFBWSxpQkFLWDtBQUxELFdBQVksaUJBQWlCO0lBQ3pCLHFFQUFjLENBQUE7SUFDZCx5RUFBZ0IsQ0FBQTtJQUNoQixxRkFBc0IsQ0FBQTtJQUN0Qiw2RUFBa0IsQ0FBQTtBQUN0QixDQUFDLEVBTFcsaUJBQWlCLGlDQUFqQixpQkFBaUIsUUFLNUI7QUFFRCxNQUFhLDBCQUEyQixTQUFRLDJCQUFlO0NBQUc7QUFBbEUsZ0VBQWtFIiwic291cmNlc0NvbnRlbnQiOlsiLy8gQ29weXJpZ2h0IChjKSAyMDIzIEFwcGxlIEluYy4gTGljZW5zZWQgdW5kZXIgTUlUIExpY2Vuc2UuXG5cbmltcG9ydCB7IE51bWJlclZhbGlkYXRvciB9IGZyb20gXCIuL1ZhbGlkYXRvclwiO1xuXG4vKipcbiAqIEEgdmFsdWUgdGhhdCBpbmRpY2F0ZXMgdGhlIGV4dGVudCB0byB3aGljaCB0aGUgY3VzdG9tZXIgY29uc3VtZWQgdGhlIGluLWFwcCBwdXJjaGFzZS5cbiAqXG4gKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvY29uc3VtcHRpb25zdGF0dXMgY29uc3VtcHRpb25TdGF0dXN9XG4gKi9cbmV4cG9ydCBlbnVtIENvbnN1bXB0aW9uU3RhdHVzIHtcbiAgICBVTkRFQ0xBUkVEID0gMCxcbiAgICBOT1RfQ09OU1VNRUQgPSAxLFxuICAgIFBBUlRJQUxMWV9DT05TVU1FRCA9IDIsXG4gICAgRlVMTFlfQ09OU1VNRUQgPSAzLFxufVxuXG5leHBvcnQgY2xhc3MgQ29uc3VtcHRpb25TdGF0dXNWYWxpZGF0b3IgZXh0ZW5kcyBOdW1iZXJWYWxpZGF0b3Ige30iXX0=