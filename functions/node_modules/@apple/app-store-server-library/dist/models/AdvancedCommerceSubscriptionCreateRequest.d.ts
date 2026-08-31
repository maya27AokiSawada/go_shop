import { AbstractAdvancedCommerceInAppRequest } from './AbstractAdvancedCommerceInAppRequest';
import { AdvancedCommerceDescriptors, AdvancedCommerceDescriptorsValidator } from './AdvancedCommerceDescriptors';
import { AdvancedCommerceSubscriptionCreateItem, AdvancedCommerceSubscriptionCreateItemValidator } from './AdvancedCommerceSubscriptionCreateItem';
import { AdvancedCommercePeriod, AdvancedCommercePeriodValidator } from './AdvancedCommercePeriod';
import { AdvancedCommerceRequestInfoValidator } from './AdvancedCommerceRequestInfo';
import { Validator } from './Validator';
/**
 * The request data your app provides when a customer purchases an auto-renewable subscription.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptioncreaterequest SubscriptionCreateRequest}
 */
export interface AdvancedCommerceSubscriptionCreateRequest extends AbstractAdvancedCommerceInAppRequest {
    operation: "CREATE_SUBSCRIPTION";
    version: "1";
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/currency currency}
     */
    currency: string;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/descriptors descriptors}
     */
    descriptors: AdvancedCommerceDescriptors;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptioncreateitem SubscriptionCreateItem}
     */
    items: AdvancedCommerceSubscriptionCreateItem[];
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/period period}
     */
    period: AdvancedCommercePeriod | string;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/transactionid transactionId}
     */
    previousTransactionId?: string;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/storefront storefront}
     */
    storefront?: string;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/taxCode taxCode}
     */
    taxCode: string;
}
export declare class AdvancedCommerceSubscriptionCreateRequestValidator implements Validator<AdvancedCommerceSubscriptionCreateRequest> {
    static readonly requestInfoValidator: AdvancedCommerceRequestInfoValidator;
    static readonly descriptorsValidator: AdvancedCommerceDescriptorsValidator;
    static readonly itemValidator: AdvancedCommerceSubscriptionCreateItemValidator;
    static readonly periodValidator: AdvancedCommercePeriodValidator;
    validate(obj: any): obj is AdvancedCommerceSubscriptionCreateRequest;
}
