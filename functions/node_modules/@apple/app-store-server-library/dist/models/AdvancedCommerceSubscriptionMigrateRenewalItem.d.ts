import { AbstractAdvancedCommerceItem } from './AbstractAdvancedCommerceItem';
import { Validator } from './Validator';
/**
 * The item information that replaces a migrated subscription item when the subscription renews.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionmigraterenewalitem SubscriptionMigrateRenewalItem}
 */
export interface AdvancedCommerceSubscriptionMigrateRenewalItem extends AbstractAdvancedCommerceItem {
}
export declare class AdvancedCommerceSubscriptionMigrateRenewalItemValidator implements Validator<AdvancedCommerceSubscriptionMigrateRenewalItem> {
    validate(obj: any): obj is AdvancedCommerceSubscriptionMigrateRenewalItem;
}
