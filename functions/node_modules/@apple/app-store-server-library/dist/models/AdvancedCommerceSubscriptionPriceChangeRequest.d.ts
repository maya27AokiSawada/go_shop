import { AdvancedCommerceRequest } from './AdvancedCommerceRequest';
import { AdvancedCommerceRequestInfoValidator } from './AdvancedCommerceRequestInfo';
import { AdvancedCommerceSubscriptionPriceChangeItem, AdvancedCommerceSubscriptionPriceChangeItemValidator } from './AdvancedCommerceSubscriptionPriceChangeItem';
import { Validator } from './Validator';
/**
 * The request body you use to change the price of an auto-renewable subscription.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionpricechangerequest SubscriptionPriceChangeRequest}
 */
export interface AdvancedCommerceSubscriptionPriceChangeRequest extends AdvancedCommerceRequest {
    /**
     * The currency of the prices.
     *
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/currency currency}
     */
    currency?: string;
    /**
     * An array that contains one or more SKUs and the changed price for each SKU.
     *
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionpricechangeitem SubscriptionPriceChangeItem}
     */
    items: AdvancedCommerceSubscriptionPriceChangeItem[];
    /**
     * The App Store storefront of the subscription.
     *
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/storefront storefront}
     */
    storefront?: string;
}
export declare class AdvancedCommerceSubscriptionPriceChangeRequestValidator implements Validator<AdvancedCommerceSubscriptionPriceChangeRequest> {
    static readonly requestInfoValidator: AdvancedCommerceRequestInfoValidator;
    static readonly itemValidator: AdvancedCommerceSubscriptionPriceChangeItemValidator;
    validate(obj: any): obj is AdvancedCommerceSubscriptionPriceChangeRequest;
}
