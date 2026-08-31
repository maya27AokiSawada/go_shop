import { Environment, EnvironmentValidator } from "./Environment";
import { SubscriptionGroupIdentifierItem } from "./SubscriptionGroupIdentifierItem";
import { Validator } from "./Validator";
/**
 * A response that contains status information for all of a customer’s auto-renewable subscriptions in your app.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/statusresponse StatusResponse}
 */
export interface StatusResponse {
    /**
     * The server environment, sandbox or production, in which the App Store generated the response.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/environment environment}
     **/
    environment?: Environment | string;
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
     * An array of information for auto-renewable subscriptions, including App Store-signed transaction information and App Store-signed renewal information.
     *
     **/
    data?: SubscriptionGroupIdentifierItem[];
}
export declare class StatusResponseValidator implements Validator<StatusResponse> {
    static readonly environmentValidator: EnvironmentValidator;
    validate(obj: any): obj is StatusResponse;
}
