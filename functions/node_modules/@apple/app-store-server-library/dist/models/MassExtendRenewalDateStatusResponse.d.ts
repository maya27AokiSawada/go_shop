import { Validator } from "./Validator";
/**
 * A response that indicates the current status of a request to extend the subscription renewal date to all eligible subscribers.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/massextendrenewaldatestatusresponse MassExtendRenewalDateStatusResponse}
 */
export interface MassExtendRenewalDateStatusResponse {
    /**
     * A string that contains a unique identifier you provide to track each subscription-renewal-date extension request.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/requestidentifier requestIdentifier}
     **/
    requestIdentifier?: string;
    /**
     * A Boolean value that indicates whether the App Store completed the request to extend a subscription renewal date to active subscribers.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/complete complete}
     **/
    complete?: boolean;
    /**
     * The UNIX time, in milliseconds, that the App Store completes a request to extend a subscription renewal date for eligible subscribers.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/completedate completeDate}
     **/
    completeDate?: number;
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
export declare class MassExtendRenewalDateStatusResponseValidator implements Validator<MassExtendRenewalDateStatusResponse> {
    validate(obj: any): obj is MassExtendRenewalDateStatusResponse;
}
