import { Validator } from "./Validator";
/**
 * A response that contains an array of signed JSON Web Signature (JWS) refunded transactions, and paging information.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/refundhistoryresponse RefundHistoryResponse}
 */
export interface RefundHistoryResponse {
    /**
     * A list of up to 20 JWS transactions, or an empty array if the customer hasn&#39;t received any refunds in your app. The transactions are sorted in ascending order by revocationDate.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/jwstransaction JWSTransaction}
     **/
    signedTransactions?: string[];
    /**
     * A token you use in a query to request the next set of transactions for the customer.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/revision revision}
     **/
    revision?: string;
    /**
     * A Boolean value indicating whether the App Store has more transaction data.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/hasmore hasMore}
     **/
    hasMore?: boolean;
}
export declare class RefundHistoryResponseValidator implements Validator<RefundHistoryResponse> {
    validate(obj: any): obj is RefundHistoryResponse;
}
