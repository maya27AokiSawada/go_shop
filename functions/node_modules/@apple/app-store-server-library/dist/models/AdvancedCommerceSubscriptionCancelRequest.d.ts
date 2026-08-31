import { AdvancedCommerceRequest } from './AdvancedCommerceRequest';
import { AdvancedCommerceRequestInfoValidator } from './AdvancedCommerceRequestInfo';
import { Validator } from './Validator';
/**
 * The request body for turning off automatic renewal of a subscription.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptioncancelrequest SubscriptionCancelRequest}
 */
export interface AdvancedCommerceSubscriptionCancelRequest extends AdvancedCommerceRequest {
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/storefront storefront}
     **/
    storefront?: string;
}
export declare class AdvancedCommerceSubscriptionCancelRequestValidator implements Validator<AdvancedCommerceSubscriptionCancelRequest> {
    static readonly requestInfoValidator: AdvancedCommerceRequestInfoValidator;
    validate(obj: any): obj is AdvancedCommerceSubscriptionCancelRequest;
}
