import { StringValidator } from "./Validator";
/**
 * Information about the refund request for an item, such as its SKU, the refund amount, reason, and type.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/requestrefunditem RequestRefundItem}
 */
export declare enum AdvancedCommerceRefundType {
    FULL = "FULL",
    PRORATED = "PRORATED",
    CUSTOM = "CUSTOM"
}
export declare class AdvancedCommerceRefundTypeValidator extends StringValidator {
}
