import { AdvancedCommerceOfferPeriod, AdvancedCommerceOfferPeriodValidator } from './AdvancedCommerceOfferPeriod';
import { AdvancedCommerceOfferReason, AdvancedCommerceOfferReasonValidator } from './AdvancedCommerceOfferReason';
import { Validator } from './Validator';
/**
 * A discount offer for an auto-renewable subscription.
 *
 * {@link https://developer.apple.com/documentation/advancedcommerceapi/offer Offer}
 */
export interface AdvancedCommerceOffer {
    /**
     * The period of the offer.
     **/
    period: AdvancedCommerceOfferPeriod | string;
    /**
     * The number of periods the offer is active.
     **/
    periodCount: number;
    /**
     * The offer price, in milliunits.
     *
     * {@link https://developer.apple.com/documentation/advancedcommerceapi/price Price}
     **/
    price: number;
    /**
     * The reason for the offer.
     **/
    reason: AdvancedCommerceOfferReason | string;
}
export declare class AdvancedCommerceOfferValidator implements Validator<AdvancedCommerceOffer> {
    static readonly periodValidator: AdvancedCommerceOfferPeriodValidator;
    static readonly reasonValidator: AdvancedCommerceOfferReasonValidator;
    validate(obj: any): obj is AdvancedCommerceOffer;
}
