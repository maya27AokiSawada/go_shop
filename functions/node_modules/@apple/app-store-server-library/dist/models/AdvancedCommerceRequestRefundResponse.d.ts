import { AbstractAdvancedCommerceResponse } from './AbstractAdvancedCommerceResponse';
import { Validator } from './Validator';
/**
 * The response body for a transaction refund request.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/requestrefundresponse RequestRefundResponse}
 */
export interface AdvancedCommerceRequestRefundResponse extends AbstractAdvancedCommerceResponse {
}
export declare class AdvancedCommerceRequestRefundResponseValidator implements Validator<AdvancedCommerceRequestRefundResponse> {
    validate(obj: any): obj is AdvancedCommerceRequestRefundResponse;
}
