"use strict";
// Copyright (c) 2023 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.EnvironmentValidator = exports.Environment = void 0;
const Validator_1 = require("./Validator");
/**
 * The server environment, either sandbox or production.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/environment environment}
 */
var Environment;
(function (Environment) {
    Environment["SANDBOX"] = "Sandbox";
    Environment["PRODUCTION"] = "Production";
    Environment["XCODE"] = "Xcode";
    Environment["LOCAL_TESTING"] = "LocalTesting";
})(Environment || (exports.Environment = Environment = {}));
class EnvironmentValidator extends Validator_1.StringValidator {
}
exports.EnvironmentValidator = EnvironmentValidator;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiRW52aXJvbm1lbnQuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi9tb2RlbHMvRW52aXJvbm1lbnQudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IjtBQUFBLDREQUE0RDs7O0FBRTVELDJDQUE4QztBQUU5Qzs7OztHQUlHO0FBQ0gsSUFBWSxXQUtYO0FBTEQsV0FBWSxXQUFXO0lBQ25CLGtDQUFtQixDQUFBO0lBQ25CLHdDQUF5QixDQUFBO0lBQ3pCLDhCQUFlLENBQUE7SUFDZiw2Q0FBOEIsQ0FBQTtBQUNsQyxDQUFDLEVBTFcsV0FBVywyQkFBWCxXQUFXLFFBS3RCO0FBRUQsTUFBYSxvQkFBcUIsU0FBUSwyQkFBZTtDQUFHO0FBQTVELG9EQUE0RCIsInNvdXJjZXNDb250ZW50IjpbIi8vIENvcHlyaWdodCAoYykgMjAyMyBBcHBsZSBJbmMuIExpY2Vuc2VkIHVuZGVyIE1JVCBMaWNlbnNlLlxuXG5pbXBvcnQgeyBTdHJpbmdWYWxpZGF0b3IgfSBmcm9tIFwiLi9WYWxpZGF0b3JcIjtcblxuLyoqXG4gKiBUaGUgc2VydmVyIGVudmlyb25tZW50LCBlaXRoZXIgc2FuZGJveCBvciBwcm9kdWN0aW9uLlxuICpcbiAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9lbnZpcm9ubWVudCBlbnZpcm9ubWVudH1cbiAqL1xuZXhwb3J0IGVudW0gRW52aXJvbm1lbnQge1xuICAgIFNBTkRCT1ggPSBcIlNhbmRib3hcIixcbiAgICBQUk9EVUNUSU9OID0gXCJQcm9kdWN0aW9uXCIsXG4gICAgWENPREUgPSBcIlhjb2RlXCIsXG4gICAgTE9DQUxfVEVTVElORyA9IFwiTG9jYWxUZXN0aW5nXCIsIC8vIFVzZWQgZm9yIHVuaXQgdGVzdGluZ1xufVxuXG5leHBvcnQgY2xhc3MgRW52aXJvbm1lbnRWYWxpZGF0b3IgZXh0ZW5kcyBTdHJpbmdWYWxpZGF0b3Ige30iXX0=