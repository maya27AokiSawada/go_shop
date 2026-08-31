import { KeyObject, X509Certificate } from 'crypto';
import { Environment } from './models/Environment';
import { JWSTransactionDecodedPayload } from './models/JWSTransactionDecodedPayload';
import { ResponseBodyV2DecodedPayload } from './models/ResponseBodyV2DecodedPayload';
import { JWSRenewalInfoDecodedPayload } from './models/JWSRenewalInfoDecodedPayload';
import { DecodedRealtimeRequestBody } from './models/DecodedRealtimeRequestBody';
import { Validator } from './models/Validator';
import { AppTransaction } from './models/AppTransaction';
declare class CacheValue {
    publicKey: KeyObject;
    cacheExpiry: number;
    constructor(publicKey: KeyObject, cacheExpiry: number);
}
/**
 * A class providing utility methods for verifying and decoding App Store signed data.
 *
 * Example Usage:
 * ```ts
 * const verifier = new SignedDataVerifier([appleRoot, appleRoot2], true, Environment.SANDBOX, "com.example")
 *
 * try {
 *     const decodedNotification = verifier.verifyAndDecodeNotification("ey...")
 *     console.log(decodedNotification)
 * } catch (e) {
 *     console.error(e)
 * }
 * ```
 */
export declare class SignedDataVerifier {
    private JWSRenewalInfoDecodedPayloadValidator;
    private JWSTransactionDecodedPayloadValidator;
    private responseBodyV2DecodedPayloadValidator;
    private appTransactionValidator;
    private decodedRealtimeRequestBodyValidator;
    protected rootCertificates: X509Certificate[];
    protected enableOnlineChecks: boolean;
    protected bundleId: string;
    protected appAppleId?: number;
    protected environment: Environment;
    protected verifiedPublicKeyCache: {
        [index: string]: CacheValue;
    };
    /**
     *
     * @param appleRootCertificates A list of DER-encoded root certificates
     * @param enableOnlineChecks Whether to enable revocation checking and check expiration using the current date
     * @param environment The App Store environment to target for checks
     * @param bundleId The app's bundle identifier
     * @param appAppleId The app's identifier, omitted in the sandbox environment
     */
    constructor(appleRootCertificates: Buffer[], enableOnlineChecks: boolean, environment: Environment, bundleId: string, appAppleId?: number);
    /**
     * Verifies and decodes a signedTransaction obtained from the App Store Server API, an App Store Server Notification, or from a device
     * See {@link https://developer.apple.com/documentation/appstoreserverapi/jwstransaction JWSTransaction}
     *
     * @param signedTransaction The signedTransaction field
     * @return The decoded transaction info after verification
     * @throws VerificationException Thrown if the data could not be verified
     */
    verifyAndDecodeTransaction(signedTransactionInfo: string): Promise<JWSTransactionDecodedPayload>;
    /**
     * Verifies and decodes a signedRenewalInfo obtained from the App Store Server API, an App Store Server Notification, or from a device
     * See {@link https://developer.apple.com/documentation/appstoreserverapi/jwsrenewalinfo JWSRenewalInfo}
     *
     * @param signedRenewalInfo The signedRenewalInfo field
     * @return The decoded renewal info after verification
     * @throws VerificationException Thrown if the data could not be verified
     */
    verifyAndDecodeRenewalInfo(signedRenewalInfo: string): Promise<JWSRenewalInfoDecodedPayload>;
    /**
     * Verifies and decodes an App Store Server Notification signedPayload
     * See {@link https://developer.apple.com/documentation/appstoreservernotifications/signedpayload signedPayload}
     *
     * @param signedPayload The payload received by your server
     * @return The decoded payload after verification
     * @throws VerificationException Thrown if the data could not be verified
     */
    verifyAndDecodeNotification(signedPayload: string): Promise<ResponseBodyV2DecodedPayload>;
    protected verifyNotification(bundleId?: string, appAppleId?: number, environment?: string): void;
    /**
     * Verifies and decodes a signed AppTransaction
     * See {@link https://developer.apple.com/documentation/storekit/apptransaction AppTransaction}
     *
     * @param signedAppTransaction The signed AppTransaction
     * @returns The decoded AppTransaction after validation
     * @throws VerificationException Thrown if the data could not be verified
     */
    verifyAndDecodeAppTransaction(signedAppTransaction: string): Promise<AppTransaction>;
    /**
     * Verifies and decodes a Retention Messaging API signedPayload
     * See {@link https://developer.apple.com/documentation/retentionmessaging/signedpayload signedPayload}
     *
     * @param signedPayload The payload received by your server
     * @returns The decoded payload after verification
     * @throws VerificationException Thrown if the data could not be verified
     */
    verifyAndDecodeRealtimeRequest(signedPayload: string): Promise<DecodedRealtimeRequestBody>;
    protected verifyJWT<T>(jwt: string, validator: Validator<T>, signedDateExtractor: (decodedJWT: T) => Date): Promise<T>;
    protected verifyCertificateChain(trustedRoots: X509Certificate[], leaf: X509Certificate, intermediate: X509Certificate, effectiveDate: Date): Promise<KeyObject>;
    protected verifyCertificateChainWithoutCaching(trustedRoots: X509Certificate[], leaf: X509Certificate, intermediate: X509Certificate, effectiveDate: Date): Promise<KeyObject>;
    protected checkOCSPStatus(cert: X509Certificate, issuer: X509Certificate): Promise<void>;
    private checkDates;
    private parseX509Date;
    private extractSignedDate;
}
export declare enum VerificationStatus {
    OK = 0,
    VERIFICATION_FAILURE = 1,
    RETRYABLE_VERIFICATION_FAILURE = 2,
    INVALID_APP_IDENTIFIER = 3,
    INVALID_ENVIRONMENT = 4,
    INVALID_CHAIN_LENGTH = 5,
    INVALID_CERTIFICATE = 6,
    FAILURE = 7
}
export declare class VerificationException extends Error {
    status: VerificationStatus;
    cause?: Error;
    constructor(status: VerificationStatus, cause?: Error);
}
export {};
