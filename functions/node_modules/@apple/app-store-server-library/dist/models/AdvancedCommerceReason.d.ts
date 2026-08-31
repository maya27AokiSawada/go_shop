import { StringValidator } from "./Validator";
/**
 * The data your app provides to change an item of an auto-renewable subscription.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionmodifychangeitem SubscriptionModifyChangeItem}
 */
export declare enum AdvancedCommerceReason {
    UPGRADE = "UPGRADE",
    DOWNGRADE = "DOWNGRADE",
    APPLY_OFFER = "APPLY_OFFER"
}
export declare class AdvancedCommerceReasonValidator extends StringValidator {
}
