import { AbstractAdvancedCommerceResponse } from './AbstractAdvancedCommerceResponse';
import { Validator } from './Validator';
/**
 * A response that contains signed renewal and transaction information after a subscription successfully migrates to the Advanced Commerce API.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionmigrateresponse SubscriptionMigrateResponse}
 */
export interface AdvancedCommerceSubscriptionMigrateResponse extends AbstractAdvancedCommerceResponse {
}
export declare class AdvancedCommerceSubscriptionMigrateResponseValidator implements Validator<AdvancedCommerceSubscriptionMigrateResponse> {
    validate(obj: any): obj is AdvancedCommerceSubscriptionMigrateResponse;
}
