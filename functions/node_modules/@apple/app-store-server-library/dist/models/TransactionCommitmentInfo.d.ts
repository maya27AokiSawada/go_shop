import { Validator } from "./Validator";
/**
 * {@link https://developer.apple.com/documentation/appstoreserverapi/transactioncommitmentinfo TransactionCommitmentInfo}
 */
export interface TransactionCommitmentInfo {
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/billingperiodnumber billingPeriodNumber}
     **/
    billingPeriodNumber?: number;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/commitmentexpiresdate commitmentExpiresDate}
     **/
    commitmentExpiresDate?: number;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/commitmentprice commitmentPrice}
     **/
    commitmentPrice?: number;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/totalbillingperiods totalBillingPeriods}
     **/
    totalBillingPeriods?: number;
}
export declare class TransactionCommitmentInfoValidator implements Validator<TransactionCommitmentInfo> {
    validate(obj: any): obj is TransactionCommitmentInfo;
}
