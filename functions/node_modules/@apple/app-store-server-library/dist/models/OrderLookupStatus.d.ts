import { NumberValidator } from "./Validator";
/**
 * A value that indicates whether the order ID in the request is valid for your app.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/orderlookupstatus OrderLookupStatus}
 */
export declare enum OrderLookupStatus {
    VALID = 0,
    INVALID = 1
}
export declare class OrderLookupStatusValidator extends NumberValidator {
}
