import { Environment, EnvironmentValidator } from "./Environment";
import { PurchasePlatform, PurchasePlatformValidator } from "./PurchasePlatform";
import { Validator } from "./Validator";
/**
 * A decoded payload that contains app transaction information.
 *
 * {@link https://developer.apple.com/documentation/storekit/apptransaction AppTransaction}
 * {@link https://developer.apple.com/documentation/appstoreserverapi/jwsapptransactiondecodedpayload JWSAppTransactionDecodedPayload}
 */
export interface AppTransaction {
    /**
     * The date that the App Store signed the JWS app transaction.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/environment environment}
     */
    receiptType?: Environment | string;
    /**
     * The unique identifier the App Store uses to identify the app.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/appappleid appId}
     */
    appAppleId?: number;
    /**
     * The bundle identifier that the app transaction applies to.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/bundleid bundleId}
     */
    bundleId?: string;
    /**
     * The app version that the app transaction applies to.
     *
     * {@link https://developer.apple.com/documentation/storekit/apptransaction/appversion appVersion}
     */
    applicationVersion?: string;
    /**
     * The version external identifier of the app
     *
     * {@link https://developer.apple.com/documentation/storekit/apptransaction/appversionid appVersionID}
     */
    versionExternalIdentifier?: number;
    /**
     * The date that the App Store signed the JWS app transaction.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/receiptcreationdate receiptCreationDate}
     */
    receiptCreationDate?: number;
    /**
     * The date the customer originally purchased the app from the App Store.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/originalpurchasedate originalPurchaseDate}
     */
    originalPurchaseDate?: number;
    /**
     * The app version that the user originally purchased from the App Store.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/originalapplicationversion originalAppVersion}
     */
    originalApplicationVersion?: string;
    /**
    The Base64 device verification value to use to verify whether the app transaction belongs to the device.

    {@link https://developer.apple.com/documentation/storekit/apptransaction/deviceverification deviceVerification}
    */
    deviceVerification?: string;
    /**
     * The UUID used to compute the device verification value.
     *
     * {@link https://developer.apple.com/documentation/storekit/apptransaction/deviceverificationnonce deviceVerificationNonce}
    */
    deviceVerificationNonce?: string;
    /**
     * The date the customer placed an order for the app before it’s available in the App Store.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/preorderdate preorderDate}
    */
    preorderDate?: number;
    /**
     * The unique identifier of the app download transaction.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/apptransactionid appTransactionId}
    */
    appTransactionId?: string;
    /**
     * The platform on which the customer originally purchased the app.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/originalplatform originalPlatform}
    */
    originalPlatform?: PurchasePlatform | string;
}
export declare class AppTransactionValidator implements Validator<AppTransaction> {
    static readonly environmentValidator: EnvironmentValidator;
    static readonly originalPlatformValidator: PurchasePlatformValidator;
    validate(obj: any): obj is AppTransaction;
}
