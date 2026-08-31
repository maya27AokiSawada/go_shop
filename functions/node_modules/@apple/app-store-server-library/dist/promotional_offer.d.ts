export declare class PromotionalOfferSignatureCreator {
    private signingKey;
    private keyId;
    private bundleId;
    constructor(signingKey: string, keyId: string, bundleId: string);
    /**
     * Create a promotional offer signature
     *
     * {@link https://developer.apple.com/documentation/storekit/in-app_purchase/original_api_for_in-app_purchase/subscriptions_and_offers/generating_a_signature_for_promotional_offers Generating a signature for promotional offers}
     * @param productIdentifier The subscription product identifier
     * @param subscriptionOfferID The subscription discount identifier
     * @param appAccountToken An optional string value that you define; may be an empty string
     * @param nonce A one-time UUID value that your server generates. Generate a new nonce for every signature.
     * @param timestamp A timestamp your server generates in UNIX time format, in milliseconds. The timestamp keeps the offer active for 24 hours.
     * @return The Base64 encoded signature
     */
    createSignature(productIdentifier: string, subscriptionOfferID: string, appAccountToken: string, nonce: string, timestamp: number): string;
}
