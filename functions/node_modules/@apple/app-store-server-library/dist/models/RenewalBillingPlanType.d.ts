import { StringValidator } from "./Validator";
/**
 * {@link https://developer.apple.com/documentation/appstoreserverapi/renewalbillingplantype renewalBillingPlanType}
 */
export declare enum RenewalBillingPlanType {
    BILLED_UPFRONT = "BILLED_UPFRONT",
    MONTHLY = "MONTHLY"
}
export declare class RenewalBillingPlanTypeValidator extends StringValidator {
}
