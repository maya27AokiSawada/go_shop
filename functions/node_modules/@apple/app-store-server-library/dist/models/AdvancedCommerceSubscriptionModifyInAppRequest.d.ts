import { AbstractAdvancedCommerceInAppRequest } from './AbstractAdvancedCommerceInAppRequest';
import { AdvancedCommerceRequestInfoValidator } from './AdvancedCommerceRequestInfo';
import { AdvancedCommerceSubscriptionModifyAddItem, AdvancedCommerceSubscriptionModifyAddItemValidator } from './AdvancedCommerceSubscriptionModifyAddItem';
import { AdvancedCommerceSubscriptionModifyChangeItem, AdvancedCommerceSubscriptionModifyChangeItemValidator } from './AdvancedCommerceSubscriptionModifyChangeItem';
import { AdvancedCommerceSubscriptionModifyDescriptors, AdvancedCommerceSubscriptionModifyDescriptorsValidator } from './AdvancedCommerceSubscriptionModifyDescriptors';
import { AdvancedCommerceSubscriptionModifyPeriodChange, AdvancedCommerceSubscriptionModifyPeriodChangeValidator } from './AdvancedCommerceSubscriptionModifyPeriodChange';
import { AdvancedCommerceSubscriptionModifyRemoveItem, AdvancedCommerceSubscriptionModifyRemoveItemValidator } from './AdvancedCommerceSubscriptionModifyRemoveItem';
import { Validator } from './Validator';
/**
 * The request data your app provides to make changes to an auto-renewable subscription.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionmodifyinapprequest SubscriptionModifyInAppRequest}
 */
export interface AdvancedCommerceSubscriptionModifyInAppRequest extends AbstractAdvancedCommerceInAppRequest {
    operation: "MODIFY_SUBSCRIPTION";
    version: "1";
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionmodifyadditem SubscriptionModifyAddItem}
     */
    addItems?: AdvancedCommerceSubscriptionModifyAddItem[];
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionmodifychangeitem SubscriptionModifyChangeItem}
     */
    changeItems?: AdvancedCommerceSubscriptionModifyChangeItem[];
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/currency currency}
     */
    currency?: string;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionmodifydescriptors SubscriptionModifyDescriptors}
     */
    descriptors?: AdvancedCommerceSubscriptionModifyDescriptors;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionmodifyperiodchange SubscriptionModifyPeriodChange}
     */
    periodChange?: AdvancedCommerceSubscriptionModifyPeriodChange;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionmodifyremoveitem SubscriptionModifyRemoveItem}
     */
    removeItems?: AdvancedCommerceSubscriptionModifyRemoveItem[];
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/retainbillingcycle retainBillingCycle}
     */
    retainBillingCycle: boolean;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/storefront storefront}
     */
    storefront?: string;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/taxcode taxCode}
     */
    taxCode?: string;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/transactionid transactionId}
     */
    transactionId: string;
}
export declare class AdvancedCommerceSubscriptionModifyInAppRequestValidator implements Validator<AdvancedCommerceSubscriptionModifyInAppRequest> {
    static readonly requestInfoValidator: AdvancedCommerceRequestInfoValidator;
    static readonly addItemValidator: AdvancedCommerceSubscriptionModifyAddItemValidator;
    static readonly changeItemValidator: AdvancedCommerceSubscriptionModifyChangeItemValidator;
    static readonly descriptorsValidator: AdvancedCommerceSubscriptionModifyDescriptorsValidator;
    static readonly periodChangeValidator: AdvancedCommerceSubscriptionModifyPeriodChangeValidator;
    static readonly removeItemValidator: AdvancedCommerceSubscriptionModifyRemoveItemValidator;
    validate(obj: any): obj is AdvancedCommerceSubscriptionModifyInAppRequest;
}
