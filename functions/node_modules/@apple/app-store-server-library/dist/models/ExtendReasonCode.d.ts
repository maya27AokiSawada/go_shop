import { NumberValidator } from "./Validator";
/**
 * The code that represents the reason for the subscription-renewal-date extension.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/extendreasoncode extendReasonCode}
 */
export declare enum ExtendReasonCode {
    UNDECLARED = 0,
    CUSTOMER_SATISFACTION = 1,
    OTHER = 2,
    SERVICE_ISSUE_OR_OUTAGE = 3
}
export declare class ExtendReasonCodeValidator extends NumberValidator {
}
