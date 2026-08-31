import { StringValidator } from "./Validator";
/**
 * A string that provides details about select notification types in version 2.
 *
 * {@link https://developer.apple.com/documentation/appstoreservernotifications/subtype subtype}
 */
export declare enum Subtype {
    INITIAL_BUY = "INITIAL_BUY",
    RESUBSCRIBE = "RESUBSCRIBE",
    DOWNGRADE = "DOWNGRADE",
    UPGRADE = "UPGRADE",
    AUTO_RENEW_ENABLED = "AUTO_RENEW_ENABLED",
    AUTO_RENEW_DISABLED = "AUTO_RENEW_DISABLED",
    VOLUNTARY = "VOLUNTARY",
    BILLING_RETRY = "BILLING_RETRY",
    PRICE_INCREASE = "PRICE_INCREASE",
    GRACE_PERIOD = "GRACE_PERIOD",
    PENDING = "PENDING",
    ACCEPTED = "ACCEPTED",
    BILLING_RECOVERY = "BILLING_RECOVERY",
    PRODUCT_NOT_FOR_SALE = "PRODUCT_NOT_FOR_SALE",
    SUMMARY = "SUMMARY",
    FAILURE = "FAILURE",
    UNREPORTED = "UNREPORTED"
}
export declare class SubtypeValidator extends StringValidator {
}
