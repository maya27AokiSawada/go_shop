import { AdvancedCommerceEffective, AdvancedCommerceEffectiveValidator } from './AdvancedCommerceEffective';
import { AdvancedCommercePeriod, AdvancedCommercePeriodValidator } from './AdvancedCommercePeriod';
import { Validator } from './Validator';
/**
 * The data your app provides to change the period of an auto-renewable subscription.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionmodifyperiodchange SubscriptionModifyPeriodChange}
 */
export interface AdvancedCommerceSubscriptionModifyPeriodChange {
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/effective effective}
     */
    effective: AdvancedCommerceEffective | string;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/period Period}
     */
    period: AdvancedCommercePeriod | string;
}
export declare class AdvancedCommerceSubscriptionModifyPeriodChangeValidator implements Validator<AdvancedCommerceSubscriptionModifyPeriodChange> {
    static readonly effectiveValidator: AdvancedCommerceEffectiveValidator;
    static readonly periodValidator: AdvancedCommercePeriodValidator;
    validate(obj: any): obj is AdvancedCommerceSubscriptionModifyPeriodChange;
}
