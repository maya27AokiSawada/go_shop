import { AdvancedCommerceRequest } from './AdvancedCommerceRequest';
import { AdvancedCommerceRequestInfoValidator } from './AdvancedCommerceRequestInfo';
import { AdvancedCommerceSubscriptionChangeMetadataDescriptors, AdvancedCommerceSubscriptionChangeMetadataDescriptorsValidator } from './AdvancedCommerceSubscriptionChangeMetadataDescriptors';
import { AdvancedCommerceSubscriptionChangeMetadataItem, AdvancedCommerceSubscriptionChangeMetadataItemValidator } from './AdvancedCommerceSubscriptionChangeMetadataItem';
import { Validator } from './Validator';
/**
 * The request body you provide to change the metadata of a subscription.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionchangemetadatarequest SubscriptionChangeMetadataRequest}
 */
export interface AdvancedCommerceSubscriptionChangeMetadataRequest extends AdvancedCommerceRequest {
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionchangemetadatadescriptors SubscriptionChangeMetadataDescriptors}
     **/
    descriptors?: AdvancedCommerceSubscriptionChangeMetadataDescriptors;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/subscriptionchangemetadataitem SubscriptionChangeMetadataItem}
     **/
    items?: AdvancedCommerceSubscriptionChangeMetadataItem[];
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/storefront storefront}
     **/
    storefront?: string;
    /**
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/taxcode taxCode}
     **/
    taxCode?: string;
}
export declare class AdvancedCommerceSubscriptionChangeMetadataRequestValidator implements Validator<AdvancedCommerceSubscriptionChangeMetadataRequest> {
    static readonly requestInfoValidator: AdvancedCommerceRequestInfoValidator;
    static readonly descriptorsValidator: AdvancedCommerceSubscriptionChangeMetadataDescriptorsValidator;
    static readonly itemValidator: AdvancedCommerceSubscriptionChangeMetadataItemValidator;
    validate(obj: any): obj is AdvancedCommerceSubscriptionChangeMetadataRequest;
}
