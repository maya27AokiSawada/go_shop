import { StringValidator } from "./Validator";
/**
 * {@link https://developer.apple.com/documentation/appstoreserverapi/billingplantype billingPlanType}
 */
export declare enum BillingPlanType {
    BILLED_UPFRONT = "BILLED_UPFRONT",
    MONTHLY = "MONTHLY"
}
export declare class BillingPlanTypeValidator extends StringValidator {
}
