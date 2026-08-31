import { AbstractAdvancedCommerceBaseItem } from './AbstractAdvancedCommerceBaseItem';
import { Validator } from './Validator';
/**
 * The data your app provides to remove an item from an auto-renewable subscription.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionmodifyremoveitem SubscriptionModifyRemoveItem}
 */
export interface AdvancedCommerceSubscriptionModifyRemoveItem extends AbstractAdvancedCommerceBaseItem {
}
export declare class AdvancedCommerceSubscriptionModifyRemoveItemValidator implements Validator<AdvancedCommerceSubscriptionModifyRemoveItem> {
    validate(obj: any): obj is AdvancedCommerceSubscriptionModifyRemoveItem;
}
