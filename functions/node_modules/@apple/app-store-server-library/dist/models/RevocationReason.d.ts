import { NumberValidator } from "./Validator";
/**
 * The reason for a refunded transaction.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/revocationreason revocationReason}
 */
export declare enum RevocationReason {
    REFUNDED_DUE_TO_ISSUE = 1,
    REFUNDED_FOR_OTHER_REASON = 0
}
export declare class RevocationReasonValidator extends NumberValidator {
}
