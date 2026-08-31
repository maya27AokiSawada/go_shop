import { Environment, EnvironmentValidator } from "./Environment";
import { Validator } from "./Validator";
/**
 * The object that contains the app metadata and signed app transaction information.
 *
 * {@link https://developer.apple.com/documentation/appstoreservernotifications/appdata AppData}
 */
export interface AppData {
    /**
     * The unique identifier of the app that the notification applies to.
     *
     * {@link https://developer.apple.com/documentation/appstoreservernotifications/appappleid appAppleId}
     **/
    appAppleId?: number;
    /**
     * The bundle identifier of the app.
     *
     * {@link https://developer.apple.com/documentation/appstoreservernotifications/bundleid bundleId}
     **/
    bundleId?: string;
    /**
     * The server environment that the notification applies to, either sandbox or production.
     *
     * {@link https://developer.apple.com/documentation/appstoreservernotifications/environment environment}
     **/
    environment?: Environment | string;
    /**
     * App transaction information signed by the App Store, in JSON Web Signature (JWS) format.
     *
     * {@link https://developer.apple.com/documentation/appstoreservernotifications/jwsapptransaction signedAppTransactionInfo}
     **/
    signedAppTransactionInfo?: string;
}
export declare class AppDataValidator implements Validator<AppData> {
    static readonly environmentValidator: EnvironmentValidator;
    validate(obj: any): obj is AppData;
}
