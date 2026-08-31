import { AbstractAdvancedCommerceBaseItem } from './AbstractAdvancedCommerceBaseItem';
import { Validator } from './Validator';
/**
 * The data your app provides to change a subscription price.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionpricechangeitem SubscriptionPriceChangeItem}
 */
export interface AdvancedCommerceSubscriptionPriceChangeItem extends AbstractAdvancedCommerceBaseItem {
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/price price}
     */
    price: number;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/dependentsku dependentSKU}
     */
    dependentSKUs?: String[];
}
export declare class AdvancedCommerceSubscriptionPriceChangeItemValidator implements Validator<AdvancedCommerceSubscriptionPriceChangeItem> {
    validate(obj: any): obj is AdvancedCommerceSubscriptionPriceChangeItem;
}
