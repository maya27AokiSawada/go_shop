import { AdvancedCommercePriceIncreaseInfoStatus, AdvancedCommercePriceIncreaseInfoStatusValidator } from "./AdvancedCommercePriceIncreaseInfoStatus";
import { Validator } from "./Validator";
/**
 * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercepriceincreaseinfo advancedCommercePriceIncreaseInfo}
 */
export interface AdvancedCommercePriceIncreaseInfo {
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercepriceincreaseinfodependentsku advancedCommercePriceIncreaseInfoDependentSKU}
     **/
    dependentSKUs?: string[];
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercepriceincreaseinfoprice advancedCommercePriceIncreaseInfoPrice}
     **/
    price?: number;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercepriceincreaseinfostatus advancedCommercePriceIncreaseInfoStatus}
     **/
    status?: AdvancedCommercePriceIncreaseInfoStatus | string;
}
export declare class AdvancedCommercePriceIncreaseInfoValidator implements Validator<AdvancedCommercePriceIncreaseInfo> {
    static readonly statusValidator: AdvancedCommercePriceIncreaseInfoStatusValidator;
    validate(obj: any): obj is AdvancedCommercePriceIncreaseInfo;
}
