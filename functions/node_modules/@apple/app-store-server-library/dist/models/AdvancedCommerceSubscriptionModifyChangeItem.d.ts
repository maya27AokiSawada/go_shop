import { AbstractAdvancedCommerceItem } from './AbstractAdvancedCommerceItem';
import { AdvancedCommerceEffective, AdvancedCommerceEffectiveValidator } from './AdvancedCommerceEffective';
import { AdvancedCommerceOffer, AdvancedCommerceOfferValidator } from './AdvancedCommerceOffer';
import { AdvancedCommerceReason, AdvancedCommerceReasonValidator } from './AdvancedCommerceReason';
import { Validator } from './Validator';
/**
 * The data your app provides to change an item of an auto-renewable subscription.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionmodifychangeitem SubscriptionModifyChangeItem}
 */
export interface AdvancedCommerceSubscriptionModifyChangeItem extends AbstractAdvancedCommerceItem {
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/sku SKU}
     */
    currentSKU: string;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/effective effective}
     */
    effective: AdvancedCommerceEffective | string;
    /**
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
    reason: AdvancedCommerceReason | string;
}
export declare class AdvancedCommerceSubscriptionModifyChangeItemValidator implements Validator<AdvancedCommerceSubscriptionModifyChangeItem> {
    static readonly effectiveValidator: AdvancedCommerceEffectiveValidator;
    static readonly offerValidator: AdvancedCommerceOfferValidator;
    static readonly reasonValidator: AdvancedCommerceReasonValidator;
    validate(obj: any): obj is AdvancedCommerceSubscriptionModifyChangeItem;
}
