"use strict";
// Copyright (c) 2023 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.OfferTypeValidator = exports.OfferType = void 0;
const Validator_1 = require("./Validator");
/**
 * The type of offer.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/offertype offerType}
 */
var OfferType;
(function (OfferType) {
    OfferType[OfferType["INTRODUCTORY_OFFER"] = 1] = "INTRODUCTORY_OFFER";
    OfferType[OfferType["PROMOTIONAL_OFFER"] = 2] = "PROMOTIONAL_OFFER";
    OfferType[OfferType["OFFER_CODE"] = 3] = "OFFER_CODE";
    OfferType[OfferType["WIN_BACK_OFFER"] = 4] = "WIN_BACK_OFFER";
})(OfferType || (exports.OfferType = OfferType = {}));
class OfferTypeValidator extends Validator_1.NumberValidator {
}
exports.OfferTypeValidator = OfferTypeValidator;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiT2ZmZXJUeXBlLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vbW9kZWxzL09mZmVyVHlwZS50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiO0FBQUEsNERBQTREOzs7QUFFNUQsMkNBQThDO0FBRTlDOzs7O0dBSUc7QUFDSCxJQUFZLFNBS1g7QUFMRCxXQUFZLFNBQVM7SUFDakIscUVBQXNCLENBQUE7SUFDdEIsbUVBQXFCLENBQUE7SUFDckIscURBQWMsQ0FBQTtJQUNkLDZEQUFrQixDQUFBO0FBQ3RCLENBQUMsRUFMVyxTQUFTLHlCQUFULFNBQVMsUUFLcEI7QUFFRCxNQUFhLGtCQUFtQixTQUFRLDJCQUFlO0NBQUc7QUFBMUQsZ0RBQTBEIiwic291cmNlc0NvbnRlbnQiOlsiLy8gQ29weXJpZ2h0IChjKSAyMDIzIEFwcGxlIEluYy4gTGljZW5zZWQgdW5kZXIgTUlUIExpY2Vuc2UuXG5cbmltcG9ydCB7IE51bWJlclZhbGlkYXRvciB9IGZyb20gXCIuL1ZhbGlkYXRvclwiO1xuXG4vKipcbiAqIFRoZSB0eXBlIG9mIG9mZmVyLlxuICpcbiAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9vZmZlcnR5cGUgb2ZmZXJUeXBlfVxuICovXG5leHBvcnQgZW51bSBPZmZlclR5cGUge1xuICAgIElOVFJPRFVDVE9SWV9PRkZFUiA9IDEsXG4gICAgUFJPTU9USU9OQUxfT0ZGRVIgPSAyLFxuICAgIE9GRkVSX0NPREUgPSAzLFxuICAgIFdJTl9CQUNLX09GRkVSID0gNCxcbn1cblxuZXhwb3J0IGNsYXNzIE9mZmVyVHlwZVZhbGlkYXRvciBleHRlbmRzIE51bWJlclZhbGlkYXRvciB7fSJdfQ==