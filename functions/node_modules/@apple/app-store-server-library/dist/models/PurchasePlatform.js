"use strict";
// Copyright (c) 2025 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.PurchasePlatformValidator = exports.PurchasePlatform = void 0;
const Validator_1 = require("./Validator");
/**
 * Values that represent Apple platforms.
 *
 * {@link https://developer.apple.com/documentation/storekit/appstore/platform AppStore.Platform}
 */
var PurchasePlatform;
(function (PurchasePlatform) {
    PurchasePlatform["IOS"] = "iOS";
    PurchasePlatform["MAC_OS"] = "macOS";
    PurchasePlatform["TV_OS"] = "tvOS";
    PurchasePlatform["VISION_OS"] = "visionOS";
})(PurchasePlatform || (exports.PurchasePlatform = PurchasePlatform = {}));
class PurchasePlatformValidator extends Validator_1.StringValidator {
}
exports.PurchasePlatformValidator = PurchasePlatformValidator;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiUHVyY2hhc2VQbGF0Zm9ybS5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uL21vZGVscy9QdXJjaGFzZVBsYXRmb3JtLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiI7QUFBQSw0REFBNEQ7OztBQUU1RCwyQ0FBOEM7QUFFOUM7Ozs7R0FJRztBQUNILElBQVksZ0JBS1g7QUFMRCxXQUFZLGdCQUFnQjtJQUN4QiwrQkFBVyxDQUFBO0lBQ1gsb0NBQWdCLENBQUE7SUFDaEIsa0NBQWMsQ0FBQTtJQUNkLDBDQUFzQixDQUFBO0FBQzFCLENBQUMsRUFMVyxnQkFBZ0IsZ0NBQWhCLGdCQUFnQixRQUszQjtBQUVELE1BQWEseUJBQTBCLFNBQVEsMkJBQWU7Q0FBRztBQUFqRSw4REFBaUUiLCJzb3VyY2VzQ29udGVudCI6WyIvLyBDb3B5cmlnaHQgKGMpIDIwMjUgQXBwbGUgSW5jLiBMaWNlbnNlZCB1bmRlciBNSVQgTGljZW5zZS5cblxuaW1wb3J0IHsgU3RyaW5nVmFsaWRhdG9yIH0gZnJvbSBcIi4vVmFsaWRhdG9yXCI7XG5cbi8qKlxuICogVmFsdWVzIHRoYXQgcmVwcmVzZW50IEFwcGxlIHBsYXRmb3Jtcy5cbiAqXG4gKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vc3RvcmVraXQvYXBwc3RvcmUvcGxhdGZvcm0gQXBwU3RvcmUuUGxhdGZvcm19XG4gKi9cbmV4cG9ydCBlbnVtIFB1cmNoYXNlUGxhdGZvcm0ge1xuICAgIElPUyA9IFwiaU9TXCIsXG4gICAgTUFDX09TID0gXCJtYWNPU1wiLFxuICAgIFRWX09TID0gXCJ0dk9TXCIsXG4gICAgVklTSU9OX09TID0gXCJ2aXNpb25PU1wiXG59XG5cbmV4cG9ydCBjbGFzcyBQdXJjaGFzZVBsYXRmb3JtVmFsaWRhdG9yIGV4dGVuZHMgU3RyaW5nVmFsaWRhdG9yIHt9Il19