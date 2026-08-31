import { Environment, EnvironmentValidator } from "./Environment";
import { Validator } from "./Validator";
/**
 * The payload data for a subscription-renewal-date extension notification.
 *
 * {@link https://developer.apple.com/documentation/appstoreservernotifications/summary summary}
 */
export interface Summary {
    /**
     * The server environment that the notification applies to, either sandbox or production.
     *
     * {@link https://developer.apple.com/documentation/appstoreservernotifications/environment environment}
     **/
    environment?: Environment | string;
    /**
     * The unique identifier of an app in the App Store.
     *
     * {@link https://developer.apple.com/documentation/appstoreservernotifications/appappleid appAppleId}
     **/
    appAppleId?: number;
    /**
     * The bundle identifier of an app.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/bundleid bundleId}
     **/
    bundleId?: string;
    /**
     * The unique identifier for the product, that you create in App Store Connect.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/productid productId}
     **/
    productId?: string;
    /**
     * A string that contains a unique identifier you provide to track each subscription-renewal-date extension request.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/requestidentifier requestIdentifier}
     **/
    requestIdentifier?: string;
    /**
     * A list of storefront country codes you provide to limit the storefronts for a subscription-renewal-date extension.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/storefrontcountrycodes storefrontCountryCodes}
     **/
    storefrontCountryCodes?: string[];
    /**
     * The count of subscriptions that successfully receive a subscription-renewal-date extension.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/succeededcount succeededCount}
     **/
    succeededCount?: number;
    /**
     * The count of subscriptions that fail to receive a subscription-renewal-date extension.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/failedcount failedCount}
     **/
    failedCount?: number;
}
export declare class SummaryValidator implements Validator<Summary> {
    static readonly environmentValidator: EnvironmentValidator;
    validate(obj: any): obj is Summary;
}
