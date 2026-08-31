import { AbstractAdvancedCommerceBaseItem } from './AbstractAdvancedCommerceBaseItem';
import { Validator } from './Validator';
/**
 * An item in a subscription to reactive.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionreactivateitem SubscriptionReactivateItem}
 */
export interface AdvancedCommerceSubscriptionReactivateItem extends AbstractAdvancedCommerceBaseItem {
}
export declare class AdvancedCommerceSubscriptionReactivateItemValidator implements Validator<AdvancedCommerceSubscriptionReactivateItem> {
    validate(obj: any): obj is AdvancedCommerceSubscriptionReactivateItem;
}
