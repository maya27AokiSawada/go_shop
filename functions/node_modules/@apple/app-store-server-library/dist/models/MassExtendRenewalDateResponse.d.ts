import { Validator } from "./Validator";
/**
 * A response that indicates the server successfully received the subscription-renewal-date extension request.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/massextendrenewaldateresponse MassExtendRenewalDateResponse}
 */
export interface MassExtendRenewalDateResponse {
    /**
     * A string that contains a unique identifier you provide to track each subscription-renewal-date extension request.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/requestidentifier requestIdentifier}
     **/
    requestIdentifier?: string;
}
export declare class MassExtendRenewalDateResponseValidator implements Validator<MassExtendRenewalDateResponse> {
    validate(obj: any): obj is MassExtendRenewalDateResponse;
}
