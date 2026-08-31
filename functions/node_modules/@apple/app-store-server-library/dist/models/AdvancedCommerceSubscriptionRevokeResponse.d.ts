import { AbstractAdvancedCommerceResponse } from './AbstractAdvancedCommerceResponse';
import { Validator } from './Validator';
/**
 * The response body for a successful revoke-subscription request.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionrevokeresponse SubscriptionRevokeResponse}
 */
export interface AdvancedCommerceSubscriptionRevokeResponse extends AbstractAdvancedCommerceResponse {
}
export declare class AdvancedCommerceSubscriptionRevokeResponseValidator implements Validator<AdvancedCommerceSubscriptionRevokeResponse> {
    validate(obj: any): obj is AdvancedCommerceSubscriptionRevokeResponse;
}
