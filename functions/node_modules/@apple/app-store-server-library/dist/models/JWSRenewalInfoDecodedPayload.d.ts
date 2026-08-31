import { AdvancedCommerceRenewalInfo, AdvancedCommerceRenewalInfoValidator } from "./AdvancedCommerceRenewalInfo";
import { AutoRenewStatus, AutoRenewStatusValidator } from "./AutoRenewStatus";
import { DecodedSignedData } from "./DecodedSignedData";
import { Environment, EnvironmentValidator } from "./Environment";
import { ExpirationIntent, ExpirationIntentValidator } from "./ExpirationIntent";
import { OfferDiscountType, OfferDiscountTypeValidator } from "./OfferDiscountType";
import { OfferType, OfferTypeValidator } from "./OfferType";
import { PriceIncreaseStatus, PriceIncreaseStatusValidator } from "./PriceIncreaseStatus";
import { RenewalBillingPlanType, RenewalBillingPlanTypeValidator } from "./RenewalBillingPlanType";
import { RenewalCommitmentInfo, RenewalCommitmentInfoValidator } from "./RenewalCommitmentInfo";
import { Validator } from "./Validator";
/**
 * A decoded payload containing subscription renewal information for an auto-renewable subscription.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/jwsrenewalinfodecodedpayload JWSRenewalInfoDecodedPayload}
 */
export interface JWSRenewalInfoDecodedPayload extends DecodedSignedData {
    /**
     * The reason the subscription expired.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/expirationintent expirationIntent}
     **/
    expirationIntent?: ExpirationIntent | number;
    /**
     * The original transaction identifier of a purchase.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/originaltransactionid originalTransactionId}
     **/
    originalTransactionId?: string;
    /**
     * The product identifier of the product that will renew at the next billing period.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/autorenewproductid autoRenewProductId}
     **/
    autoRenewProductId?: string;
    /**
     * The unique identifier for the product, that you create in App Store Connect.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/productid productId}
     **/
    productId?: string;
    /**
     * The renewal status of the auto-renewable subscription.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/autorenewstatus autoRenewStatus}
     **/
    autoRenewStatus?: AutoRenewStatus | number;
    /**
     * A Boolean value that indicates whether the App Store is attempting to automatically renew an expired subscription.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/isinbillingretryperiod isInBillingRetryPeriod}
     **/
    isInBillingRetryPeriod?: boolean;
    /**
     * The status that indicates whether the auto-renewable subscription is subject to a price increase.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/priceincreasestatus priceIncreaseStatus}
     **/
    priceIncreaseStatus?: PriceIncreaseStatus | number;
    /**
     * The time when the billing grace period for subscription renewals expires.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/graceperiodexpiresdate gracePeriodExpiresDate}
     **/
    gracePeriodExpiresDate?: number;
    /**
     * The type of subscription offer.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/offertype offerType}
     **/
    offerType?: OfferType | number;
    /**
     * The offer code or the promotional offer identifier.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/offeridentifier offerIdentifier}
     **/
    offerIdentifier?: string;
    /**
     * The UNIX time, in milliseconds, that the App Store signed the JSON Web Signature data.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/signeddate signedDate}
     **/
    signedDate?: number;
    /**
     * The server environment, either sandbox or production.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/environment environment}
     **/
    environment?: Environment | string;
    /**
     * The earliest start date of a subscription in a series of auto-renewable subscription purchases that ignores all lapses of paid service shorter than 60 days.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/recentsubscriptionstartdate recentSubscriptionStartDate}
     **/
    recentSubscriptionStartDate?: number;
    /**
     * The UNIX time, in milliseconds, when the most recent auto-renewable subscription purchase expires.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/renewaldate renewalDate}
     **/
    renewalDate?: number;
    /**
     * The currency code for the renewalPrice of the subscription.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/currency currency}
     **/
    currency?: string;
    /**
     * The renewal price, in milliunits, of the auto-renewable subscription that renews at the next billing period.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/renewalprice renewalPrice}
     **/
    renewalPrice?: number;
    /**
     * The payment mode you configure for the offer.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/offerdiscounttype offerDiscountType}
     **/
    offerDiscountType?: OfferDiscountType | string;
    /**
     * An array of win-back offer identifiers that a customer is eligible to redeem, which sorts the identifiers to present the better offers first.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/eligiblewinbackofferids eligibleWinBackOfferIds}
     **/
    eligibleWinBackOfferIds?: string[];
    /**
     * The UUID that an app optionally generates to map a customer’s in-app purchase with its resulting App Store transaction.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/appaccounttoken appAccountToken}
     **/
    appAccountToken?: string;
    /**
     * The unique identifier of the app download transaction.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/appTransactionId appTransactionId}
     **/
    appTransactionId?: string;
    /**
     * The duration of the offer.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/offerPeriod offerPeriod}
     **/
    offerPeriod?: string;
    /**
     * Renewal information that is present only for Advanced Commerce SKUs.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercerenewalinfo advancedCommerceRenewalInfo}
     **/
    advancedCommerceInfo?: AdvancedCommerceRenewalInfo;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/renewalcommitmentinfo RenewalCommitmentInfo}
     **/
    commitmentInfo?: RenewalCommitmentInfo;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/renewalbillingplantype renewalBillingPlanType}
     **/
    renewalBillingPlanType?: RenewalBillingPlanType | string;
}
export declare class JWSRenewalInfoDecodedPayloadValidator implements Validator<JWSRenewalInfoDecodedPayload> {
    static readonly environmentValidator: EnvironmentValidator;
    static readonly offerTypeValidator: OfferTypeValidator;
    static readonly priceIncreaseStatusValidator: PriceIncreaseStatusValidator;
    static readonly autoRenewStatusValidator: AutoRenewStatusValidator;
    static readonly expirationIntentValidator: ExpirationIntentValidator;
    static readonly offerDiscountTypeValidator: OfferDiscountTypeValidator;
    static readonly renewalBillingPlanTypeValidator: RenewalBillingPlanTypeValidator;
    static readonly advancedCommerceRenewalInfoValidator: AdvancedCommerceRenewalInfoValidator;
    static readonly renewalCommitmentInfoValidator: RenewalCommitmentInfoValidator;
    validate(obj: any): obj is JWSRenewalInfoDecodedPayload;
}
