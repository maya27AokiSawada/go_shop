import { StringValidator } from "./Validator";
/**
 * The payment mode for a discount offer on an In-App Purchase.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/offerdiscounttype offerDiscountType}
 */
export declare enum OfferDiscountType {
    FREE_TRIAL = "FREE_TRIAL",
    PAY_AS_YOU_GO = "PAY_AS_YOU_GO",
    PAY_UP_FRONT = "PAY_UP_FRONT",
    ONE_TIME = "ONE_TIME"
}
export declare class OfferDiscountTypeValidator extends StringValidator {
}
