import { Validator } from "./Validator";
/**
 * The payload data that contains an external purchase token.
 *
 * {@link https://developer.apple.com/documentation/appstoreservernotifications/externalpurchasetoken externalPurchaseToken}
 */
export interface ExternalPurchaseToken {
    /**
     * The field of an external purchase token that uniquely identifies the token.
     *
     * {@link https://developer.apple.com/documentation/appstoreservernotifications/externalpurchaseid externalPurchaseId}
     **/
    externalPurchaseId?: string;
    /**
     * The field of an external purchase token that contains the UNIX date, in milliseconds, when the system created the token.
     *
     * {@link https://developer.apple.com/documentation/appstoreservernotifications/tokencreationdate tokenCreationDate}
     **/
    tokenCreationDate?: number;
    /**
     * The unique identifier of an app in the App Store.
     *
     * {@link https://developer.apple.com/documentation/appstoreservernotifications/appappleid appAppleId}
     **/
    appAppleId?: number;
    /**
     * The bundle identifier of an app.
     *
     * {@link https://developer.apple.com/documentation/appstoreservernotifications/bundleid bundleId}
     **/
    bundleId?: string;
}
export declare class ExternalPurchaseTokenValidator implements Validator<ExternalPurchaseToken> {
    validate(obj: any): obj is ExternalPurchaseToken;
}
