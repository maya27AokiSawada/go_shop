import { AbstractAdvancedCommerceBaseItem } from './AbstractAdvancedCommerceBaseItem';
import { AdvancedCommerceRefundReason, AdvancedCommerceRefundReasonValidator } from './AdvancedCommerceRefundReason';
import { AdvancedCommerceRefundType, AdvancedCommerceRefundTypeValidator } from './AdvancedCommerceRefundType';
import { Validator } from './Validator';
/**
 * Information about the refund request for an item, such as its SKU, the refund amount, reason, and type.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/requestrefunditem RequestRefundItem}
 */
export interface AdvancedCommerceRequestRefundItem extends AbstractAdvancedCommerceBaseItem {
    /**
     * The refund amount you're requesting for the SKU, in milliunits of the currency.
     *
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/refundamount refundAmount}
     **/
    refundAmount?: number;
    /**
     * The reason for the refund request.
     *
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/refundreason refundReason}
     **/
    refundReason: AdvancedCommerceRefundReason | string;
    /**
     * The type of refund requested.
     **/
    refundType: AdvancedCommerceRefundType | string;
    revoke: boolean;
}
export declare class AdvancedCommerceRequestRefundItemValidator implements Validator<AdvancedCommerceRequestRefundItem> {
    static readonly refundReasonValidator: AdvancedCommerceRefundReasonValidator;
    static readonly refundTypeValidator: AdvancedCommerceRefundTypeValidator;
    validate(obj: any): obj is AdvancedCommerceRequestRefundItem;
}
