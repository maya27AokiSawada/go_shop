import { StringValidator } from "./Validator";
/**
 * The type of the refund or revocation that applies to the transaction.
 *
 * {@link https://developer.apple.com/documentation/appstoreservernotifications/revocationtype revocationType}
 */
export declare enum RevocationType {
    REFUND_FULL = "REFUND_FULL",
    REFUND_PRORATED = "REFUND_PRORATED",
    FAMILY_REVOKE = "FAMILY_REVOKE"
}
export declare class RevocationTypeValidator extends StringValidator {
}
