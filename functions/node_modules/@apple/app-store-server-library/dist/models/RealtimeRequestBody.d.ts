import { Validator } from "./Validator";
/**
 * The request body the App Store server sends to your Get Retention Message endpoint.
 *
 * {@link https://developer.apple.com/documentation/retentionmessaging/realtimerequestbody RealtimeRequestBody}
 */
export interface RealtimeRequestBody {
    /**
     * The payload in JSON Web Signature (JWS) format, signed by the App Store.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/signedpayload signedPayload}
     **/
    signedPayload?: string;
}
export declare class RealtimeRequestBodyValidator implements Validator<RealtimeRequestBody> {
    validate(obj: any): obj is RealtimeRequestBody;
}
