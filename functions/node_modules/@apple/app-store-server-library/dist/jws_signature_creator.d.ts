declare class BaseSignatureCreator {
    private audience;
    private signingKey;
    private keyId;
    private issuerId;
    private bundleId;
    constructor(audience: string, signingKey: string, keyId: string, issuerId: string, bundleId: string);
    protected internalCreateSignature(featureSpecificClaims: {
        [key: string]: any;
    }): string;
}
export declare class PromotionalOfferV2SignatureCreator extends BaseSignatureCreator {
    /**
     * Create a PromotionalOfferV2SignatureCreator
     *
     * @param signingKey Your private key downloaded from App Store Connect
     * @param keyId Your private key ID from App Store Connect
     * @param issuerId Your issuer ID from the Keys page in App Store Connect
     * @param bundleId Your app's bundle ID
     */
    constructor(signingKey: string, keyId: string, issuerId: string, bundleId: string);
    /**
     * Create a promotional offer V2 signature.
     *
     * @param productId The unique identifier of the product
     * @param offerIdentifier The promotional offer identifier that you set up in App Store Connect
     * @param transactionId The unique identifier of any transaction that belongs to the customer. You can use the customer's appTransactionId, even for customers who haven't made any In-App Purchases in your app. This field is optional, but recommended.
     * @return The signed JWS.
     * {@link https://developer.apple.com/documentation/storekit/generating-jws-to-sign-app-store-requests Generating JWS to sign App Store requests}
     */
    createSignature(productId: string, offerIdentifier: string, transactionId?: string | undefined): string;
}
export declare class IntroductoryOfferEligibilitySignatureCreator extends BaseSignatureCreator {
    /**
     * Create a IntroductoryOfferEligibilitySignatureCreator
     *
     * @param signingKey Your private key downloaded from App Store Connect
     * @param keyId Your private key ID from App Store Connect
     * @param issuerId Your issuer ID from the Keys page in App Store Connect
     * @param bundleId Your app's bundle ID
     */
    constructor(signingKey: string, keyId: string, issuerId: string, bundleId: string);
    /**
     * Create an introductory offer eligibility signature.
     *
     * @param productId The unique identifier of the product
     * @param allowIntroductoryOffer A boolean value that determines whether the customer is eligible for an introductory offer
     * @param transactionId The unique identifier of any transaction that belongs to the customer. You can use the customer's appTransactionId, even for customers who haven't made any In-App Purchases in your app.
     * @return The signed JWS.
     * {@link https://developer.apple.com/documentation/storekit/generating-jws-to-sign-app-store-requests Generating JWS to sign App Store requests}
     */
    createSignature(productId: string, allowIntroductoryOffer: boolean, transactionId: string): string;
}
export interface AdvancedCommerceInAppRequest {
}
export declare class AdvancedCommerceInAppSignatureCreator extends BaseSignatureCreator {
    /**
     * Create a AdvancedCommerceInAppSignatureCreator
     *
     * @param signingKey Your private key downloaded from App Store Connect
     * @param keyId Your private key ID from App Store Connect
     * @param issuerId Your issuer ID from the Keys page in App Store Connect
     * @param bundleId Your app's bundle ID
     */
    constructor(signingKey: string, keyId: string, issuerId: string, bundleId: string);
    /**
     * Create an Advanced Commerce in-app signed request.
     *
     * @param AdvancedCommerceInAppRequest The request to be signed.
     * @return The signed JWS.
     * {@link https://developer.apple.com/documentation/storekit/generating-jws-to-sign-app-store-requests Generating JWS to sign App Store requests}
     */
    createSignature(AdvancedCommerceInAppRequest: AdvancedCommerceInAppRequest): string;
}
export {};
