import { NumberValidator } from "./Validator";
/**
 * The status that indicates whether an auto-renewable subscription is subject to a price increase.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/priceincreasestatus priceIncreaseStatus}
 */
export declare enum PriceIncreaseStatus {
    CUSTOMER_HAS_NOT_RESPONDED = 0,
    CUSTOMER_CONSENTED_OR_WAS_NOTIFIED_WITHOUT_NEEDING_CONSENT = 1
}
export declare class PriceIncreaseStatusValidator extends NumberValidator {
}
