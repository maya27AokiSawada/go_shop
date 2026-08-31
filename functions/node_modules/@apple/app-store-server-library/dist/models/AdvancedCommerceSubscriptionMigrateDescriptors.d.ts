import { AdvancedCommerceDescriptors } from './AdvancedCommerceDescriptors';
import { Validator } from './Validator';
/**
 * The description and display name of the subscription to migrate to that you manage.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionmigratedescriptors SubscriptionMigrateDescriptors}
 */
export interface AdvancedCommerceSubscriptionMigrateDescriptors extends AdvancedCommerceDescriptors {
}
export declare class AdvancedCommerceSubscriptionMigrateDescriptorsValidator implements Validator<AdvancedCommerceSubscriptionMigrateDescriptors> {
    validate(obj: any): obj is AdvancedCommerceSubscriptionMigrateDescriptors;
}
