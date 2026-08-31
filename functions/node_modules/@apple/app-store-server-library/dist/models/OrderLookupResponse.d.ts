import { OrderLookupStatus, OrderLookupStatusValidator } from "./OrderLookupStatus";
import { Validator } from "./Validator";
/**
 * A response that includes the order lookup status and an array of signed transactions for the in-app purchases in the order.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/orderlookupresponse OrderLookupResponse}
 */
export interface OrderLookupResponse {
    /**
     * The status that indicates whether the order ID is valid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/orderlookupstatus OrderLookupStatus}
     **/
    status?: OrderLookupStatus | number;
    /**
     * An array of in-app purchase transactions that are part of order, signed by Apple, in JSON Web Signature format.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/jwstransaction JWSTransaction}
     **/
    signedTransactions?: string[];
}
export declare class OrderLookupResponseValidator implements Validator<OrderLookupResponse> {
    static readonly statusValidator: OrderLookupStatusValidator;
    validate(obj: any): obj is OrderLookupResponse;
}
