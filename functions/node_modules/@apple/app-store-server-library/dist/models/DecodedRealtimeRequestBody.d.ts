import { DecodedSignedData } from "./DecodedSignedData";
import { Environment, EnvironmentValidator } from "./Environment";
import { Validator } from "./Validator";
/**
 * The decoded request body the App Store sends to your server to request a real-time retention message.
 *
 * {@link https://developer.apple.com/documentation/retentionmessaging/decodedrealtimerequestbody DecodedRealtimeRequestBody}
 */
export interface DecodedRealtimeRequestBody extends DecodedSignedData {
    /**
     * The original transaction identifier of the customer's subscription.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/originaltransactionid originalTransactionId}
     **/
    originalTransactionId: string;
    /**
     * The unique identifier of the app in the App Store.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/appappleid appAppleId}
     **/
    appAppleId: number;
    /**
     * The unique identifier of the auto-renewable subscription.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/productid productId}
     **/
    productId: string;
    /**
     * The device's locale.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/locale locale}
     **/
    userLocale: string;
    /**
     * A UUID the App Store server creates to uniquely identify each request.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/requestidentifier requestIdentifier}
     **/
    requestIdentifier: string;
    /**
     * The UNIX time, in milliseconds, that the App Store signed the JSON Web Signature (JWS) data.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/signeddate signedDate}
     **/
    signedDate: number;
    /**
     * The server environment, either sandbox or production.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/environment environment}
     **/
    environment: Environment | string;
}
export declare class DecodedRealtimeRequestBodyValidator implements Validator<DecodedRealtimeRequestBody> {
    static readonly environmentValidator: EnvironmentValidator;
    validate(obj: any): obj is DecodedRealtimeRequestBody;
}
