"use strict";
// Copyright (c) 2026 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdvancedCommerceOfferPeriodValidator = exports.AdvancedCommerceOfferPeriod = void 0;
const Validator_1 = require("./Validator");
/**
 * The period of the offer.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/offer Offer}
 */
var AdvancedCommerceOfferPeriod;
(function (AdvancedCommerceOfferPeriod) {
    AdvancedCommerceOfferPeriod["P3D"] = "P3D";
    AdvancedCommerceOfferPeriod["P1W"] = "P1W";
    AdvancedCommerceOfferPeriod["P2W"] = "P2W";
    AdvancedCommerceOfferPeriod["P1M"] = "P1M";
    AdvancedCommerceOfferPeriod["P2M"] = "P2M";
    AdvancedCommerceOfferPeriod["P3M"] = "P3M";
    AdvancedCommerceOfferPeriod["P6M"] = "P6M";
    AdvancedCommerceOfferPeriod["P9M"] = "P9M";
    AdvancedCommerceOfferPeriod["P1Y"] = "P1Y";
})(AdvancedCommerceOfferPeriod || (exports.AdvancedCommerceOfferPeriod = AdvancedCommerceOfferPeriod = {}));
class AdvancedCommerceOfferPeriodValidator extends Validator_1.StringValidator {
}
exports.AdvancedCommerceOfferPeriodValidator = AdvancedCommerceOfferPeriodValidator;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiQWR2YW5jZWRDb21tZXJjZU9mZmVyUGVyaW9kLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vbW9kZWxzL0FkdmFuY2VkQ29tbWVyY2VPZmZlclBlcmlvZC50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiO0FBQUEsNERBQTREOzs7QUFFNUQsMkNBQTZDO0FBRTdDOzs7O0dBSUc7QUFDSCxJQUFZLDJCQVVYO0FBVkQsV0FBWSwyQkFBMkI7SUFDbkMsMENBQVcsQ0FBQTtJQUNYLDBDQUFXLENBQUE7SUFDWCwwQ0FBVyxDQUFBO0lBQ1gsMENBQVcsQ0FBQTtJQUNYLDBDQUFXLENBQUE7SUFDWCwwQ0FBVyxDQUFBO0lBQ1gsMENBQVcsQ0FBQTtJQUNYLDBDQUFXLENBQUE7SUFDWCwwQ0FBVyxDQUFBO0FBQ2YsQ0FBQyxFQVZXLDJCQUEyQiwyQ0FBM0IsMkJBQTJCLFFBVXRDO0FBRUQsTUFBYSxvQ0FBcUMsU0FBUSwyQkFBZTtDQUFHO0FBQTVFLG9GQUE0RSIsInNvdXJjZXNDb250ZW50IjpbIi8vIENvcHlyaWdodCAoYykgMjAyNiBBcHBsZSBJbmMuIExpY2Vuc2VkIHVuZGVyIE1JVCBMaWNlbnNlLlxuXG5pbXBvcnQgeyBTdHJpbmdWYWxpZGF0b3IgfSBmcm9tIFwiLi9WYWxpZGF0b3JcIlxuXG4vKipcbiAqIFRoZSBwZXJpb2Qgb2YgdGhlIG9mZmVyLlxuICpcbiAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hZHZhbmNlZGNvbW1lcmNlYXBpL29mZmVyIE9mZmVyfVxuICovXG5leHBvcnQgZW51bSBBZHZhbmNlZENvbW1lcmNlT2ZmZXJQZXJpb2Qge1xuICAgIFAzRCA9IFwiUDNEXCIsXG4gICAgUDFXID0gXCJQMVdcIixcbiAgICBQMlcgPSBcIlAyV1wiLFxuICAgIFAxTSA9IFwiUDFNXCIsXG4gICAgUDJNID0gXCJQMk1cIixcbiAgICBQM00gPSBcIlAzTVwiLFxuICAgIFA2TSA9IFwiUDZNXCIsXG4gICAgUDlNID0gXCJQOU1cIixcbiAgICBQMVkgPSBcIlAxWVwiXG59XG5cbmV4cG9ydCBjbGFzcyBBZHZhbmNlZENvbW1lcmNlT2ZmZXJQZXJpb2RWYWxpZGF0b3IgZXh0ZW5kcyBTdHJpbmdWYWxpZGF0b3Ige30iXX0=