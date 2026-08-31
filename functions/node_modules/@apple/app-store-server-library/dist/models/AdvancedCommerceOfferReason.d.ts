import { StringValidator } from "./Validator";
/**
 * The reason for the offer.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/offer Offer}
 */
export declare enum AdvancedCommerceOfferReason {
    ACQUISITION = "ACQUISITION",
    WIN_BACK = "WIN_BACK",
    RETENTION = "RETENTION"
}
export declare class AdvancedCommerceOfferReasonValidator extends StringValidator {
}
