"use strict";
// Copyright (c) 2023 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.PlatformValidator = exports.Platform = void 0;
const Validator_1 = require("./Validator");
/**
 * The platform on which the customer consumed the in-app purchase.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/platform platform}
 */
var Platform;
(function (Platform) {
    Platform[Platform["UNDECLARED"] = 0] = "UNDECLARED";
    Platform[Platform["APPLE"] = 1] = "APPLE";
    Platform[Platform["NON_APPLE"] = 2] = "NON_APPLE";
})(Platform || (exports.Platform = Platform = {}));
class PlatformValidator extends Validator_1.NumberValidator {
}
exports.PlatformValidator = PlatformValidator;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiUGxhdGZvcm0uanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi9tb2RlbHMvUGxhdGZvcm0udHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IjtBQUFBLDREQUE0RDs7O0FBRTVELDJDQUE4QztBQUU5Qzs7OztHQUlHO0FBQ0gsSUFBWSxRQUlYO0FBSkQsV0FBWSxRQUFRO0lBQ2hCLG1EQUFjLENBQUE7SUFDZCx5Q0FBUyxDQUFBO0lBQ1QsaURBQWEsQ0FBQTtBQUNqQixDQUFDLEVBSlcsUUFBUSx3QkFBUixRQUFRLFFBSW5CO0FBRUQsTUFBYSxpQkFBa0IsU0FBUSwyQkFBZTtDQUFHO0FBQXpELDhDQUF5RCIsInNvdXJjZXNDb250ZW50IjpbIi8vIENvcHlyaWdodCAoYykgMjAyMyBBcHBsZSBJbmMuIExpY2Vuc2VkIHVuZGVyIE1JVCBMaWNlbnNlLlxuXG5pbXBvcnQgeyBOdW1iZXJWYWxpZGF0b3IgfSBmcm9tIFwiLi9WYWxpZGF0b3JcIjtcblxuLyoqXG4gKiBUaGUgcGxhdGZvcm0gb24gd2hpY2ggdGhlIGN1c3RvbWVyIGNvbnN1bWVkIHRoZSBpbi1hcHAgcHVyY2hhc2UuXG4gKlxuICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL3BsYXRmb3JtIHBsYXRmb3JtfVxuICovXG5leHBvcnQgZW51bSBQbGF0Zm9ybSB7XG4gICAgVU5ERUNMQVJFRCA9IDAsXG4gICAgQVBQTEUgPSAxLFxuICAgIE5PTl9BUFBMRSA9IDIsXG59XG5cbmV4cG9ydCBjbGFzcyBQbGF0Zm9ybVZhbGlkYXRvciBleHRlbmRzIE51bWJlclZhbGlkYXRvciB7fSJdfQ==