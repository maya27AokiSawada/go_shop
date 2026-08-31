import { Validator } from "./Validator";
/**
 * A response that contains signed app transaction information for a customer.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/apptransactioninforesponse AppTransactionInfoResponse}
 */
export interface AppTransactionInfoResponse {
    /**
     * A customer’s app transaction information, signed by Apple, in JSON Web Signature (JWS) format.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/jwsapptransaction JWSAppTransaction}
     **/
    signedAppTransactionInfo?: string;
}
export declare class AppTransactionInfoResponseValidator implements Validator<AppTransactionInfoResponse> {
    validate(obj: any): obj is AppTransactionInfoResponse;
}
