import { Status, StatusValidator } from "./Status";
import { Validator } from "./Validator";
/**
 * The most recent App Store-signed transaction information and App Store-signed renewal information for an auto-renewable subscription.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/lasttransactionsitem lastTransactionsItem}
 */
export interface LastTransactionsItem {
    /**
     * The status of the auto-renewable subscription.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/status status}
     **/
    status?: Status | number;
    /**
     * The original transaction identifier of a purchase.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/originaltransactionid originalTransactionId}
     **/
    originalTransactionId?: string;
    /**
     * Transaction information signed by the App Store, in JSON Web Signature (JWS) format.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/jwstransaction JWSTransaction}
     **/
    signedTransactionInfo?: string;
    /**
     * Subscription renewal information, signed by the App Store, in JSON Web Signature (JWS) format.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/jwsrenewalinfo JWSRenewalInfo}
     **/
    signedRenewalInfo?: string;
}
export declare class LastTransactionsItemValidator implements Validator<LastTransactionsItem> {
    static readonly statusValidator: StatusValidator;
    validate(obj: any): obj is LastTransactionsItem;
}
