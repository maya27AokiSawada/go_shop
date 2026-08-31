import { AbstractAdvancedCommerceResponse } from './AbstractAdvancedCommerceResponse';
import { Validator } from './Validator';
/**
 * A response that contains signed JWS renewal and JWS transaction information after a subscription price change request.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionpricechangeresponse SubscriptionPriceChangeResponse}
 */
export interface AdvancedCommerceSubscriptionPriceChangeResponse extends AbstractAdvancedCommerceResponse {
}
export declare class AdvancedCommerceSubscriptionPriceChangeResponseValidator implements Validator<AdvancedCommerceSubscriptionPriceChangeResponse> {
    validate(obj: any): obj is AdvancedCommerceSubscriptionPriceChangeResponse;
}
