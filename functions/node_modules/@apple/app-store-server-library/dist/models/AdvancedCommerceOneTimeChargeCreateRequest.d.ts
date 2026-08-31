import { AbstractAdvancedCommerceInAppRequest } from './AbstractAdvancedCommerceInAppRequest';
import { AdvancedCommerceOneTimeChargeItem, AdvancedCommerceOneTimeChargeItemValidator } from './AdvancedCommerceOneTimeChargeItem';
import { AdvancedCommerceRequestInfoValidator } from './AdvancedCommerceRequestInfo';
import { Validator } from './Validator';
/**
 * The request data your app provides when a customer purchases a one-time-charge product.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/onetimechargecreaterequest OneTimeChargeCreateRequest}
 */
export interface AdvancedCommerceOneTimeChargeCreateRequest extends AbstractAdvancedCommerceInAppRequest {
    /**
     * The constant that represents the operation of this request.
     */
    operation: "CREATE_ONE_TIME_CHARGE";
    /**
     * The version number of the API.
     */
    version: "1";
    /**
     * The currency of the price of the product.
     *
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/currency currency}
     **/
    currency: string;
    /**
     * The details of the product for purchase.
     *
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/onetimechargeitem OneTimeChargeItem}
     **/
    item: AdvancedCommerceOneTimeChargeItem;
    /**
     * The storefront for the transaction.
     *
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/storefront storefront}
     **/
    storefront?: string;
    /**
     * The tax code for this product.
     *
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/taxCode taxCode}
     **/
    taxCode: string;
}
export declare class AdvancedCommerceOneTimeChargeCreateRequestValidator implements Validator<AdvancedCommerceOneTimeChargeCreateRequest> {
    static readonly itemValidator: AdvancedCommerceOneTimeChargeItemValidator;
    static readonly requestInfoValidator: AdvancedCommerceRequestInfoValidator;
    validate(obj: any): obj is AdvancedCommerceOneTimeChargeCreateRequest;
}
