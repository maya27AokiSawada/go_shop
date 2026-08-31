"use strict";
// Copyright (c) 2023 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.StatusValidator = exports.Status = void 0;
const Validator_1 = require("./Validator");
/**
 * The status of an auto-renewable subscription.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/status status}
 */
var Status;
(function (Status) {
    Status[Status["ACTIVE"] = 1] = "ACTIVE";
    Status[Status["EXPIRED"] = 2] = "EXPIRED";
    Status[Status["BILLING_RETRY"] = 3] = "BILLING_RETRY";
    Status[Status["BILLING_GRACE_PERIOD"] = 4] = "BILLING_GRACE_PERIOD";
    Status[Status["REVOKED"] = 5] = "REVOKED";
})(Status || (exports.Status = Status = {}));
class StatusValidator extends Validator_1.NumberValidator {
}
exports.StatusValidator = StatusValidator;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiU3RhdHVzLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vbW9kZWxzL1N0YXR1cy50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiO0FBQUEsNERBQTREOzs7QUFFNUQsMkNBQThDO0FBRTlDOzs7O0dBSUc7QUFDSCxJQUFZLE1BTVg7QUFORCxXQUFZLE1BQU07SUFDZCx1Q0FBVSxDQUFBO0lBQ1YseUNBQVcsQ0FBQTtJQUNYLHFEQUFpQixDQUFBO0lBQ2pCLG1FQUF3QixDQUFBO0lBQ3hCLHlDQUFXLENBQUE7QUFDZixDQUFDLEVBTlcsTUFBTSxzQkFBTixNQUFNLFFBTWpCO0FBRUQsTUFBYSxlQUFnQixTQUFRLDJCQUFlO0NBQUc7QUFBdkQsMENBQXVEIiwic291cmNlc0NvbnRlbnQiOlsiLy8gQ29weXJpZ2h0IChjKSAyMDIzIEFwcGxlIEluYy4gTGljZW5zZWQgdW5kZXIgTUlUIExpY2Vuc2UuXG5cbmltcG9ydCB7IE51bWJlclZhbGlkYXRvciB9IGZyb20gXCIuL1ZhbGlkYXRvclwiO1xuXG4vKipcbiAqIFRoZSBzdGF0dXMgb2YgYW4gYXV0by1yZW5ld2FibGUgc3Vic2NyaXB0aW9uLlxuICpcbiAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9zdGF0dXMgc3RhdHVzfVxuICovXG5leHBvcnQgZW51bSBTdGF0dXMge1xuICAgIEFDVElWRSA9IDEsXG4gICAgRVhQSVJFRCA9IDIsXG4gICAgQklMTElOR19SRVRSWSA9IDMsXG4gICAgQklMTElOR19HUkFDRV9QRVJJT0QgPSA0LFxuICAgIFJFVk9LRUQgPSA1LFxufVxuXG5leHBvcnQgY2xhc3MgU3RhdHVzVmFsaWRhdG9yIGV4dGVuZHMgTnVtYmVyVmFsaWRhdG9yIHt9Il19