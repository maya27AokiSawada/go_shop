import { AdvancedCommerceRequest } from './AdvancedCommerceRequest';
import { AdvancedCommerceRequestInfoValidator } from './AdvancedCommerceRequestInfo';
import { AdvancedCommerceRefundReason, AdvancedCommerceRefundReasonValidator } from './AdvancedCommerceRefundReason';
import { AdvancedCommerceRefundType, AdvancedCommerceRefundTypeValidator } from './AdvancedCommerceRefundType';
import { Validator } from './Validator';
/**
 * The request body you provide to terminate a subscription and all its items immediately.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionrevokerequest SubscriptionRevokeRequest}
 */
export interface AdvancedCommerceSubscriptionRevokeRequest extends AdvancedCommerceRequest {
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/refundreason refundReason}
     */
    refundReason: AdvancedCommerceRefundReason | string;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/refundriskingpreference refundRiskingPreference}
     */
    refundRiskingPreference: boolean;
    refundType: AdvancedCommerceRefundType | string;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/storefront storefront}
     */
    storefront?: string;
}
export declare class AdvancedCommerceSubscriptionRevokeRequestValidator implements Validator<AdvancedCommerceSubscriptionRevokeRequest> {
    static readonly requestInfoValidator: AdvancedCommerceRequestInfoValidator;
    static readonly refundReasonValidator: AdvancedCommerceRefundReasonValidator;
    static readonly refundTypeValidator: AdvancedCommerceRefundTypeValidator;
    validate(obj: any): obj is AdvancedCommerceSubscriptionRevokeRequest;
}
