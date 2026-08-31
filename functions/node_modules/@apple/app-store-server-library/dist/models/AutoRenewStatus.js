"use strict";
// Copyright (c) 2023 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.AutoRenewStatusValidator = exports.AutoRenewStatus = void 0;
const Validator_1 = require("./Validator");
/**
 * The renewal status for an auto-renewable subscription.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/autorenewstatus autoRenewStatus}
 */
var AutoRenewStatus;
(function (AutoRenewStatus) {
    AutoRenewStatus[AutoRenewStatus["OFF"] = 0] = "OFF";
    AutoRenewStatus[AutoRenewStatus["ON"] = 1] = "ON";
})(AutoRenewStatus || (exports.AutoRenewStatus = AutoRenewStatus = {}));
class AutoRenewStatusValidator extends Validator_1.NumberValidator {
}
exports.AutoRenewStatusValidator = AutoRenewStatusValidator;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiQXV0b1JlbmV3U3RhdHVzLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vbW9kZWxzL0F1dG9SZW5ld1N0YXR1cy50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiO0FBQUEsNERBQTREOzs7QUFFNUQsMkNBQThDO0FBRTlDOzs7O0dBSUc7QUFDSCxJQUFZLGVBR1g7QUFIRCxXQUFZLGVBQWU7SUFDdkIsbURBQU8sQ0FBQTtJQUNQLGlEQUFNLENBQUE7QUFDVixDQUFDLEVBSFcsZUFBZSwrQkFBZixlQUFlLFFBRzFCO0FBRUQsTUFBYSx3QkFBeUIsU0FBUSwyQkFBZTtDQUFHO0FBQWhFLDREQUFnRSIsInNvdXJjZXNDb250ZW50IjpbIi8vIENvcHlyaWdodCAoYykgMjAyMyBBcHBsZSBJbmMuIExpY2Vuc2VkIHVuZGVyIE1JVCBMaWNlbnNlLlxuXG5pbXBvcnQgeyBOdW1iZXJWYWxpZGF0b3IgfSBmcm9tIFwiLi9WYWxpZGF0b3JcIjtcblxuLyoqXG4gKiBUaGUgcmVuZXdhbCBzdGF0dXMgZm9yIGFuIGF1dG8tcmVuZXdhYmxlIHN1YnNjcmlwdGlvbi5cbiAqXG4gKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvYXV0b3JlbmV3c3RhdHVzIGF1dG9SZW5ld1N0YXR1c31cbiAqL1xuZXhwb3J0IGVudW0gQXV0b1JlbmV3U3RhdHVzIHtcbiAgICBPRkYgPSAwLFxuICAgIE9OID0gMSxcbn1cblxuZXhwb3J0IGNsYXNzIEF1dG9SZW5ld1N0YXR1c1ZhbGlkYXRvciBleHRlbmRzIE51bWJlclZhbGlkYXRvciB7fSJdfQ==