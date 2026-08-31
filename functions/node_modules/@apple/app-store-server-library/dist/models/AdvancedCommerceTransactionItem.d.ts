import { AdvancedCommerceOffer, AdvancedCommerceOfferValidator } from "./AdvancedCommerceOffer";
import { AdvancedCommerceRefund, AdvancedCommerceRefundValidator } from "./AdvancedCommerceRefund";
import { Validator } from "./Validator";
/**
 * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercetransactionitem advancedCommerceTransactionItem}
 */
export interface AdvancedCommerceTransactionItem {
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
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercerefunds advancedCommerceRefunds}
     **/
    refunds?: AdvancedCommerceRefund[];
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/revocationdate revocationDate}
     **/
    revocationDate?: number;
}
export declare class AdvancedCommerceTransactionItemValidator implements Validator<AdvancedCommerceTransactionItem> {
    static readonly offerValidator: AdvancedCommerceOfferValidator;
    static readonly refundValidator: AdvancedCommerceRefundValidator;
    validate(obj: any): obj is AdvancedCommerceTransactionItem;
}
