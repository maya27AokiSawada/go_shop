"use strict";
// Copyright (c) 2026 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdvancedCommercePeriodValidator = exports.AdvancedCommercePeriod = void 0;
const Validator_1 = require("./Validator");
/**
 * The duration of a single cycle of an auto-renewable subscription.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/period period}
 */
var AdvancedCommercePeriod;
(function (AdvancedCommercePeriod) {
    AdvancedCommercePeriod["P1W"] = "P1W";
    AdvancedCommercePeriod["P1M"] = "P1M";
    AdvancedCommercePeriod["P2M"] = "P2M";
    AdvancedCommercePeriod["P3M"] = "P3M";
    AdvancedCommercePeriod["P6M"] = "P6M";
    AdvancedCommercePeriod["P1Y"] = "P1Y";
})(AdvancedCommercePeriod || (exports.AdvancedCommercePeriod = AdvancedCommercePeriod = {}));
class AdvancedCommercePeriodValidator extends Validator_1.StringValidator {
}
exports.AdvancedCommercePeriodValidator = AdvancedCommercePeriodValidator;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiQWR2YW5jZWRDb21tZXJjZVBlcmlvZC5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uL21vZGVscy9BZHZhbmNlZENvbW1lcmNlUGVyaW9kLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiI7QUFBQSw0REFBNEQ7OztBQUU1RCwyQ0FBNkM7QUFFN0M7Ozs7R0FJRztBQUNILElBQVksc0JBT1g7QUFQRCxXQUFZLHNCQUFzQjtJQUM5QixxQ0FBVyxDQUFBO0lBQ1gscUNBQVcsQ0FBQTtJQUNYLHFDQUFXLENBQUE7SUFDWCxxQ0FBVyxDQUFBO0lBQ1gscUNBQVcsQ0FBQTtJQUNYLHFDQUFXLENBQUE7QUFDZixDQUFDLEVBUFcsc0JBQXNCLHNDQUF0QixzQkFBc0IsUUFPakM7QUFFRCxNQUFhLCtCQUFnQyxTQUFRLDJCQUFlO0NBQUc7QUFBdkUsMEVBQXVFIiwic291cmNlc0NvbnRlbnQiOlsiLy8gQ29weXJpZ2h0IChjKSAyMDI2IEFwcGxlIEluYy4gTGljZW5zZWQgdW5kZXIgTUlUIExpY2Vuc2UuXG5cbmltcG9ydCB7IFN0cmluZ1ZhbGlkYXRvciB9IGZyb20gXCIuL1ZhbGlkYXRvclwiXG5cbi8qKlxuICogVGhlIGR1cmF0aW9uIG9mIGEgc2luZ2xlIGN5Y2xlIG9mIGFuIGF1dG8tcmVuZXdhYmxlIHN1YnNjcmlwdGlvbi5cbiAqXG4gKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYWR2YW5jZWRjb21tZXJjZWFwaS9wZXJpb2QgcGVyaW9kfVxuICovXG5leHBvcnQgZW51bSBBZHZhbmNlZENvbW1lcmNlUGVyaW9kIHtcbiAgICBQMVcgPSBcIlAxV1wiLFxuICAgIFAxTSA9IFwiUDFNXCIsXG4gICAgUDJNID0gXCJQMk1cIixcbiAgICBQM00gPSBcIlAzTVwiLFxuICAgIFA2TSA9IFwiUDZNXCIsXG4gICAgUDFZID0gXCJQMVlcIlxufVxuXG5leHBvcnQgY2xhc3MgQWR2YW5jZWRDb21tZXJjZVBlcmlvZFZhbGlkYXRvciBleHRlbmRzIFN0cmluZ1ZhbGlkYXRvciB7fSJdfQ==