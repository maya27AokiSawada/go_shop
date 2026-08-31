import { StringValidator } from "./Validator";
/**
 * The customer-provided reason for a refund request.
 *
 * {@link https://developer.apple.com/documentation/appstoreservernotifications/consumptionrequestreason consumptionRequestReason}
 */
export declare enum ConsumptionRequestReason {
    UNINTENDED_PURCHASE = "UNINTENDED_PURCHASE",
    FULFILLMENT_ISSUE = "FULFILLMENT_ISSUE",
    UNSATISFIED_WITH_PURCHASE = "UNSATISFIED_WITH_PURCHASE",
    LEGAL = "LEGAL",
    OTHER = "OTHER"
}
export declare class ConsumptionRequestReasonValidator extends StringValidator {
}
