import { StringValidator } from "./Validator";
/**
 * {@link https://developer.apple.com/documentation/appstoreservernotifications/advancedcommercepriceincreaseinfostatus advancedCommercePriceIncreaseInfoStatus}
 */
export declare enum AdvancedCommercePriceIncreaseInfoStatus {
    SCHEDULED = "SCHEDULED",
    PENDING = "PENDING",
    ACCEPTED = "ACCEPTED"
}
export declare class AdvancedCommercePriceIncreaseInfoStatusValidator extends StringValidator {
}
