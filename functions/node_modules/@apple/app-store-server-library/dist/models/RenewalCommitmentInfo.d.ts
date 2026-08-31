import { AutoRenewStatus, AutoRenewStatusValidator } from "./AutoRenewStatus";
import { RenewalBillingPlanType, RenewalBillingPlanTypeValidator } from "./RenewalBillingPlanType";
import { Validator } from "./Validator";
/**
 * {@link https://developer.apple.com/documentation/appstoreserverapi/renewalcommitmentinfo RenewalCommitmentInfo}
 */
export interface RenewalCommitmentInfo {
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/commitmentautorenewproductid commitmentAutoRenewProductId}
     **/
    commitmentAutoRenewProductId?: string;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/commitmentautorenewstatus commitmentAutoRenewStatus}
     **/
    commitmentAutoRenewStatus?: AutoRenewStatus | number;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/commitmentrenewalbillingplantype commitmentRenewalBillingPlanType}
     **/
    commitmentRenewalBillingPlanType?: RenewalBillingPlanType | string;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/commitmentrenewaldate commitmentRenewalDate}
     **/
    commitmentRenewalDate?: number;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/commitmentrenewalprice commitmentRenewalPrice}
     **/
    commitmentRenewalPrice?: number;
}
export declare class RenewalCommitmentInfoValidator implements Validator<RenewalCommitmentInfo> {
    static readonly autoRenewStatusValidator: AutoRenewStatusValidator;
    static readonly renewalBillingPlanTypeValidator: RenewalBillingPlanTypeValidator;
    validate(obj: any): obj is RenewalCommitmentInfo;
}
