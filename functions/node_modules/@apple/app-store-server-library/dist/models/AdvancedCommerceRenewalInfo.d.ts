import { AdvancedCommerceDescriptors, AdvancedCommerceDescriptorsValidator } from "./AdvancedCommerceDescriptors";
import { AdvancedCommercePeriod, AdvancedCommercePeriodValidator } from "./AdvancedCommercePeriod";
import { AdvancedCommerceRenewalItem, AdvancedCommerceRenewalItemValidator } from "./AdvancedCommerceRenewalItem";
import { Validator } from "./Validator";
/**
 * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercerenewalinfo advancedCommerceRenewalInfo}
 */
export interface AdvancedCommerceRenewalInfo {
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommerceconsistencytoken advancedCommerceConsistencyToken}
     **/
    consistencyToken?: string;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercedescriptors advancedCommerceDescriptors}
     **/
    descriptors?: AdvancedCommerceDescriptors;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercerenewalitem advancedCommerceRenewalItem}
     **/
    items?: AdvancedCommerceRenewalItem[];
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
}
export declare class AdvancedCommerceRenewalInfoValidator implements Validator<AdvancedCommerceRenewalInfo> {
    static readonly descriptorsValidator: AdvancedCommerceDescriptorsValidator;
    static readonly itemValidator: AdvancedCommerceRenewalItemValidator;
    static readonly periodValidator: AdvancedCommercePeriodValidator;
    validate(obj: any): obj is AdvancedCommerceRenewalInfo;
}
