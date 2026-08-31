import { Validator } from './Validator';
/**
 * The display name and description of a subscription product.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/descriptors Descriptors}
 */
export interface AdvancedCommerceDescriptors {
    /**
     * A string you provide that describes a SKU.
     *
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/description description}
     **/
    description: string;
    /**
     * A string with a product name that you can localize and is suitable for display to customers.
     *
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/displayname displayName}
     **/
    displayName: string;
}
export declare class AdvancedCommerceDescriptorsValidator implements Validator<AdvancedCommerceDescriptors> {
    validate(obj: any): obj is AdvancedCommerceDescriptors;
}
