import { AbstractAdvancedCommerceItem } from './AbstractAdvancedCommerceItem';
import { Validator } from './Validator';
/**
 * The details of a one-time charge product, including its display name, price, SKU, and metadata.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/onetimechargeitem OneTimeChargeItem}
 */
export interface AdvancedCommerceOneTimeChargeItem extends AbstractAdvancedCommerceItem {
    /**
     * The price, in milliunits of the currency, of the one-time charge product.
     *
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/price price}
     **/
    price: number;
}
export declare class AdvancedCommerceOneTimeChargeItemValidator implements Validator<AdvancedCommerceOneTimeChargeItem> {
    validate(obj: any): obj is AdvancedCommerceOneTimeChargeItem;
}
