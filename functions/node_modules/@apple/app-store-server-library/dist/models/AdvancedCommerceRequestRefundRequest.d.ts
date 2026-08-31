import { AdvancedCommerceRequest } from './AdvancedCommerceRequest';
import { AdvancedCommerceRequestInfoValidator } from './AdvancedCommerceRequestInfo';
import { AdvancedCommerceRequestRefundItem, AdvancedCommerceRequestRefundItemValidator } from './AdvancedCommerceRequestRefundItem';
import { Validator } from './Validator';
/**
 * The request body for requesting a refund for a transaction.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/requestrefundrequest RequestRefundRequest}
 */
export interface AdvancedCommerceRequestRefundRequest extends AdvancedCommerceRequest {
    /**
     * The currency of the transaction.
     *
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/currency currency}
     **/
    currency?: string;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/requestrefunditem RequestRefundItem}
     **/
    items: AdvancedCommerceRequestRefundItem[];
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/refundriskingpreference RefundRiskingPreference}
     **/
    refundRiskingPreference: boolean;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/storefront storefront}
     **/
    storefront?: string;
}
export declare class AdvancedCommerceRequestRefundRequestValidator implements Validator<AdvancedCommerceRequestRefundRequest> {
    static readonly requestInfoValidator: AdvancedCommerceRequestInfoValidator;
    static readonly itemValidator: AdvancedCommerceRequestRefundItemValidator;
    validate(obj: any): obj is AdvancedCommerceRequestRefundRequest;
}
