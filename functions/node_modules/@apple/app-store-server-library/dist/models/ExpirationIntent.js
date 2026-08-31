"use strict";
// Copyright (c) 2023 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.ExpirationIntentValidator = exports.ExpirationIntent = void 0;
const Validator_1 = require("./Validator");
/**
 * The reason an auto-renewable subscription expired.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/expirationintent expirationIntent}
 */
var ExpirationIntent;
(function (ExpirationIntent) {
    ExpirationIntent[ExpirationIntent["CUSTOMER_CANCELLED"] = 1] = "CUSTOMER_CANCELLED";
    ExpirationIntent[ExpirationIntent["BILLING_ERROR"] = 2] = "BILLING_ERROR";
    ExpirationIntent[ExpirationIntent["CUSTOMER_DID_NOT_CONSENT_TO_PRICE_INCREASE"] = 3] = "CUSTOMER_DID_NOT_CONSENT_TO_PRICE_INCREASE";
    ExpirationIntent[ExpirationIntent["PRODUCT_NOT_AVAILABLE"] = 4] = "PRODUCT_NOT_AVAILABLE";
    ExpirationIntent[ExpirationIntent["OTHER"] = 5] = "OTHER";
})(ExpirationIntent || (exports.ExpirationIntent = ExpirationIntent = {}));
class ExpirationIntentValidator extends Validator_1.NumberValidator {
}
exports.ExpirationIntentValidator = ExpirationIntentValidator;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiRXhwaXJhdGlvbkludGVudC5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uL21vZGVscy9FeHBpcmF0aW9uSW50ZW50LnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiI7QUFBQSw0REFBNEQ7OztBQUU1RCwyQ0FBOEM7QUFFOUM7Ozs7R0FJRztBQUNILElBQVksZ0JBTVg7QUFORCxXQUFZLGdCQUFnQjtJQUN4QixtRkFBc0IsQ0FBQTtJQUN0Qix5RUFBaUIsQ0FBQTtJQUNqQixtSUFBOEMsQ0FBQTtJQUM5Qyx5RkFBeUIsQ0FBQTtJQUN6Qix5REFBUyxDQUFBO0FBQ2IsQ0FBQyxFQU5XLGdCQUFnQixnQ0FBaEIsZ0JBQWdCLFFBTTNCO0FBRUQsTUFBYSx5QkFBMEIsU0FBUSwyQkFBZTtDQUFHO0FBQWpFLDhEQUFpRSIsInNvdXJjZXNDb250ZW50IjpbIi8vIENvcHlyaWdodCAoYykgMjAyMyBBcHBsZSBJbmMuIExpY2Vuc2VkIHVuZGVyIE1JVCBMaWNlbnNlLlxuXG5pbXBvcnQgeyBOdW1iZXJWYWxpZGF0b3IgfSBmcm9tIFwiLi9WYWxpZGF0b3JcIjtcblxuLyoqXG4gKiBUaGUgcmVhc29uIGFuIGF1dG8tcmVuZXdhYmxlIHN1YnNjcmlwdGlvbiBleHBpcmVkLlxuICpcbiAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9leHBpcmF0aW9uaW50ZW50IGV4cGlyYXRpb25JbnRlbnR9XG4gKi9cbmV4cG9ydCBlbnVtIEV4cGlyYXRpb25JbnRlbnQge1xuICAgIENVU1RPTUVSX0NBTkNFTExFRCA9IDEsXG4gICAgQklMTElOR19FUlJPUiA9IDIsXG4gICAgQ1VTVE9NRVJfRElEX05PVF9DT05TRU5UX1RPX1BSSUNFX0lOQ1JFQVNFID0gMyxcbiAgICBQUk9EVUNUX05PVF9BVkFJTEFCTEUgPSA0LFxuICAgIE9USEVSID0gNSxcbn1cblxuZXhwb3J0IGNsYXNzIEV4cGlyYXRpb25JbnRlbnRWYWxpZGF0b3IgZXh0ZW5kcyBOdW1iZXJWYWxpZGF0b3Ige30iXX0=