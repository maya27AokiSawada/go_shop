import { StringValidator } from "./Validator";
/**
 * The cause of a purchase transaction, which indicates whether it’s a customer’s purchase or a renewal for an auto-renewable subscription that the system initiates.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/transactionreason transactionReason}
 */
export declare enum TransactionReason {
    PURCHASE = "PURCHASE",
    RENEWAL = "RENEWAL"
}
export declare class TransactionReasonValidator extends StringValidator {
}
