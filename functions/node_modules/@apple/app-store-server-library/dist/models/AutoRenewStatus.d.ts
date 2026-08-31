import { NumberValidator } from "./Validator";
/**
 * The renewal status for an auto-renewable subscription.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/autorenewstatus autoRenewStatus}
 */
export declare enum AutoRenewStatus {
    OFF = 0,
    ON = 1
}
export declare class AutoRenewStatusValidator extends NumberValidator {
}
