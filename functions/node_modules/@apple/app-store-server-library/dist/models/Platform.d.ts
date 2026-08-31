import { NumberValidator } from "./Validator";
/**
 * The platform on which the customer consumed the in-app purchase.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/platform platform}
 */
export declare enum Platform {
    UNDECLARED = 0,
    APPLE = 1,
    NON_APPLE = 2
}
export declare class PlatformValidator extends NumberValidator {
}
