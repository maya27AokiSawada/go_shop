import { AdvancedCommerceInAppRequest } from '../jws_signature_creator';
import { AdvancedCommerceRequest } from './AdvancedCommerceRequest';
export interface AbstractAdvancedCommerceInAppRequest extends AdvancedCommerceRequest, AdvancedCommerceInAppRequest {
    readonly operation: string;
    readonly version: string;
}
