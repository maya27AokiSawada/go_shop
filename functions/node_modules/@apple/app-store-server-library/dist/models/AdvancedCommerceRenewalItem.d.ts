import { AdvancedCommerceOffer, AdvancedCommerceOfferValidator } from "./AdvancedCommerceOffer";
import { AdvancedCommercePriceIncreaseInfo, AdvancedCommercePriceIncreaseInfoValidator } from "./AdvancedCommercePriceIncreaseInfo";
import { Validator } from "./Validator";
/**
 * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercerenewalitem advancedCommerceRenewalItem}
 */
export interface AdvancedCommerceRenewalItem {
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercesku advancedCommerceSKU}
     **/
    SKU?: string;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercedescription advancedCommerceDescription}
     **/
    description?: string;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercedisplayname advancedCommerceDisplayName}
     **/
    displayName?: string;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommerceoffer advancedCommerceOffer}
     **/
    offer?: AdvancedCommerceOffer;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommerceprice advancedCommercePrice}
     **/
    price?: number;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercepriceincreaseinfo advancedCommercePriceIncreaseInfo}
     **/
    priceIncreaseInfo?: AdvancedCommercePriceIncreaseInfo;
}
export declare class AdvancedCommerceRenewalItemValidator implements Validator<AdvancedCommerceRenewalItem> {
    static readonly offerValidator: AdvancedCommerceOfferValidator;
    static readonly priceIncreaseInfoValidator: AdvancedCommercePriceIncreaseInfoValidator;
    validate(obj: any): obj is AdvancedCommerceRenewalItem;
}
