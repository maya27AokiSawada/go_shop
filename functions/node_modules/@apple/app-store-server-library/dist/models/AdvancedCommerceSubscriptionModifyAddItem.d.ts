import { AbstractAdvancedCommerceItem } from './AbstractAdvancedCommerceItem';
import { AdvancedCommerceOffer, AdvancedCommerceOfferValidator } from './AdvancedCommerceOffer';
import { Validator } from './Validator';
/**
 * The data your app provides to add items when it makes changes to an auto-renewable subscription.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionmodifyadditem SubscriptionModifyAddItem}
 */
export interface AdvancedCommerceSubscriptionModifyAddItem extends AbstractAdvancedCommerceItem {
    /**
     * A discount offer for an auto-renewable subscription.
     *
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/offer Offer}
     */
    offer?: AdvancedCommerceOffer;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/price price}
     */
    price: number;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/proratedprice proratedPrice}
     */
    proratedPrice?: number;
}
export declare class AdvancedCommerceSubscriptionModifyAddItemValidator implements Validator<AdvancedCommerceSubscriptionModifyAddItem> {
    static readonly offerValidator: AdvancedCommerceOfferValidator;
    validate(obj: any): obj is AdvancedCommerceSubscriptionModifyAddItem;
}
