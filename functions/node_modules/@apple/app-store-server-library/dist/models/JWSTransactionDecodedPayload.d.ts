import { AdvancedCommerceTransactionInfo, AdvancedCommerceTransactionInfoValidator } from "./AdvancedCommerceTransactionInfo";
import { BillingPlanType, BillingPlanTypeValidator } from "./BillingPlanType";
import { DecodedSignedData } from "./DecodedSignedData";
import { Environment, EnvironmentValidator } from "./Environment";
import { InAppOwnershipType, InAppOwnershipTypeValidator } from "./InAppOwnershipType";
import { OfferDiscountType, OfferDiscountTypeValidator } from "./OfferDiscountType";
import { OfferType, OfferTypeValidator } from "./OfferType";
import { RevocationType, RevocationTypeValidator } from "./RevocationType";
import { RevocationReason, RevocationReasonValidator } from "./RevocationReason";
import { TransactionCommitmentInfo, TransactionCommitmentInfoValidator } from "./TransactionCommitmentInfo";
import { TransactionReason, TransactionReasonValidator } from "./TransactionReason";
import { Type, TypeValidator } from "./Type";
import { Validator } from "./Validator";
/**
 * A decoded payload containing transaction information.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/jwstransactiondecodedpayload JWSTransactionDecodedPayload}
 */
export interface JWSTransactionDecodedPayload extends DecodedSignedData {
    /**
     * The original transaction identifier of a purchase.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/originaltransactionid originalTransactionId}
     **/
    originalTransactionId?: string;
    /**
     * The unique identifier for a transaction such as an in-app purchase, restored in-app purchase, or subscription renewal.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/transactionid transactionId}
     **/
    transactionId?: string;
    /**
     * The unique identifier of subscription-purchase events across devices, including renewals.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/weborderlineitemid webOrderLineItemId}
     **/
    webOrderLineItemId?: string;
    /**
     * The bundle identifier of an app.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/bundleid bundleId}
     **/
    bundleId?: string;
    /**
     * The unique identifier for the product, that you create in App Store Connect.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/productid productId}
     **/
    productId?: string;
    /**
     * The identifier of the subscription group that the subscription belongs to.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/subscriptiongroupidentifier subscriptionGroupIdentifier}
     **/
    subscriptionGroupIdentifier?: string;
    /**
     * The time that the App Store charged the user’s account for an in-app purchase, a restored in-app purchase, a subscription, or a subscription renewal after a lapse.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/purchasedate purchaseDate}
     **/
    purchaseDate?: number;
    /**
     * The purchase date of the transaction associated with the original transaction identifier.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/originalpurchasedate originalPurchaseDate}
     **/
    originalPurchaseDate?: number;
    /**
     * The UNIX time, in milliseconds, an auto-renewable subscription expires or renews.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/expiresdate expiresDate}
     **/
    expiresDate?: number;
    /**
     * The number of consumable products purchased.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/quantity quantity}
     **/
    quantity?: number;
    /**
     * The type of the in-app purchase.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/type type}
     **/
    type?: Type | string;
    /**
     * The UUID that an app optionally generates to map a customer’s in-app purchase with its resulting App Store transaction.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/appaccounttoken appAccountToken}
     **/
    appAccountToken?: string;
    /**
     * A string that describes whether the transaction was purchased by the user, or is available to them through Family Sharing.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/inappownershiptype inAppOwnershipType}
     **/
    inAppOwnershipType?: InAppOwnershipType | string;
    /**
     * The UNIX time, in milliseconds, that the App Store signed the JSON Web Signature data.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/signeddate signedDate}
     **/
    signedDate?: number;
    /**
     * The reason that the App Store refunded the transaction or revoked it from Family Sharing.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/revocationreason revocationReason}
     **/
    revocationReason?: RevocationReason | number;
    /**
     * The UNIX time, in milliseconds, that Apple Support refunded a transaction.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/revocationdate revocationDate}
     **/
    revocationDate?: number;
    /**
     * The Boolean value that indicates whether the user upgraded to another subscription.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/isupgraded isUpgraded}
     **/
    isUpgraded?: boolean;
    /**
     * A value that represents the promotional offer type.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/offertype offerType}
     **/
    offerType?: OfferType | number;
    /**
     * The identifier that contains the offer code or the promotional offer identifier.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/offeridentifier offerIdentifier}
     **/
    offerIdentifier?: string;
    /**
     * The server environment, either sandbox or production.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/environment environment}
     **/
    environment?: Environment | string;
    /**
     * The three-letter code that represents the country or region associated with the App Store storefront for the purchase.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/storefront storefront}
     **/
    storefront?: string;
    /**
     * An Apple-defined value that uniquely identifies the App Store storefront associated with the purchase.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/storefrontid storefrontId}
     **/
    storefrontId?: string;
    /**
     * The reason for the purchase transaction, which indicates whether it’s a customer’s purchase or a renewal for an auto-renewable subscription that the system initates.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/transactionreason transactionReason}
     **/
    transactionReason?: TransactionReason | string;
    /**
     * The three-letter ISO 4217 currency code for the price of the product.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/currency currency}
     **/
    currency?: string;
    /**
     * The price, in milliunits, of the in-app purchase or subscription offer that you configured in App Store Connect.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/price price}
     **/
    price?: number;
    /**
     * The payment mode you configure for the offer.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/offerdiscounttype offerDiscountType}
     **/
    offerDiscountType?: OfferDiscountType | string;
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
     * The type of the refund or revocation that applies to the transaction.
     *
     * {@link https://developer.apple.com/documentation/appstoreservernotifications/revocationtype revocationType}
     **/
    revocationType?: RevocationType | string;
    /**
     * The percentage, in milliunits, of the transaction that the App Store has refunded or revoked.
     *
     * {@link https://developer.apple.com/documentation/appstoreservernotifications/revocationpercentage revocationPercentage}
     **/
    revocationPercentage?: number;
    /**
     * Transaction information that is present only for Advanced Commerce SKUs.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/advancedcommercetransactioninfo advancedCommerceTransactionInfo}
     **/
    advancedCommerceInfo?: AdvancedCommerceTransactionInfo;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/billingplantype billingPlanType}
     **/
    billingPlanType?: BillingPlanType | string;
    /**
     * {@link https://developer.apple.com/documentation/appstoreserverapi/transactioncommitmentinfo TransactionCommitmentInfo}
     **/
    commitmentInfo?: TransactionCommitmentInfo;
}
export declare class JWSTransactionDecodedPayloadValidator implements Validator<JWSTransactionDecodedPayload> {
    static readonly environmentValidator: EnvironmentValidator;
    static readonly offerTypeValidator: OfferTypeValidator;
    static readonly revocationReasonValidator: RevocationReasonValidator;
    static readonly revocationTypeValidator: RevocationTypeValidator;
    static readonly inAppOwnershipTypeValidator: InAppOwnershipTypeValidator;
    static readonly typeValidator: TypeValidator;
    static readonly transactionReasonValidator: TransactionReasonValidator;
    static readonly offerDiscountTypeValidator: OfferDiscountTypeValidator;
    static readonly billingPlanTypeValidator: BillingPlanTypeValidator;
    static readonly advancedCommerceTransactionInfoValidator: AdvancedCommerceTransactionInfoValidator;
    static readonly transactionCommitmentInfoValidator: TransactionCommitmentInfoValidator;
    validate(obj: any): obj is JWSTransactionDecodedPayload;
}
