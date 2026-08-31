import { StringValidator } from "./Validator";
/**
 * The period of the offer.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/offer Offer}
 */
export declare enum AdvancedCommerceOfferPeriod {
    P3D = "P3D",
    P1W = "P1W",
    P2W = "P2W",
    P1M = "P1M",
    P2M = "P2M",
    P3M = "P3M",
    P6M = "P6M",
    P9M = "P9M",
    P1Y = "P1Y"
}
export declare class AdvancedCommerceOfferPeriodValidator extends StringValidator {
}
