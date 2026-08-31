import { AdvancedCommerceDescriptors, AdvancedCommerceDescriptorsValidator } from "./AdvancedCommerceDescriptors";
import { AdvancedCommercePeriod, AdvancedCommercePeriodValidator } from "./AdvancedCommercePeriod";
import { AdvancedCommerceTransactionItem, AdvancedCommerceTransactionItemValidator } from "./AdvancedCommerceTransactionItem";
import { Validator } from "./Validator";
/**
 * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercetransactioninfo advancedCommerceTransactionInfo}
 */
export interface AdvancedCommerceTransactionInfo {
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercedescriptors advancedCommerceDescriptors}
     **/
    descriptors?: AdvancedCommerceDescriptors;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommerceestimatedtax advancedCommerceEstimatedTax}
     **/
    estimatedTax?: number;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercetransactionitem advancedCommerceTransactionItem}
     **/
    items?: AdvancedCommerceTransactionItem[];
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommerceperiod advancedCommercePeriod}
     **/
    period?: AdvancedCommercePeriod | string;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercerequestreferenceid advancedCommerceRequestReferenceId}
     **/
    requestReferenceId?: string;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercetaxcode advancedCommerceTaxCode}
     **/
    taxCode?: string;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercetaxexclusiveprice advancedCommerceTaxExclusivePrice}
     **/
    taxExclusivePrice?: number;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercetaxrate advancedCommerceTaxRate}
     **/
    taxRate?: string;
}
export declare class AdvancedCommerceTransactionInfoValidator implements Validator<AdvancedCommerceTransactionInfo> {
    static readonly descriptorsValidator: AdvancedCommerceDescriptorsValidator;
    static readonly itemValidator: AdvancedCommerceTransactionItemValidator;
    static readonly periodValidator: AdvancedCommercePeriodValidator;
    validate(obj: any): obj is AdvancedCommerceTransactionInfo;
}
