import { AbstractAdvancedCommerceItem } from './AbstractAdvancedCommerceItem';
import { Validator } from './Validator';
/**
 * The SKU, description, and display name to use for a migrated subscription item.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionmigrateitem SubscriptionMigrateItem}
 */
export interface AdvancedCommerceSubscriptionMigrateItem extends AbstractAdvancedCommerceItem {
}
export declare class AdvancedCommerceSubscriptionMigrateItemValidator implements Validator<AdvancedCommerceSubscriptionMigrateItem> {
    validate(obj: any): obj is AdvancedCommerceSubscriptionMigrateItem;
}
