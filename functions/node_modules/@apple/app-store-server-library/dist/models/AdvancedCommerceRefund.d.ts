import { AdvancedCommerceRefundReason, AdvancedCommerceRefundReasonValidator } from "./AdvancedCommerceRefundReason";
import { AdvancedCommerceRefundType, AdvancedCommerceRefundTypeValidator } from "./AdvancedCommerceRefundType";
import { Validator } from "./Validator";
/**
 * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercerefund advancedCommerceRefund}
 */
export interface AdvancedCommerceRefund {
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercerefundamount advancedCommerceRefundAmount}
     **/
    refundAmount?: number;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercerefunddate advancedCommerceRefundDate}
     **/
    refundDate?: number;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercerefundreason advancedCommerceRefundReason}
     **/
    refundReason?: AdvancedCommerceRefundReason | string;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercerefundtype advancedCommerceRefundType}
     **/
    refundType?: AdvancedCommerceRefundType | string;
}
export declare class AdvancedCommerceRefundValidator implements Validator<AdvancedCommerceRefund> {
    static readonly refundReasonValidator: AdvancedCommerceRefundReasonValidator;
    static readonly refundTypeValidator: AdvancedCommerceRefundTypeValidator;
    validate(obj: any): obj is AdvancedCommerceRefund;
}
