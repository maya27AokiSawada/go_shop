import { AbstractAdvancedCommerceResponse } from './AbstractAdvancedCommerceResponse';
import { Validator } from './Validator';
/**
 * The response body for a successful subscription metadata change.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionchangemetadataresponse SubscriptionChangeMetadataResponse}
 */
export interface AdvancedCommerceSubscriptionChangeMetadataResponse extends AbstractAdvancedCommerceResponse {
}
export declare class AdvancedCommerceSubscriptionChangeMetadataResponseValidator implements Validator<AdvancedCommerceSubscriptionChangeMetadataResponse> {
    validate(obj: any): obj is AdvancedCommerceSubscriptionChangeMetadataResponse;
}
