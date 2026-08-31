import { Validator } from "./Validator";
/**
 * A response that contains signed transaction information for a single transaction.
 *
 * {@link https://developer.apple.com/documentation/appstoreservernotifications/transactioninforesponse TransactionInfoResponse}
 */
export interface TransactionInfoResponse {
    /**
     * A customer’s in-app purchase transaction, signed by Apple, in JSON Web Signature (JWS) format.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/jwstransaction JWSTransaction}
     **/
    signedTransactionInfo?: string;
}
export declare class TransactionInfoResponseValidator implements Validator<TransactionInfoResponse> {
    validate(obj: any): obj is TransactionInfoResponse;
}
