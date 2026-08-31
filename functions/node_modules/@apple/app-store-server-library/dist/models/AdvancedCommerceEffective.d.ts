import { StringValidator } from "./Validator";
/**
 * A string value that indicates when a requested change to an auto-renewable subscription goes into effect.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/effective effective}
 */
export declare enum AdvancedCommerceEffective {
    IMMEDIATELY = "IMMEDIATELY",
    NEXT_BILL_CYCLE = "NEXT_BILL_CYCLE"
}
export declare class AdvancedCommerceEffectiveValidator extends StringValidator {
}
