import { AbstractAdvancedCommerceResponse } from './AbstractAdvancedCommerceResponse';
import { Validator } from './Validator';
/**
 * The response body for a successful subscription cancellation.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptioncancelresponse SubscriptionCancelResponse}
 */
export interface AdvancedCommerceSubscriptionCancelResponse extends AbstractAdvancedCommerceResponse {
}
export declare class AdvancedCommerceSubscriptionCancelResponseValidator implements Validator<AdvancedCommerceSubscriptionCancelResponse> {
    validate(obj: any): obj is AdvancedCommerceSubscriptionCancelResponse;
}
