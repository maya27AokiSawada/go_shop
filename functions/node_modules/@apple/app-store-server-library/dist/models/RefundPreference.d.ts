import { StringValidator } from "./Validator";
/**
 * A value that indicates your preferred outcome for the refund request.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/refundpreference refundPreference}
 */
export declare enum RefundPreference {
    DECLINE = "DECLINE",
    GRANT_FULL = "GRANT_FULL",
    GRANT_PRORATED = "GRANT_PRORATED"
}
export declare class RefundPreferenceValidator extends StringValidator {
}
