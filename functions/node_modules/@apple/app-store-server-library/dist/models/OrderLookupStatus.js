"use strict";
// Copyright (c) 2023 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrderLookupStatusValidator = exports.OrderLookupStatus = void 0;
const Validator_1 = require("./Validator");
/**
 * A value that indicates whether the order ID in the request is valid for your app.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/orderlookupstatus OrderLookupStatus}
 */
var OrderLookupStatus;
(function (OrderLookupStatus) {
    OrderLookupStatus[OrderLookupStatus["VALID"] = 0] = "VALID";
    OrderLookupStatus[OrderLookupStatus["INVALID"] = 1] = "INVALID";
})(OrderLookupStatus || (exports.OrderLookupStatus = OrderLookupStatus = {}));
class OrderLookupStatusValidator extends Validator_1.NumberValidator {
}
exports.OrderLookupStatusValidator = OrderLookupStatusValidator;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiT3JkZXJMb29rdXBTdGF0dXMuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi9tb2RlbHMvT3JkZXJMb29rdXBTdGF0dXMudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IjtBQUFBLDREQUE0RDs7O0FBRTVELDJDQUE4QztBQUU5Qzs7OztHQUlHO0FBQ0gsSUFBWSxpQkFHWDtBQUhELFdBQVksaUJBQWlCO0lBQ3pCLDJEQUFTLENBQUE7SUFDVCwrREFBVyxDQUFBO0FBQ2YsQ0FBQyxFQUhXLGlCQUFpQixpQ0FBakIsaUJBQWlCLFFBRzVCO0FBRUQsTUFBYSwwQkFBMkIsU0FBUSwyQkFBZTtDQUFHO0FBQWxFLGdFQUFrRSIsInNvdXJjZXNDb250ZW50IjpbIi8vIENvcHlyaWdodCAoYykgMjAyMyBBcHBsZSBJbmMuIExpY2Vuc2VkIHVuZGVyIE1JVCBMaWNlbnNlLlxuXG5pbXBvcnQgeyBOdW1iZXJWYWxpZGF0b3IgfSBmcm9tIFwiLi9WYWxpZGF0b3JcIjtcblxuLyoqXG4gKiBBIHZhbHVlIHRoYXQgaW5kaWNhdGVzIHdoZXRoZXIgdGhlIG9yZGVyIElEIGluIHRoZSByZXF1ZXN0IGlzIHZhbGlkIGZvciB5b3VyIGFwcC5cbiAqXG4gKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvb3JkZXJsb29rdXBzdGF0dXMgT3JkZXJMb29rdXBTdGF0dXN9XG4gKi9cbmV4cG9ydCBlbnVtIE9yZGVyTG9va3VwU3RhdHVzIHtcbiAgICBWQUxJRCA9IDAsXG4gICAgSU5WQUxJRCA9IDEsXG59XG5cbmV4cG9ydCBjbGFzcyBPcmRlckxvb2t1cFN0YXR1c1ZhbGlkYXRvciBleHRlbmRzIE51bWJlclZhbGlkYXRvciB7fSJdfQ==