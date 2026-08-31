import { ConsumptionRequestReason, ConsumptionRequestReasonValidator } from "./ConsumptionRequestReason";
import { Environment, EnvironmentValidator } from "./Environment";
import { Status, StatusValidator } from "./Status";
import { Validator } from "./Validator";
/**
 * The app metadata and the signed renewal and transaction information.
 *
 * {@link https://developer.apple.com/documentation/appstoreservernotifications/data data}
 */
export interface Data {
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
     * The version of the build that identifies an iteration of the bundle.
     *
     * {@link https://developer.apple.com/documentation/appstoreservernotifications/bundleversion bundleVersion}
     **/
    bundleVersion?: string;
    /**
     * Transaction information signed by the App Store, in JSON Web Signature (JWS) format.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/jwstransaction JWSTransaction}
     **/
    signedTransactionInfo?: string;
    /**
     * Subscription renewal information, signed by the App Store, in JSON Web Signature (JWS) format.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/jwsrenewalinfo JWSRenewalInfo}
     **/
    signedRenewalInfo?: string;
    /**
     * The status of an auto-renewable subscription as of the signedDate in the responseBodyV2DecodedPayload.
     *
     * {@link https://developer.apple.com/documentation/appstoreservernotifications/status status}
     **/
    status?: Status | number;
    /**
     * The reason the customer requested the refund.
     *
     * {@link https://developer.apple.com/documentation/appstoreservernotifications/consumptionrequestreason consumptionRequestReason}
     **/
    consumptionRequestReason?: ConsumptionRequestReason | string;
}
export declare class DataValidator implements Validator<Data> {
    static readonly environmentValidator: EnvironmentValidator;
    static readonly statusValidator: StatusValidator;
    static readonly consumptionRequestReasonValidator: ConsumptionRequestReasonValidator;
    validate(obj: any): obj is Data;
}
