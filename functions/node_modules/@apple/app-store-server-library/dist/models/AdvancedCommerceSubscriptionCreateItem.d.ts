import { AbstractAdvancedCommerceItem } from './AbstractAdvancedCommerceItem';
import { AdvancedCommerceOffer, AdvancedCommerceOfferValidator } from './AdvancedCommerceOffer';
import { Validator } from './Validator';
/**
 * The data that describes a subscription item.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptioncreateitem SubscriptionCreateItem}
 */
export interface AdvancedCommerceSubscriptionCreateItem extends AbstractAdvancedCommerceItem {
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/offer Offer}
     */
    offer?: AdvancedCommerceOffer;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/price price}
     */
    price: number;
}
export declare class AdvancedCommerceSubscriptionCreateItemValidator implements Validator<AdvancedCommerceSubscriptionCreateItem> {
    static readonly offerValidator: AdvancedCommerceOfferValidator;
    validate(obj: any): obj is AdvancedCommerceSubscriptionCreateItem;
}
