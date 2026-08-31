import { AdvancedCommerceEffective, AdvancedCommerceEffectiveValidator } from './AdvancedCommerceEffective';
import { Validator } from './Validator';
/**
 * The data your app provides to change the description and display name of an auto-renewable subscription.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionmodifydescriptors SubscriptionModifyDescriptors}
 */
export interface AdvancedCommerceSubscriptionModifyDescriptors {
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/effective effective}
     */
    effective: AdvancedCommerceEffective | string;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/description description}
     */
    description?: string;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/displayname displayName}
     */
    displayName?: string;
}
export declare class AdvancedCommerceSubscriptionModifyDescriptorsValidator implements Validator<AdvancedCommerceSubscriptionModifyDescriptors> {
    static readonly effectiveValidator: AdvancedCommerceEffectiveValidator;
    validate(obj: any): obj is AdvancedCommerceSubscriptionModifyDescriptors;
}
