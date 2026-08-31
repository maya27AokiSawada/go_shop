"use strict";
// Copyright (c) 2024 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.RefundPreferenceV1 = void 0;
/**
 * A value that indicates your preferred outcome for the refund request.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/refundpreferencev1 RefundPreferenceV1}
 * @deprecated Use {@link RefundPreference} instead.
 */
var RefundPreferenceV1;
(function (RefundPreferenceV1) {
    RefundPreferenceV1[RefundPreferenceV1["UNDECLARED"] = 0] = "UNDECLARED";
    RefundPreferenceV1[RefundPreferenceV1["PREFER_GRANT"] = 1] = "PREFER_GRANT";
    RefundPreferenceV1[RefundPreferenceV1["PREFER_DECLINE"] = 2] = "PREFER_DECLINE";
    RefundPreferenceV1[RefundPreferenceV1["NO_PREFERENCE"] = 3] = "NO_PREFERENCE";
})(RefundPreferenceV1 || (exports.RefundPreferenceV1 = RefundPreferenceV1 = {}));
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiUmVmdW5kUHJlZmVyZW5jZVYxLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vbW9kZWxzL1JlZnVuZFByZWZlcmVuY2VWMS50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiO0FBQUEsNERBQTREOzs7QUFJNUQ7Ozs7O0dBS0c7QUFDSCxJQUFZLGtCQUtYO0FBTEQsV0FBWSxrQkFBa0I7SUFDMUIsdUVBQWMsQ0FBQTtJQUNkLDJFQUFnQixDQUFBO0lBQ2hCLCtFQUFrQixDQUFBO0lBQ2xCLDZFQUFpQixDQUFBO0FBQ3JCLENBQUMsRUFMVyxrQkFBa0Isa0NBQWxCLGtCQUFrQixRQUs3QiIsInNvdXJjZXNDb250ZW50IjpbIi8vIENvcHlyaWdodCAoYykgMjAyNCBBcHBsZSBJbmMuIExpY2Vuc2VkIHVuZGVyIE1JVCBMaWNlbnNlLlxuXG5pbXBvcnQgeyBOdW1iZXJWYWxpZGF0b3IgfSBmcm9tIFwiLi9WYWxpZGF0b3JcIjtcblxuLyoqXG4gKiBBIHZhbHVlIHRoYXQgaW5kaWNhdGVzIHlvdXIgcHJlZmVycmVkIG91dGNvbWUgZm9yIHRoZSByZWZ1bmQgcmVxdWVzdC5cbiAqXG4gKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvcmVmdW5kcHJlZmVyZW5jZXYxIFJlZnVuZFByZWZlcmVuY2VWMX1cbiAqIEBkZXByZWNhdGVkIFVzZSB7QGxpbmsgUmVmdW5kUHJlZmVyZW5jZX0gaW5zdGVhZC5cbiAqL1xuZXhwb3J0IGVudW0gUmVmdW5kUHJlZmVyZW5jZVYxIHtcbiAgICBVTkRFQ0xBUkVEID0gMCxcbiAgICBQUkVGRVJfR1JBTlQgPSAxLFxuICAgIFBSRUZFUl9ERUNMSU5FID0gMixcbiAgICBOT19QUkVGRVJFTkNFID0gMyxcbn1cbiJdfQ==