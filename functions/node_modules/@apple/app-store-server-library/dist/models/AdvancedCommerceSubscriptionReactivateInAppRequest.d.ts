import { AbstractAdvancedCommerceInAppRequest } from './AbstractAdvancedCommerceInAppRequest';
import { AdvancedCommerceRequestInfoValidator } from './AdvancedCommerceRequestInfo';
import { AdvancedCommerceSubscriptionReactivateItem, AdvancedCommerceSubscriptionReactivateItemValidator } from './AdvancedCommerceSubscriptionReactivateItem';
import { Validator } from './Validator';
/**
 * The request your app provides to reactivate a subscription that has automatic renewal turned off.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionreactivateinapprequest SubscriptionReactivateInAppRequest}
 */
export interface AdvancedCommerceSubscriptionReactivateInAppRequest extends AbstractAdvancedCommerceInAppRequest {
    operation: "REACTIVATE_SUBSCRIPTION";
    version: "1";
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionreactivateitem SubscriptionReactivateItem}
     */
    items?: AdvancedCommerceSubscriptionReactivateItem[];
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/storefront storefront}
     */
    storefront?: string;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/transactionid transactionId}
     */
    transactionId: string;
}
export declare class AdvancedCommerceSubscriptionReactivateInAppRequestValidator implements Validator<AdvancedCommerceSubscriptionReactivateInAppRequest> {
    static readonly requestInfoValidator: AdvancedCommerceRequestInfoValidator;
    static readonly itemValidator: AdvancedCommerceSubscriptionReactivateItemValidator;
    validate(obj: any): obj is AdvancedCommerceSubscriptionReactivateInAppRequest;
}
