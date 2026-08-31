import { Environment, EnvironmentValidator } from "./Environment";
import { Validator } from "./Validator";
/**
 * A response that contains the customer’s transaction history for an app.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/historyresponse HistoryResponse}
 */
export interface HistoryResponse {
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
    /**
     * The bundle identifier of an app.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/bundleid bundleId}
     **/
    bundleId?: string;
    /**
     * The unique identifier of an app in the App Store.
     *
     * {@link https://developer.apple.com/documentation/appstoreservernotifications/appappleid appAppleId}
     **/
    appAppleId?: number;
    /**
     * The server environment in which you’re making the request, whether sandbox or production.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/environment environment}
     **/
    environment?: Environment | string;
    /**
     * An array of in-app purchase transactions for the customer, signed by Apple, in JSON Web Signature format.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/jwstransaction JWSTransaction}
     **/
    signedTransactions?: string[];
}
export declare class HistoryResponseValidator implements Validator<HistoryResponse> {
    static readonly environmentValidator: EnvironmentValidator;
    validate(obj: any): obj is HistoryResponse;
}
