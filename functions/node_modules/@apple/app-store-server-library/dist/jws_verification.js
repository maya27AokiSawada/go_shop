"use strict";
// Copyright (c) 2023 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.VerificationException = exports.VerificationStatus = exports.SignedDataVerifier = void 0;
const jsonwebtoken = require("jsonwebtoken");
const base64url_1 = require("base64url");
const crypto_1 = require("crypto");
const jsrsasign_1 = require("jsrsasign");
const node_fetch_1 = require("node-fetch");
const Environment_1 = require("./models/Environment");
const JWSTransactionDecodedPayload_1 = require("./models/JWSTransactionDecodedPayload");
const ResponseBodyV2DecodedPayload_1 = require("./models/ResponseBodyV2DecodedPayload");
const JWSRenewalInfoDecodedPayload_1 = require("./models/JWSRenewalInfoDecodedPayload");
const DecodedRealtimeRequestBody_1 = require("./models/DecodedRealtimeRequestBody");
const AppTransaction_1 = require("./models/AppTransaction");
const MAX_SKEW = 60000;
const MAXIMUM_CACHE_SIZE = 32; // There are unlikely to be more than a couple keys at once
const CACHE_TIME_LIMIT = 15 * 60 * 1000; // 15 minutes
class CacheValue {
    constructor(publicKey, cacheExpiry) {
        this.publicKey = publicKey;
        this.cacheExpiry = cacheExpiry;
    }
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
class SignedDataVerifier {
    /**
     *
     * @param appleRootCertificates A list of DER-encoded root certificates
     * @param enableOnlineChecks Whether to enable revocation checking and check expiration using the current date
     * @param environment The App Store environment to target for checks
     * @param bundleId The app's bundle identifier
     * @param appAppleId The app's identifier, omitted in the sandbox environment
     */
    constructor(appleRootCertificates, enableOnlineChecks, environment, bundleId, appAppleId) {
        this.JWSRenewalInfoDecodedPayloadValidator = new JWSRenewalInfoDecodedPayload_1.JWSRenewalInfoDecodedPayloadValidator();
        this.JWSTransactionDecodedPayloadValidator = new JWSTransactionDecodedPayload_1.JWSTransactionDecodedPayloadValidator();
        this.responseBodyV2DecodedPayloadValidator = new ResponseBodyV2DecodedPayload_1.ResponseBodyV2DecodedPayloadValidator();
        this.appTransactionValidator = new AppTransaction_1.AppTransactionValidator();
        this.decodedRealtimeRequestBodyValidator = new DecodedRealtimeRequestBody_1.DecodedRealtimeRequestBodyValidator();
        this.rootCertificates = appleRootCertificates.map(cert => new crypto_1.X509Certificate(cert));
        this.enableOnlineChecks = enableOnlineChecks;
        this.bundleId = bundleId;
        this.environment = environment;
        this.appAppleId = appAppleId;
        this.verifiedPublicKeyCache = {};
        if (environment === Environment_1.Environment.PRODUCTION && appAppleId === undefined) {
            throw new Error("appAppleId is required when the environment is Production");
        }
    }
    /**
     * Verifies and decodes a signedTransaction obtained from the App Store Server API, an App Store Server Notification, or from a device
     * See {@link https://developer.apple.com/documentation/appstoreserverapi/jwstransaction JWSTransaction}
     *
     * @param signedTransaction The signedTransaction field
     * @return The decoded transaction info after verification
     * @throws VerificationException Thrown if the data could not be verified
     */
    async verifyAndDecodeTransaction(signedTransactionInfo) {
        const decodedJWT = await this.verifyJWT(signedTransactionInfo, this.JWSTransactionDecodedPayloadValidator, this.extractSignedDate);
        if (decodedJWT.bundleId !== this.bundleId) {
            throw new VerificationException(VerificationStatus.INVALID_APP_IDENTIFIER);
        }
        if (decodedJWT.environment !== this.environment) {
            throw new VerificationException(VerificationStatus.INVALID_ENVIRONMENT);
        }
        return decodedJWT;
    }
    /**
     * Verifies and decodes a signedRenewalInfo obtained from the App Store Server API, an App Store Server Notification, or from a device
     * See {@link https://developer.apple.com/documentation/appstoreserverapi/jwsrenewalinfo JWSRenewalInfo}
     *
     * @param signedRenewalInfo The signedRenewalInfo field
     * @return The decoded renewal info after verification
     * @throws VerificationException Thrown if the data could not be verified
     */
    async verifyAndDecodeRenewalInfo(signedRenewalInfo) {
        const decodedRenewalInfo = await this.verifyJWT(signedRenewalInfo, this.JWSRenewalInfoDecodedPayloadValidator, this.extractSignedDate);
        const environment = decodedRenewalInfo.environment;
        if (this.environment !== environment) {
            throw new VerificationException(VerificationStatus.INVALID_ENVIRONMENT);
        }
        return decodedRenewalInfo;
    }
    /**
     * Verifies and decodes an App Store Server Notification signedPayload
     * See {@link https://developer.apple.com/documentation/appstoreservernotifications/signedpayload signedPayload}
     *
     * @param signedPayload The payload received by your server
     * @return The decoded payload after verification
     * @throws VerificationException Thrown if the data could not be verified
     */
    async verifyAndDecodeNotification(signedPayload) {
        const decodedJWT = await this.verifyJWT(signedPayload, this.responseBodyV2DecodedPayloadValidator, this.extractSignedDate);
        let appAppleId;
        let bundleId;
        let environment;
        if (decodedJWT.data) {
            appAppleId = decodedJWT.data.appAppleId;
            bundleId = decodedJWT.data.bundleId;
            environment = decodedJWT.data.environment;
        }
        else if (decodedJWT.summary) {
            appAppleId = decodedJWT.summary.appAppleId;
            bundleId = decodedJWT.summary.bundleId;
            environment = decodedJWT.summary.environment;
        }
        else if (decodedJWT.externalPurchaseToken) {
            appAppleId = decodedJWT.externalPurchaseToken.appAppleId;
            bundleId = decodedJWT.externalPurchaseToken.bundleId;
            if (decodedJWT.externalPurchaseToken.externalPurchaseId && decodedJWT.externalPurchaseToken.externalPurchaseId.startsWith("SANDBOX")) {
                environment = Environment_1.Environment.SANDBOX;
            }
            else {
                environment = Environment_1.Environment.PRODUCTION;
            }
        }
        else if (decodedJWT.appData) {
            appAppleId = decodedJWT.appData.appAppleId;
            bundleId = decodedJWT.appData.bundleId;
            environment = decodedJWT.appData.environment;
        }
        this.verifyNotification(bundleId, appAppleId, environment);
        return decodedJWT;
    }
    verifyNotification(bundleId, appAppleId, environment) {
        if (this.bundleId !== bundleId || (this.environment === Environment_1.Environment.PRODUCTION && this.appAppleId !== appAppleId)) {
            throw new VerificationException(VerificationStatus.INVALID_APP_IDENTIFIER);
        }
        if (this.environment !== environment) {
            throw new VerificationException(VerificationStatus.INVALID_ENVIRONMENT);
        }
    }
    /**
     * Verifies and decodes a signed AppTransaction
     * See {@link https://developer.apple.com/documentation/storekit/apptransaction AppTransaction}
     *
     * @param signedAppTransaction The signed AppTransaction
     * @returns The decoded AppTransaction after validation
     * @throws VerificationException Thrown if the data could not be verified
     */
    async verifyAndDecodeAppTransaction(signedAppTransaction) {
        const decodedAppTransaction = await this.verifyJWT(signedAppTransaction, this.appTransactionValidator, t => t.receiptCreationDate === undefined ? new Date() : new Date(t.receiptCreationDate));
        const environment = decodedAppTransaction.receiptType;
        if (this.bundleId !== decodedAppTransaction.bundleId || (this.environment === Environment_1.Environment.PRODUCTION && this.appAppleId !== decodedAppTransaction.appAppleId)) {
            throw new VerificationException(VerificationStatus.INVALID_APP_IDENTIFIER);
        }
        if (this.environment !== environment) {
            throw new VerificationException(VerificationStatus.INVALID_ENVIRONMENT);
        }
        return decodedAppTransaction;
    }
    /**
     * Verifies and decodes a Retention Messaging API signedPayload
     * See {@link https://developer.apple.com/documentation/retentionmessaging/signedpayload signedPayload}
     *
     * @param signedPayload The payload received by your server
     * @returns The decoded payload after verification
     * @throws VerificationException Thrown if the data could not be verified
     */
    async verifyAndDecodeRealtimeRequest(signedPayload) {
        const decodedRequest = await this.verifyJWT(signedPayload, this.decodedRealtimeRequestBodyValidator, this.extractSignedDate);
        if (this.environment === Environment_1.Environment.PRODUCTION && this.appAppleId !== decodedRequest.appAppleId) {
            throw new VerificationException(VerificationStatus.INVALID_APP_IDENTIFIER);
        }
        if (this.environment !== decodedRequest.environment) {
            throw new VerificationException(VerificationStatus.INVALID_ENVIRONMENT);
        }
        return decodedRequest;
    }
    async verifyJWT(jwt, validator, signedDateExtractor) {
        let certificateChain;
        let decodedJWT;
        try {
            decodedJWT = jsonwebtoken.decode(jwt);
            if (!validator.validate(decodedJWT)) {
                throw new VerificationException(VerificationStatus.FAILURE);
            }
            if (this.environment === Environment_1.Environment.XCODE || this.environment === Environment_1.Environment.LOCAL_TESTING) {
                // Data is not signed by the App Store, and verification should be skipped
                // The environment MUST be checked in the public method calling this
                return decodedJWT;
            }
            try {
                const header = jwt.split('.')[0];
                const decodedHeader = base64url_1.default.decode(header);
                const headerObj = JSON.parse(decodedHeader);
                const chain = headerObj['x5c'] ?? [];
                if (chain.length != 3) {
                    throw new VerificationException(VerificationStatus.INVALID_CHAIN_LENGTH);
                }
                certificateChain = chain.slice(0, 2).map(cert => new crypto_1.X509Certificate(Buffer.from(cert, 'base64')));
            }
            catch (error) {
                if (error instanceof Error) {
                    throw new VerificationException(VerificationStatus.INVALID_CERTIFICATE, error);
                }
                throw new VerificationException(VerificationStatus.INVALID_CERTIFICATE);
            }
            const effectiveDate = this.enableOnlineChecks ? new Date() : signedDateExtractor(decodedJWT);
            const publicKey = await this.verifyCertificateChain(this.rootCertificates, certificateChain[0], certificateChain[1], effectiveDate);
            const encodedKey = publicKey.export({
                type: "spki",
                format: "pem"
            });
            jsonwebtoken.verify(jwt, encodedKey);
            return decodedJWT;
        }
        catch (error) {
            if (error instanceof VerificationException) {
                throw error;
            }
            else if (error instanceof Error) {
                throw new VerificationException(VerificationStatus.VERIFICATION_FAILURE, error);
            }
            throw new VerificationException(VerificationStatus.VERIFICATION_FAILURE);
        }
    }
    async verifyCertificateChain(trustedRoots, leaf, intermediate, effectiveDate) {
        let cacheKey = leaf.toString() + intermediate.toString();
        if (this.enableOnlineChecks) {
            if (cacheKey in this.verifiedPublicKeyCache) {
                if (this.verifiedPublicKeyCache[cacheKey].cacheExpiry > new Date().getTime()) {
                    return this.verifiedPublicKeyCache[cacheKey].publicKey;
                }
            }
        }
        let publicKey = await this.verifyCertificateChainWithoutCaching(trustedRoots, leaf, intermediate, effectiveDate);
        if (this.enableOnlineChecks) {
            this.verifiedPublicKeyCache[cacheKey] = new CacheValue(leaf.publicKey, new Date().getTime() + CACHE_TIME_LIMIT);
            if (Object.keys(this.verifiedPublicKeyCache).length > MAXIMUM_CACHE_SIZE) {
                for (let key in Object.keys(this.verifiedPublicKeyCache)) {
                    if (this.verifiedPublicKeyCache[key].cacheExpiry < new Date().getTime()) {
                        delete this.verifiedPublicKeyCache[key];
                    }
                }
            }
        }
        return publicKey;
    }
    async verifyCertificateChainWithoutCaching(trustedRoots, leaf, intermediate, effectiveDate) {
        let validity = false;
        let rootCert;
        for (const root of trustedRoots) {
            if (intermediate.verify(root.publicKey) && intermediate.issuer === root.subject) {
                validity = true;
                rootCert = root;
            }
        }
        validity = validity && leaf.verify(intermediate.publicKey) && leaf.issuer === intermediate.subject;
        validity = validity && intermediate.ca;
        const jsrsassignX509Leaf = new jsrsasign_1.X509();
        jsrsassignX509Leaf.readCertHex(leaf.raw.toString('hex'));
        const jsrassignX509Intermediate = new jsrsasign_1.X509();
        jsrassignX509Intermediate.readCertHex(intermediate.raw.toString('hex'));
        validity = validity && jsrsassignX509Leaf.getExtInfo("1.2.840.113635.100.6.11.1") !== undefined;
        validity = validity && jsrassignX509Intermediate.getExtInfo("1.2.840.113635.100.6.2.1") !== undefined;
        if (!validity) {
            throw new VerificationException(VerificationStatus.VERIFICATION_FAILURE);
        }
        rootCert = rootCert;
        this.checkDates(leaf, effectiveDate);
        this.checkDates(intermediate, effectiveDate);
        this.checkDates(rootCert, effectiveDate);
        if (this.enableOnlineChecks) {
            await Promise.all([this.checkOCSPStatus(leaf, intermediate), this.checkOCSPStatus(intermediate, rootCert)]);
        }
        return leaf.publicKey;
    }
    async checkOCSPStatus(cert, issuer) {
        const authorityRex = /^OCSP - URI:(.*)$/m;
        const matchResult = cert.infoAccess ? authorityRex.exec(cert.infoAccess) : "";
        if (matchResult === null || matchResult.length !== 2) {
            throw new VerificationException(VerificationStatus.INVALID_CERTIFICATE);
        }
        const request = new jsrsasign_1.KJUR.asn1.ocsp.OCSPRequest({ reqList: [{ issuerCert: issuer.toString(), subjectCert: cert.toString(), alg: "sha256" }] });
        const headers = new node_fetch_1.Headers();
        headers.append('Content-Type', 'application/ocsp-request');
        let response;
        try {
            response = await (0, node_fetch_1.default)(matchResult[1], {
                headers: headers,
                method: 'POST',
                body: Buffer.from(request.getEncodedHex(), 'hex'),
                timeout: 30000
            });
            if (!response.ok) {
                throw new VerificationException(VerificationStatus.RETRYABLE_VERIFICATION_FAILURE);
            }
        }
        catch (error) {
            if (error instanceof VerificationException) {
                throw error;
            }
            // Network errors
            throw new VerificationException(VerificationStatus.RETRYABLE_VERIFICATION_FAILURE, error instanceof Error ? error : undefined);
        }
        const responseBuffer = await response.buffer();
        const parsedResponse = new jsrsasign_1.KJUR.asn1.ocsp.OCSPParser().getOCSPResponse(responseBuffer.toString('hex'));
        // The issuer could also be the signer
        const jsrassignX509Issuer = new jsrsasign_1.X509();
        jsrassignX509Issuer.readCertHex(issuer.raw.toString('hex'));
        const allCerts = [jsrassignX509Issuer];
        for (const certHex of parsedResponse.certs) {
            const cert = new jsrsasign_1.X509();
            cert.readCertHex(certHex);
            allCerts.push(cert);
        }
        let signingCert = null;
        if (parsedResponse.respid.key) {
            for (const cert of allCerts) {
                const shasum = (0, crypto_1.createHash)('sha1');
                shasum.update(Buffer.from(cert.getSPKIValue(), 'hex'));
                const spkiHash = shasum.digest('hex');
                if (spkiHash === parsedResponse.respid.key) {
                    signingCert = new crypto_1.X509Certificate(Buffer.from(cert.hex, 'hex'));
                }
            }
        }
        else if (parsedResponse.respid.name) {
            for (const cert of allCerts) {
                if (cert.getSubject().str === parsedResponse.respid.name.str) {
                    signingCert = new crypto_1.X509Certificate(Buffer.from(cert.hex, 'hex'));
                }
            }
        }
        if (signingCert == null) {
            throw new VerificationException(VerificationStatus.FAILURE);
        }
        // Verify Signing Cert is issued by issuer
        if (signingCert.publicKey === issuer.publicKey && signingCert.subject === issuer.subject) {
            // This is directly signed by the issuer
        }
        else if (signingCert.verify(issuer.publicKey)) {
            // This is issued by the issuer, let's check the dates and purpose
            const signingCertAssign = new jsrsasign_1.X509();
            signingCertAssign.readCertPEM(signingCert.toString());
            if (!signingCertAssign.getExtExtKeyUsage().array.includes("ocspSigning")) {
                throw new VerificationException(VerificationStatus.INVALID_CERTIFICATE);
            }
            this.checkDates(signingCert, new Date());
        }
        else {
            throw new VerificationException(VerificationStatus.INVALID_CERTIFICATE);
        }
        // Extract raw responseData
        const responseData = jsrsasign_1.ASN1HEX.getTLVbyList(responseBuffer.toString('hex'), 0, [1, 0, 1, 0, 0]);
        // Verify Payload signed by cert
        const shortAlg = parsedResponse.alg.substring(0, 6).toUpperCase();
        if (shortAlg !== "SHA256" && shortAlg !== "SHA384" && shortAlg !== "SHA512") {
            throw new VerificationException(VerificationStatus.FAILURE);
        }
        if (!(0, crypto_1.verify)(shortAlg, Buffer.from(responseData, 'hex'), signingCert.publicKey, Buffer.from(parsedResponse.sighex, 'hex'))) {
            throw new VerificationException(VerificationStatus.FAILURE);
        }
        for (const singleResponse of parsedResponse.array) {
            // Confirm entry is for this cert
            const certIdBuilder = new jsrsasign_1.KJUR.asn1.ocsp.CertID();
            const currentCertCertId = certIdBuilder.getParamByCerts(issuer.toString(), cert.toString(), 'sha256');
            if (!(currentCertCertId.alg === singleResponse.certid.alg && currentCertCertId.issname === singleResponse.certid.issname &&
                currentCertCertId.isskey === singleResponse.certid.isskey && currentCertCertId.sbjsn === singleResponse.certid.sbjsn)) {
                continue;
            }
            // Validate contents
            const issueDate = this.parseX509Date(singleResponse.thisupdate);
            const nextDate = this.parseX509Date(singleResponse.nextupdate);
            if (singleResponse.status.status !== 'good' || new Date().getTime() + MAX_SKEW < issueDate.getTime() || nextDate.getTime() < new Date().getTime() - MAX_SKEW) {
                throw new VerificationException(VerificationStatus.FAILURE);
            }
            // Success
            return;
        }
        throw new VerificationException(VerificationStatus.FAILURE);
    }
    checkDates(cert, effectiveDate) {
        if (new Date(cert.validFrom).getTime() > (effectiveDate.getTime() + MAX_SKEW) ||
            new Date(cert.validTo).getTime() < (effectiveDate.getTime() - MAX_SKEW)) {
            throw new VerificationException(VerificationStatus.INVALID_CERTIFICATE);
        }
    }
    parseX509Date(date) {
        return new Date(date.replace(/^(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/, '$4:$5:$6 $2/$3/$1'));
    }
    extractSignedDate(decodedJWT) {
        return decodedJWT.signedDate === undefined ? new Date() : new Date(decodedJWT.signedDate);
    }
}
exports.SignedDataVerifier = SignedDataVerifier;
var VerificationStatus;
(function (VerificationStatus) {
    VerificationStatus[VerificationStatus["OK"] = 0] = "OK";
    VerificationStatus[VerificationStatus["VERIFICATION_FAILURE"] = 1] = "VERIFICATION_FAILURE";
    VerificationStatus[VerificationStatus["RETRYABLE_VERIFICATION_FAILURE"] = 2] = "RETRYABLE_VERIFICATION_FAILURE";
    VerificationStatus[VerificationStatus["INVALID_APP_IDENTIFIER"] = 3] = "INVALID_APP_IDENTIFIER";
    VerificationStatus[VerificationStatus["INVALID_ENVIRONMENT"] = 4] = "INVALID_ENVIRONMENT";
    VerificationStatus[VerificationStatus["INVALID_CHAIN_LENGTH"] = 5] = "INVALID_CHAIN_LENGTH";
    VerificationStatus[VerificationStatus["INVALID_CERTIFICATE"] = 6] = "INVALID_CERTIFICATE";
    VerificationStatus[VerificationStatus["FAILURE"] = 7] = "FAILURE";
})(VerificationStatus || (exports.VerificationStatus = VerificationStatus = {}));
class VerificationException extends Error {
    constructor(status, cause) {
        super();
        this.status = status;
        this.cause = cause;
    }
}
exports.VerificationException = VerificationException;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiandzX3ZlcmlmaWNhdGlvbi5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uL2p3c192ZXJpZmljYXRpb24udHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IjtBQUFBLDREQUE0RDs7O0FBRTVELDZDQUE4QztBQUU5Qyx5Q0FBa0M7QUFDbEMsbUNBQXdFO0FBQ3hFLHlDQUFnRDtBQUNoRCwyQ0FBNEM7QUFDNUMsc0RBQW1EO0FBQ25ELHdGQUE0SDtBQUM1SCx3RkFBNEg7QUFDNUgsd0ZBQTRIO0FBQzVILG9GQUFzSDtBQUd0SCw0REFBa0Y7QUFFbEYsTUFBTSxRQUFRLEdBQUcsS0FBSyxDQUFBO0FBRXRCLE1BQU0sa0JBQWtCLEdBQUcsRUFBRSxDQUFBLENBQUMsMkRBQTJEO0FBQ3pGLE1BQU0sZ0JBQWdCLEdBQUcsRUFBRSxHQUFHLEVBQUUsR0FBRyxJQUFLLENBQUEsQ0FBQyxhQUFhO0FBRXRELE1BQU0sVUFBVTtJQUlkLFlBQVksU0FBb0IsRUFBRSxXQUFtQjtRQUNuRCxJQUFJLENBQUMsU0FBUyxHQUFHLFNBQVMsQ0FBQTtRQUMxQixJQUFJLENBQUMsV0FBVyxHQUFHLFdBQVcsQ0FBQTtJQUNoQyxDQUFDO0NBQ0Y7QUFFRDs7Ozs7Ozs7Ozs7Ozs7R0FjRztBQUNILE1BQWEsa0JBQWtCO0lBYzNCOzs7Ozs7O09BT0c7SUFDSCxZQUFZLHFCQUErQixFQUFFLGtCQUEyQixFQUFFLFdBQXdCLEVBQUUsUUFBZ0IsRUFBRSxVQUFtQjtRQXJCakksMENBQXFDLEdBQUcsSUFBSSxvRUFBcUMsRUFBRSxDQUFBO1FBQ25GLDBDQUFxQyxHQUFHLElBQUksb0VBQXFDLEVBQUUsQ0FBQTtRQUNuRiwwQ0FBcUMsR0FBRyxJQUFJLG9FQUFxQyxFQUFFLENBQUE7UUFDbkYsNEJBQXVCLEdBQUcsSUFBSSx3Q0FBdUIsRUFBRSxDQUFBO1FBQ3ZELHdDQUFtQyxHQUFHLElBQUksZ0VBQW1DLEVBQUUsQ0FBQTtRQWtCckYsSUFBSSxDQUFDLGdCQUFnQixHQUFHLHFCQUFx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bUJBQW1CLENBQUMsQ0FBQTtRQUN6RSxDQUFDO0lBQ0gsQ0FBQztJQUVPLGFBQWEsQ0FBQyxJQUFZO1FBQ2hDLE9BQU8sSUFBSSxJQUFJLENBQUMsSUFBSSxDQUFDLE9BQU8sQ0FDMUIseUNBQXlDLEVBQ3pDLG1CQUFtQixDQUNwQixDQUFDLENBQUM7SUFDTCxDQUFDO0lBRU8saUJBQWlCLENBQUMsVUFBNkI7UUFDckQsT0FBTyxVQUFVLENBQUMsVUFBVSxLQUFLLFNBQVMsQ0FBQyxDQUFDLENBQUMsSUFBSSxJQUFJLEVBQUUsQ0FBQyxDQUFDLENBQUMsSUFBSSxJQUFJLENBQUMsVUFBVSxDQUFDLFVBQVUsQ0FBQyxDQUFBO0lBQzNGLENBQUM7Q0FDSjtBQTlYRCxnREE4WEM7QUFFRCxJQUFZLGtCQVNYO0FBVEQsV0FBWSxrQkFBa0I7SUFDNUIsdURBQUUsQ0FBQTtJQUNGLDJGQUFvQixDQUFBO0lBQ3BCLCtHQUE4QixDQUFBO0lBQzlCLCtGQUFzQixDQUFBO0lBQ3RCLHlGQUFtQixDQUFBO0lBQ25CLDJGQUFvQixDQUFBO0lBQ3BCLHlGQUFtQixDQUFBO0lBQ25CLGlFQUFPLENBQUE7QUFDVCxDQUFDLEVBVFcsa0JBQWtCLGtDQUFsQixrQkFBa0IsUUFTN0I7QUFFRCxNQUFhLHFCQUFzQixTQUFRLEtBQUs7SUFJOUMsWUFBWSxNQUEwQixFQUFFLEtBQWE7UUFDbkQsS0FBSyxFQUFFLENBQUM7UUFDUixJQUFJLENBQUMsTUFBTSxHQUFHLE1BQU0sQ0FBQTtRQUNwQixJQUFJLENBQUMsS0FBSyxHQUFHLEtBQUssQ0FBQTtJQUNwQixDQUFDO0NBQ0Y7QUFURCxzREFTQyIsInNvdXJjZXNDb250ZW50IjpbIi8vIENvcHlyaWdodCAoYykgMjAyMyBBcHBsZSBJbmMuIExpY2Vuc2VkIHVuZGVyIE1JVCBMaWNlbnNlLlxuXG5pbXBvcnQganNvbndlYnRva2VuID0gcmVxdWlyZSgnanNvbndlYnRva2VuJyk7XG5cbmltcG9ydCBiYXNlNjR1cmwgZnJvbSAnYmFzZTY0dXJsJztcbmltcG9ydCB7IEtleU9iamVjdCwgWDUwOUNlcnRpZmljYXRlLCBjcmVhdGVIYXNoLCB2ZXJpZnkgfSBmcm9tICdjcnlwdG8nO1xuaW1wb3J0IHsgS0pVUiwgWDUwOSwgQVNOMUhFWCB9IGZyb20gJ2pzcnNhc2lnbic7XG5pbXBvcnQgZmV0Y2gsIHsgSGVhZGVycyB9IGZyb20gJ25vZGUtZmV0Y2gnO1xuaW1wb3J0IHsgRW52aXJvbm1lbnQgfSBmcm9tICcuL21vZGVscy9FbnZpcm9ubWVudCc7XG5pbXBvcnQgeyBKV1NUcmFuc2FjdGlvbkRlY29kZWRQYXlsb2FkLCBKV1NUcmFuc2FjdGlvbkRlY29kZWRQYXlsb2FkVmFsaWRhdG9yIH0gZnJvbSAnLi9tb2RlbHMvSldTVHJhbnNhY3Rpb25EZWNvZGVkUGF5bG9hZCc7XG5pbXBvcnQgeyBSZXNwb25zZUJvZHlWMkRlY29kZWRQYXlsb2FkLCBSZXNwb25zZUJvZHlWMkRlY29kZWRQYXlsb2FkVmFsaWRhdG9yIH0gZnJvbSAnLi9tb2RlbHMvUmVzcG9uc2VCb2R5VjJEZWNvZGVkUGF5bG9hZCc7XG5pbXBvcnQgeyBKV1NSZW5ld2FsSW5mb0RlY29kZWRQYXlsb2FkLCBKV1NSZW5ld2FsSW5mb0RlY29kZWRQYXlsb2FkVmFsaWRhdG9yIH0gZnJvbSAnLi9tb2RlbHMvSldTUmVuZXdhbEluZm9EZWNvZGVkUGF5bG9hZCc7XG5pbXBvcnQgeyBEZWNvZGVkUmVhbHRpbWVSZXF1ZXN0Qm9keSwgRGVjb2RlZFJlYWx0aW1lUmVxdWVzdEJvZHlWYWxpZGF0b3IgfSBmcm9tICcuL21vZGVscy9EZWNvZGVkUmVhbHRpbWVSZXF1ZXN0Qm9keSc7XG5pbXBvcnQgeyBWYWxpZGF0b3IgfSBmcm9tICcuL21vZGVscy9WYWxpZGF0b3InO1xuaW1wb3J0IHsgRGVjb2RlZFNpZ25lZERhdGEgfSBmcm9tICcuL21vZGVscy9EZWNvZGVkU2lnbmVkRGF0YSc7XG5pbXBvcnQgeyBBcHBUcmFuc2FjdGlvbiwgQXBwVHJhbnNhY3Rpb25WYWxpZGF0b3IgfSBmcm9tICcuL21vZGVscy9BcHBUcmFuc2FjdGlvbic7XG5cbmNvbnN0IE1BWF9TS0VXID0gNjAwMDBcblxuY29uc3QgTUFYSU1VTV9DQUNIRV9TSVpFID0gMzIgLy8gVGhlcmUgYXJlIHVubGlrZWx5IHRvIGJlIG1vcmUgdGhhbiBhIGNvdXBsZSBrZXlzIGF0IG9uY2VcbmNvbnN0IENBQ0hFX1RJTUVfTElNSVQgPSAxNSAqIDYwICogMV8wMDAgLy8gMTUgbWludXRlc1xuXG5jbGFzcyBDYWNoZVZhbHVlIHtcbiAgcHVibGljIHB1YmxpY0tleTogS2V5T2JqZWN0XG4gIHB1YmxpYyBjYWNoZUV4cGlyeTogbnVtYmVyXG5cbiAgY29uc3RydWN0b3IocHVibGljS2V5OiBLZXlPYmplY3QsIGNhY2hlRXhwaXJ5OiBudW1iZXIpIHtcbiAgICB0aGlzLnB1YmxpY0tleSA9IHB1YmxpY0tleVxuICAgIHRoaXMuY2FjaGVFeHBpcnkgPSBjYWNoZUV4cGlyeVxuICB9XG59XG5cbi8qKlxuICogQSBjbGFzcyBwcm92aWRpbmcgdXRpbGl0eSBtZXRob2RzIGZvciB2ZXJpZnlpbmcgYW5kIGRlY29kaW5nIEFwcCBTdG9yZSBzaWduZWQgZGF0YS5cbiAqIFxuICogRXhhbXBsZSBVc2FnZTpcbiAqIGBgYHRzXG4gKiBjb25zdCB2ZXJpZmllciA9IG5ldyBTaWduZWREYXRhVmVyaWZpZXIoW2FwcGxlUm9vdCwgYXBwbGVSb290Ml0sIHRydWUsIEVudmlyb25tZW50LlNBTkRCT1gsIFwiY29tLmV4YW1wbGVcIilcbiAqIFxuICogdHJ5IHtcbiAqICAgICBjb25zdCBkZWNvZGVkTm90aWZpY2F0aW9uID0gdmVyaWZpZXIudmVyaWZ5QW5kRGVjb2RlTm90aWZpY2F0aW9uKFwiZXkuLi5cIilcbiAqICAgICBjb25zb2xlLmxvZyhkZWNvZGVkTm90aWZpY2F0aW9uKVxuICogfSBjYXRjaCAoZSkge1xuICogICAgIGNvbnNvbGUuZXJyb3IoZSlcbiAqIH1cbiAqIGBgYFxuICovXG5leHBvcnQgY2xhc3MgU2lnbmVkRGF0YVZlcmlmaWVyIHtcbiAgICBwcml2YXRlIEpXU1JlbmV3YWxJbmZvRGVjb2RlZFBheWxvYWRWYWxpZGF0b3IgPSBuZXcgSldTUmVuZXdhbEluZm9EZWNvZGVkUGF5bG9hZFZhbGlkYXRvcigpXG4gICAgcHJpdmF0ZSBKV1NUcmFuc2FjdGlvbkRlY29kZWRQYXlsb2FkVmFsaWRhdG9yID0gbmV3IEpXU1RyYW5zYWN0aW9uRGVjb2RlZFBheWxvYWRWYWxpZGF0b3IoKVxuICAgIHByaXZhdGUgcmVzcG9uc2VCb2R5VjJEZWNvZGVkUGF5bG9hZFZhbGlkYXRvciA9IG5ldyBSZXNwb25zZUJvZHlWMkRlY29kZWRQYXlsb2FkVmFsaWRhdG9yKClcbiAgICBwcml2YXRlIGFwcFRyYW5zYWN0aW9uVmFsaWRhdG9yID0gbmV3IEFwcFRyYW5zYWN0aW9uVmFsaWRhdG9yKClcbiAgICBwcml2YXRlIGRlY29kZWRSZWFsdGltZVJlcXVlc3RCb2R5VmFsaWRhdG9yID0gbmV3IERlY29kZWRSZWFsdGltZVJlcXVlc3RCb2R5VmFsaWRhdG9yKClcblxuICAgIHByb3RlY3RlZCByb290Q2VydGlmaWNhdGVzOiBYNTA5Q2VydGlmaWNhdGVbXVxuICAgIHByb3RlY3RlZCBlbmFibGVPbmxpbmVDaGVja3M6IGJvb2xlYW5cbiAgICBwcm90ZWN0ZWQgYnVuZGxlSWQ6IHN0cmluZ1xuICAgIHByb3RlY3RlZCBhcHBBcHBsZUlkPzogbnVtYmVyXG4gICAgcHJvdGVjdGVkIGVudmlyb25tZW50OiBFbnZpcm9ubWVudFxuICAgIHByb3RlY3RlZCB2ZXJpZmllZFB1YmxpY0tleUNhY2hlOiB7IFtpbmRleDogc3RyaW5nXTogQ2FjaGVWYWx1ZSB9XG5cbiAgICAvKipcbiAgICAgKiBcbiAgICAgKiBAcGFyYW0gYXBwbGVSb290Q2VydGlmaWNhdGVzIEEgbGlzdCBvZiBERVItZW5jb2RlZCByb290IGNlcnRpZmljYXRlcyBcbiAgICAgKiBAcGFyYW0gZW5hYmxlT25saW5lQ2hlY2tzIFdoZXRoZXIgdG8gZW5hYmxlIHJldm9jYXRpb24gY2hlY2tpbmcgYW5kIGNoZWNrIGV4cGlyYXRpb24gdXNpbmcgdGhlIGN1cnJlbnQgZGF0ZVxuICAgICAqIEBwYXJhbSBlbnZpcm9ubWVudCBUaGUgQXBwIFN0b3JlIGVudmlyb25tZW50IHRvIHRhcmdldCBmb3IgY2hlY2tzXG4gICAgICogQHBhcmFtIGJ1bmRsZUlkIFRoZSBhcHAncyBidW5kbGUgaWRlbnRpZmllclxuICAgICAqIEBwYXJhbSBhcHBBcHBsZUlkIFRoZSBhcHAncyBpZGVudGlmaWVyLCBvbWl0dGVkIGluIHRoZSBzYW5kYm94IGVudmlyb25tZW50XG4gICAgICovXG4gICAgY29uc3RydWN0b3IoYXBwbGVSb290Q2VydGlmaWNhdGVzOiBCdWZmZXJbXSwgZW5hYmxlT25saW5lQ2hlY2tzOiBib29sZWFuLCBlbnZpcm9ubWVudDogRW52aXJvbm1lbnQsIGJ1bmRsZUlkOiBzdHJpbmcsIGFwcEFwcGxlSWQ/OiBudW1iZXIpIHtcbiAgICAgIHRoaXMucm9vdENlcnRpZmljYXRlcyA9IGFwcGxlUm9vdENlcnRpZmljYXRlcy5tYXAoY2VydCA9PiBuZXcgWDUwOUNlcnRpZmljYXRlKGNlcnQpKVxuICAgICAgdGhpcy5lbmFibGVPbmxpbmVDaGVja3MgPSBlbmFibGVPbmxpbmVDaGVja3NcbiAgICAgIHRoaXMuYnVuZGxlSWQgPSBidW5kbGVJZDtcbiAgICAgIHRoaXMuZW52aXJvbm1lbnQgPSBlbnZpcm9ubWVudFxuICAgICAgdGhpcy5hcHBBcHBsZUlkID0gYXBwQXBwbGVJZFxuICAgICAgdGhpcy52ZXJpZmllZFB1YmxpY0tleUNhY2hlID0ge31cbiAgICAgIGlmIChlbnZpcm9ubWVudCA9PT0gRW52aXJvbm1lbnQuUFJPRFVDVElPTiAmJiBhcHBBcHBsZUlkID09PSB1bmRlZmluZWQpIHtcbiAgICAgICAgdGhyb3cgbmV3IEVycm9yKFwiYXBwQXBwbGVJZCBpcyByZXF1aXJlZCB3aGVuIHRoZSBlbnZpcm9ubWVudCBpcyBQcm9kdWN0aW9uXCIpXG4gICAgICB9XG4gICAgfVxuXG4gICAgLyoqXG4gICAgICogVmVyaWZpZXMgYW5kIGRlY29kZXMgYSBzaWduZWRUcmFuc2FjdGlvbiBvYnRhaW5lZCBmcm9tIHRoZSBBcHAgU3RvcmUgU2VydmVyIEFQSSwgYW4gQXBwIFN0b3JlIFNlcnZlciBOb3RpZmljYXRpb24sIG9yIGZyb20gYSBkZXZpY2VcbiAgICAgKiBTZWUge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2p3c3RyYW5zYWN0aW9uIEpXU1RyYW5zYWN0aW9ufVxuICAgICAqXG4gICAgICogQHBhcmFtIHNpZ25lZFRyYW5zYWN0aW9uIFRoZSBzaWduZWRUcmFuc2FjdGlvbiBmaWVsZFxuICAgICAqIEByZXR1cm4gVGhlIGRlY29kZWQgdHJhbnNhY3Rpb24gaW5mbyBhZnRlciB2ZXJpZmljYXRpb25cbiAgICAgKiBAdGhyb3dzIFZlcmlmaWNhdGlvbkV4Y2VwdGlvbiBUaHJvd24gaWYgdGhlIGRhdGEgY291bGQgbm90IGJlIHZlcmlmaWVkXG4gICAgICovXG4gICAgYXN5bmMgdmVyaWZ5QW5kRGVjb2RlVHJhbnNhY3Rpb24oc2lnbmVkVHJhbnNhY3Rpb25JbmZvOiBzdHJpbmcpOiBQcm9taXNlPEpXU1RyYW5zYWN0aW9uRGVjb2RlZFBheWxvYWQ+IHtcbiAgICAgIGNvbnN0IGRlY29kZWRKV1Q6IEpXU1RyYW5zYWN0aW9uRGVjb2RlZFBheWxvYWQgPSBhd2FpdCB0aGlzLnZlcmlmeUpXVChzaWduZWRUcmFuc2FjdGlvbkluZm8sIHRoaXMuSldTVHJhbnNhY3Rpb25EZWNvZGVkUGF5bG9hZFZhbGlkYXRvciwgdGhpcy5leHRyYWN0U2lnbmVkRGF0ZSk7XG4gICAgICBpZiAoZGVjb2RlZEpXVC5idW5kbGVJZCAhPT0gdGhpcy5idW5kbGVJZCkge1xuICAgICAgICB0aHJvdyBuZXcgVmVyaWZpY2F0aW9uRXhjZXB0aW9uKFZlcmlmaWNhdGlvblN0YXR1cy5JTlZBTElEX0FQUF9JREVOVElGSUVSKVxuICAgICAgfVxuICAgICAgaWYgKGRlY29kZWRKV1QuZW52aXJvbm1lbnQgIT09IHRoaXMuZW52aXJvbm1lbnQpIHtcbiAgICAgICAgdGhyb3cgbmV3IFZlcmlmaWNhdGlvbkV4Y2VwdGlvbihWZXJpZmljYXRpb25TdGF0dXMuSU5WQUxJRF9FTlZJUk9OTUVOVClcbiAgICAgIH1cbiAgICAgIHJldHVybiBkZWNvZGVkSldUO1xuICAgIH1cblxuICAgIC8qKlxuICAgICAqIFZlcmlmaWVzIGFuZCBkZWNvZGVzIGEgc2lnbmVkUmVuZXdhbEluZm8gb2J0YWluZWQgZnJvbSB0aGUgQXBwIFN0b3JlIFNlcnZlciBBUEksIGFuIEFwcCBTdG9yZSBTZXJ2ZXIgTm90aWZpY2F0aW9uLCBvciBmcm9tIGEgZGV2aWNlXG4gICAgICogU2VlIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9qd3NyZW5ld2FsaW5mbyBKV1NSZW5ld2FsSW5mb31cbiAgICAgKlxuICAgICAqIEBwYXJhbSBzaWduZWRSZW5ld2FsSW5mbyBUaGUgc2lnbmVkUmVuZXdhbEluZm8gZmllbGRcbiAgICAgKiBAcmV0dXJuIFRoZSBkZWNvZGVkIHJlbmV3YWwgaW5mbyBhZnRlciB2ZXJpZmljYXRpb25cbiAgICAgKiBAdGhyb3dzIFZlcmlmaWNhdGlvbkV4Y2VwdGlvbiBUaHJvd24gaWYgdGhlIGRhdGEgY291bGQgbm90IGJlIHZlcmlmaWVkXG4gICAgICovXG4gICAgYXN5bmMgdmVyaWZ5QW5kRGVjb2RlUmVuZXdhbEluZm8oc2lnbmVkUmVuZXdhbEluZm86IHN0cmluZyk6IFByb21pc2U8SldTUmVuZXdhbEluZm9EZWNvZGVkUGF5bG9hZD4ge1xuICAgICAgY29uc3QgZGVjb2RlZFJlbmV3YWxJbmZvOiBKV1NSZW5ld2FsSW5mb0RlY29kZWRQYXlsb2FkID0gYXdhaXQgdGhpcy52ZXJpZnlKV1Qoc2lnbmVkUmVuZXdhbEluZm8sIHRoaXMuSldTUmVuZXdhbEluZm9EZWNvZGVkUGF5bG9hZFZhbGlkYXRvciwgdGhpcy5leHRyYWN0U2lnbmVkRGF0ZSk7XG4gICAgICBjb25zdCBlbnZpcm9ubWVudCA9IGRlY29kZWRSZW5ld2FsSW5mby5lbnZpcm9ubWVudFxuICAgICAgaWYgKHRoaXMuZW52aXJvbm1lbnQgIT09IGVudmlyb25tZW50KSB7XG4gICAgICAgIHRocm93IG5ldyBWZXJpZmljYXRpb25FeGNlcHRpb24oVmVyaWZpY2F0aW9uU3RhdHVzLklOVkFMSURfRU5WSVJPTk1FTlQpXG4gICAgICB9XG4gICAgICByZXR1cm4gZGVjb2RlZFJlbmV3YWxJbmZvXG4gICAgfVxuXG4gICAgLyoqXG4gICAgICogVmVyaWZpZXMgYW5kIGRlY29kZXMgYW4gQXBwIFN0b3JlIFNlcnZlciBOb3RpZmljYXRpb24gc2lnbmVkUGF5bG9hZFxuICAgICAqIFNlZSB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJub3RpZmljYXRpb25zL3NpZ25lZHBheWxvYWQgc2lnbmVkUGF5bG9hZH1cbiAgICAgKlxuICAgICAqIEBwYXJhbSBzaWduZWRQYXlsb2FkIFRoZSBwYXlsb2FkIHJlY2VpdmVkIGJ5IHlvdXIgc2VydmVyXG4gICAgICogQHJldHVybiBUaGUgZGVjb2RlZCBwYXlsb2FkIGFmdGVyIHZlcmlmaWNhdGlvblxuICAgICAqIEB0aHJvd3MgVmVyaWZpY2F0aW9uRXhjZXB0aW9uIFRocm93biBpZiB0aGUgZGF0YSBjb3VsZCBub3QgYmUgdmVyaWZpZWRcbiAgICAgKi9cbiAgICBhc3luYyB2ZXJpZnlBbmREZWNvZGVOb3RpZmljYXRpb24oc2lnbmVkUGF5bG9hZDogc3RyaW5nKTogUHJvbWlzZTxSZXNwb25zZUJvZHlWMkRlY29kZWRQYXlsb2FkPiB7XG4gICAgICBjb25zdCBkZWNvZGVkSldUOiBSZXNwb25zZUJvZHlWMkRlY29kZWRQYXlsb2FkID0gYXdhaXQgdGhpcy52ZXJpZnlKV1Qoc2lnbmVkUGF5bG9hZCwgdGhpcy5yZXNwb25zZUJvZHlWMkRlY29kZWRQYXlsb2FkVmFsaWRhdG9yLCB0aGlzLmV4dHJhY3RTaWduZWREYXRlKTtcbiAgICAgIGxldCBhcHBBcHBsZUlkOiBudW1iZXIgfCB1bmRlZmluZWRcbiAgICAgIGxldCBidW5kbGVJZDogc3RyaW5nIHwgdW5kZWZpbmVkXG4gICAgICBsZXQgZW52aXJvbm1lbnQ6IHN0cmluZyB8IHVuZGVmaW5lZFxuICAgICAgaWYgKGRlY29kZWRKV1QuZGF0YSkge1xuICAgICAgICBhcHBBcHBsZUlkID0gZGVjb2RlZEpXVC5kYXRhLmFwcEFwcGxlSWRcbiAgICAgICAgYnVuZGxlSWQgPSBkZWNvZGVkSldULmRhdGEuYnVuZGxlSWRcbiAgICAgICAgZW52aXJvbm1lbnQgPSBkZWNvZGVkSldULmRhdGEuZW52aXJvbm1lbnRcbiAgICAgIH0gZWxzZSBpZiAoZGVjb2RlZEpXVC5zdW1tYXJ5KSB7XG4gICAgICAgIGFwcEFwcGxlSWQgPSBkZWNvZGVkSldULnN1bW1hcnkuYXBwQXBwbGVJZFxuICAgICAgICBidW5kbGVJZCA9IGRlY29kZWRKV1Quc3VtbWFyeS5idW5kbGVJZFxuICAgICAgICBlbnZpcm9ubWVudCA9IGRlY29kZWRKV1Quc3VtbWFyeS5lbnZpcm9ubWVudFxuICAgICAgfSBlbHNlIGlmIChkZWNvZGVkSldULmV4dGVybmFsUHVyY2hhc2VUb2tlbikge1xuICAgICAgICBhcHBBcHBsZUlkID0gZGVjb2RlZEpXVC5leHRlcm5hbFB1cmNoYXNlVG9rZW4uYXBwQXBwbGVJZFxuICAgICAgICBidW5kbGVJZCA9IGRlY29kZWRKV1QuZXh0ZXJuYWxQdXJjaGFzZVRva2VuLmJ1bmRsZUlkXG4gICAgICAgIGlmIChkZWNvZGVkSldULmV4dGVybmFsUHVyY2hhc2VUb2tlbi5leHRlcm5hbFB1cmNoYXNlSWQgJiYgZGVjb2RlZEpXVC5leHRlcm5hbFB1cmNoYXNlVG9rZW4uZXh0ZXJuYWxQdXJjaGFzZUlkLnN0YXJ0c1dpdGgoXCJTQU5EQk9YXCIpKSB7XG4gICAgICAgICAgZW52aXJvbm1lbnQgPSBFbnZpcm9ubWVudC5TQU5EQk9YXG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgZW52aXJvbm1lbnQgPSBFbnZpcm9ubWVudC5QUk9EVUNUSU9OXG4gICAgICAgIH1cbiAgICAgIH0gZWxzZSBpZiAoZGVjb2RlZEpXVC5hcHBEYXRhKSB7XG4gICAgICAgIGFwcEFwcGxlSWQgPSBkZWNvZGVkSldULmFwcERhdGEuYXBwQXBwbGVJZFxuICAgICAgICBidW5kbGVJZCA9IGRlY29kZWRKV1QuYXBwRGF0YS5idW5kbGVJZFxuICAgICAgICBlbnZpcm9ubWVudCA9IGRlY29kZWRKV1QuYXBwRGF0YS5lbnZpcm9ubWVudFxuICAgICAgfVxuICAgICAgdGhpcy52ZXJpZnlOb3RpZmljYXRpb24oYnVuZGxlSWQsIGFwcEFwcGxlSWQsIGVudmlyb25tZW50KVxuICAgICAgcmV0dXJuIGRlY29kZWRKV1RcbiAgICB9XG5cbiAgICBwcm90ZWN0ZWQgdmVyaWZ5Tm90aWZpY2F0aW9uKGJ1bmRsZUlkPzogc3RyaW5nLCBhcHBBcHBsZUlkPzogbnVtYmVyLCBlbnZpcm9ubWVudD86IHN0cmluZykge1xuICAgICAgaWYgKHRoaXMuYnVuZGxlSWQgIT09IGJ1bmRsZUlkIHx8ICh0aGlzLmVudmlyb25tZW50ID09PSBFbnZpcm9ubWVudC5QUk9EVUNUSU9OICYmIHRoaXMuYXBwQXBwbGVJZCAhPT0gYXBwQXBwbGVJZCkpIHtcbiAgICAgICAgdGhyb3cgbmV3IFZlcmlmaWNhdGlvbkV4Y2VwdGlvbihWZXJpZmljYXRpb25TdGF0dXMuSU5WQUxJRF9BUFBfSURFTlRJRklFUilcbiAgICAgIH1cbiAgICAgIGlmICh0aGlzLmVudmlyb25tZW50ICE9PSBlbnZpcm9ubWVudCkge1xuICAgICAgICB0aHJvdyBuZXcgVmVyaWZpY2F0aW9uRXhjZXB0aW9uKFZlcmlmaWNhdGlvblN0YXR1cy5JTlZBTElEX0VOVklST05NRU5UKVxuICAgICAgfVxuICAgIH1cblxuICAgIC8qKlxuICAgICAqIFZlcmlmaWVzIGFuZCBkZWNvZGVzIGEgc2lnbmVkIEFwcFRyYW5zYWN0aW9uXG4gICAgICogU2VlIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9zdG9yZWtpdC9hcHB0cmFuc2FjdGlvbiBBcHBUcmFuc2FjdGlvbn1cbiAgICAgKlxuICAgICAqIEBwYXJhbSBzaWduZWRBcHBUcmFuc2FjdGlvbiBUaGUgc2lnbmVkIEFwcFRyYW5zYWN0aW9uXG4gICAgICogQHJldHVybnMgVGhlIGRlY29kZWQgQXBwVHJhbnNhY3Rpb24gYWZ0ZXIgdmFsaWRhdGlvblxuICAgICAqIEB0aHJvd3MgVmVyaWZpY2F0aW9uRXhjZXB0aW9uIFRocm93biBpZiB0aGUgZGF0YSBjb3VsZCBub3QgYmUgdmVyaWZpZWRcbiAgICAgKi9cbiAgICBhc3luYyB2ZXJpZnlBbmREZWNvZGVBcHBUcmFuc2FjdGlvbihzaWduZWRBcHBUcmFuc2FjdGlvbjogc3RyaW5nKTogUHJvbWlzZTxBcHBUcmFuc2FjdGlvbj4ge1xuICAgICAgY29uc3QgZGVjb2RlZEFwcFRyYW5zYWN0aW9uOiBBcHBUcmFuc2FjdGlvbiA9IGF3YWl0IHRoaXMudmVyaWZ5SldUKHNpZ25lZEFwcFRyYW5zYWN0aW9uLCB0aGlzLmFwcFRyYW5zYWN0aW9uVmFsaWRhdG9yLCB0ID0+IHQucmVjZWlwdENyZWF0aW9uRGF0ZSA9PT0gdW5kZWZpbmVkID8gbmV3IERhdGUoKSA6IG5ldyBEYXRlKHQucmVjZWlwdENyZWF0aW9uRGF0ZSkpO1xuICAgICAgY29uc3QgZW52aXJvbm1lbnQgPSBkZWNvZGVkQXBwVHJhbnNhY3Rpb24ucmVjZWlwdFR5cGVcbiAgICAgIGlmICh0aGlzLmJ1bmRsZUlkICE9PSBkZWNvZGVkQXBwVHJhbnNhY3Rpb24uYnVuZGxlSWQgfHwgKHRoaXMuZW52aXJvbm1lbnQgPT09IEVudmlyb25tZW50LlBST0RVQ1RJT04gJiYgdGhpcy5hcHBBcHBsZUlkICE9PSBkZWNvZGVkQXBwVHJhbnNhY3Rpb24uYXBwQXBwbGVJZCkpIHtcbiAgICAgICAgdGhyb3cgbmV3IFZlcmlmaWNhdGlvbkV4Y2VwdGlvbihWZXJpZmljYXRpb25TdGF0dXMuSU5WQUxJRF9BUFBfSURFTlRJRklFUilcbiAgICAgIH1cbiAgICAgIGlmICh0aGlzLmVudmlyb25tZW50ICE9PSBlbnZpcm9ubWVudCkge1xuICAgICAgICB0aHJvdyBuZXcgVmVyaWZpY2F0aW9uRXhjZXB0aW9uKFZlcmlmaWNhdGlvblN0YXR1cy5JTlZBTElEX0VOVklST05NRU5UKVxuICAgICAgfVxuICAgICAgcmV0dXJuIGRlY29kZWRBcHBUcmFuc2FjdGlvblxuICAgIH1cblxuICAgIC8qKlxuICAgICAqIFZlcmlmaWVzIGFuZCBkZWNvZGVzIGEgUmV0ZW50aW9uIE1lc3NhZ2luZyBBUEkgc2lnbmVkUGF5bG9hZFxuICAgICAqIFNlZSB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL3NpZ25lZHBheWxvYWQgc2lnbmVkUGF5bG9hZH1cbiAgICAgKlxuICAgICAqIEBwYXJhbSBzaWduZWRQYXlsb2FkIFRoZSBwYXlsb2FkIHJlY2VpdmVkIGJ5IHlvdXIgc2VydmVyXG4gICAgICogQHJldHVybnMgVGhlIGRlY29kZWQgcGF5bG9hZCBhZnRlciB2ZXJpZmljYXRpb25cbiAgICAgKiBAdGhyb3dzIFZlcmlmaWNhdGlvbkV4Y2VwdGlvbiBUaHJvd24gaWYgdGhlIGRhdGEgY291bGQgbm90IGJlIHZlcmlmaWVkXG4gICAgICovXG4gICAgYXN5bmMgdmVyaWZ5QW5kRGVjb2RlUmVhbHRpbWVSZXF1ZXN0KHNpZ25lZFBheWxvYWQ6IHN0cmluZyk6IFByb21pc2U8RGVjb2RlZFJlYWx0aW1lUmVxdWVzdEJvZHk+IHtcbiAgICAgIGNvbnN0IGRlY29kZWRSZXF1ZXN0OiBEZWNvZGVkUmVhbHRpbWVSZXF1ZXN0Qm9keSA9IGF3YWl0IHRoaXMudmVyaWZ5SldUKHNpZ25lZFBheWxvYWQsIHRoaXMuZGVjb2RlZFJlYWx0aW1lUmVxdWVzdEJvZHlWYWxpZGF0b3IsIHRoaXMuZXh0cmFjdFNpZ25lZERhdGUpO1xuICAgICAgaWYgKHRoaXMuZW52aXJvbm1lbnQgPT09IEVudmlyb25tZW50LlBST0RVQ1RJT04gJiYgdGhpcy5hcHBBcHBsZUlkICE9PSBkZWNvZGVkUmVxdWVzdC5hcHBBcHBsZUlkKSB7XG4gICAgICAgIHRocm93IG5ldyBWZXJpZmljYXRpb25FeGNlcHRpb24oVmVyaWZpY2F0aW9uU3RhdHVzLklOVkFMSURfQVBQX0lERU5USUZJRVIpXG4gICAgICB9XG4gICAgICBpZiAodGhpcy5lbnZpcm9ubWVudCAhPT0gZGVjb2RlZFJlcXVlc3QuZW52aXJvbm1lbnQpIHtcbiAgICAgICAgdGhyb3cgbmV3IFZlcmlmaWNhdGlvbkV4Y2VwdGlvbihWZXJpZmljYXRpb25TdGF0dXMuSU5WQUxJRF9FTlZJUk9OTUVOVClcbiAgICAgIH1cbiAgICAgIHJldHVybiBkZWNvZGVkUmVxdWVzdFxuICAgIH1cblxuICAgIHByb3RlY3RlZCBhc3luYyB2ZXJpZnlKV1Q8VD4oand0OiBzdHJpbmcsIHZhbGlkYXRvcjogVmFsaWRhdG9yPFQ+LCBzaWduZWREYXRlRXh0cmFjdG9yOiAoZGVjb2RlZEpXVDogVCkgPT4gRGF0ZSk6IFByb21pc2U8VD4ge1xuICAgICAgbGV0IGNlcnRpZmljYXRlQ2hhaW47XG4gICAgICBsZXQgZGVjb2RlZEpXVFxuICAgICAgdHJ5IHtcbiAgICAgICAgZGVjb2RlZEpXVCA9IGpzb253ZWJ0b2tlbi5kZWNvZGUoand0KVxuICAgICAgICBpZiAoIXZhbGlkYXRvci52YWxpZGF0ZShkZWNvZGVkSldUKSkge1xuICAgICAgICAgIHRocm93IG5ldyBWZXJpZmljYXRpb25FeGNlcHRpb24oVmVyaWZpY2F0aW9uU3RhdHVzLkZBSUxVUkUpXG4gICAgICAgIH1cbiAgICAgICAgaWYgKHRoaXMuZW52aXJvbm1lbnQgPT09IEVudmlyb25tZW50LlhDT0RFIHx8IHRoaXMuZW52aXJvbm1lbnQgPT09IEVudmlyb25tZW50LkxPQ0FMX1RFU1RJTkcpIHtcbiAgICAgICAgICAvLyBEYXRhIGlzIG5vdCBzaWduZWQgYnkgdGhlIEFwcCBTdG9yZSwgYW5kIHZlcmlmaWNhdGlvbiBzaG91bGQgYmUgc2tpcHBlZFxuICAgICAgICAgIC8vIFRoZSBlbnZpcm9ubWVudCBNVVNUIGJlIGNoZWNrZWQgaW4gdGhlIHB1YmxpYyBtZXRob2QgY2FsbGluZyB0aGlzXG4gICAgICAgICAgcmV0dXJuIGRlY29kZWRKV1RcbiAgICAgICAgfVxuICAgICAgICB0cnkge1xuICAgICAgICAgIGNvbnN0IGhlYWRlciA9IGp3dC5zcGxpdCgnLicpWzBdXG4gICAgICAgICAgY29uc3QgZGVjb2RlZEhlYWRlciA9IGJhc2U2NHVybC5kZWNvZGUoaGVhZGVyKVxuICAgICAgICAgIGNvbnN0IGhlYWRlck9iaiA9IEpTT04ucGFyc2UoZGVjb2RlZEhlYWRlcilcbiAgICAgICAgICBjb25zdCBjaGFpbjogc3RyaW5nW10gPSBoZWFkZXJPYmpbJ3g1YyddID8/IFtdXG4gICAgICAgICAgaWYgKGNoYWluLmxlbmd0aCAhPSAzKSB7XG4gICAgICAgICAgICB0aHJvdyBuZXcgVmVyaWZpY2F0aW9uRXhjZXB0aW9uKFZlcmlmaWNhdGlvblN0YXR1cy5JTlZBTElEX0NIQUlOX0xFTkdUSClcbiAgICAgICAgICB9XG4gICAgICAgICAgY2VydGlmaWNhdGVDaGFpbiA9IGNoYWluLnNsaWNlKDAsIDIpLm1hcChjZXJ0ID0+IG5ldyBYNTA5Q2VydGlmaWNhdGUoQnVmZmVyLmZyb20oY2VydCwgJ2Jhc2U2NCcpKSlcbiAgICAgICAgfSBjYXRjaCAoZXJyb3IpIHtcbiAgICAgICAgICBpZiAoZXJyb3IgaW5zdGFuY2VvZiBFcnJvcikge1xuICAgICAgICAgICAgdGhyb3cgbmV3IFZlcmlmaWNhdGlvbkV4Y2VwdGlvbihWZXJpZmljYXRpb25TdGF0dXMuSU5WQUxJRF9DRVJUSUZJQ0FURSwgZXJyb3IpXG4gICAgICAgICAgfVxuICAgICAgICAgIHRocm93IG5ldyBWZXJpZmljYXRpb25FeGNlcHRpb24oVmVyaWZpY2F0aW9uU3RhdHVzLklOVkFMSURfQ0VSVElGSUNBVEUpXG4gICAgICAgIH1cbiAgICAgICAgY29uc3QgZWZmZWN0aXZlRGF0ZSA9IHRoaXMuZW5hYmxlT25saW5lQ2hlY2tzID8gbmV3IERhdGUoKSA6IHNpZ25lZERhdGVFeHRyYWN0b3IoZGVjb2RlZEpXVClcbiAgICAgICAgY29uc3QgcHVibGljS2V5ID0gYXdhaXQgdGhpcy52ZXJpZnlDZXJ0aWZpY2F0ZUNoYWluKHRoaXMucm9vdENlcnRpZmljYXRlcywgY2VydGlmaWNhdGVDaGFpblswXSwgY2VydGlmaWNhdGVDaGFpblsxXSwgZWZmZWN0aXZlRGF0ZSk7XG4gICAgICAgIGNvbnN0IGVuY29kZWRLZXkgPSBwdWJsaWNLZXkuZXhwb3J0KHtcbiAgICAgICAgICB0eXBlOiBcInNwa2lcIixcbiAgICAgICAgICBmb3JtYXQ6IFwicGVtXCJcbiAgICAgICAgfSk7XG4gICAgICAgIGpzb253ZWJ0b2tlbi52ZXJpZnkoand0LCBlbmNvZGVkS2V5KSBhcyBUXG4gICAgICAgIHJldHVybiBkZWNvZGVkSldUXG4gICAgICB9IGNhdGNoIChlcnJvcikge1xuICAgICAgICBpZiAoZXJyb3IgaW5zdGFuY2VvZiBWZXJpZmljYXRpb25FeGNlcHRpb24pIHtcbiAgICAgICAgICB0aHJvdyBlcnJvclxuICAgICAgICB9IGVsc2UgaWYgKGVycm9yIGluc3RhbmNlb2YgRXJyb3IpIHtcbiAgICAgICAgICB0aHJvdyBuZXcgVmVyaWZpY2F0aW9uRXhjZXB0aW9uKFZlcmlmaWNhdGlvblN0YXR1cy5WRVJJRklDQVRJT05fRkFJTFVSRSwgZXJyb3IpXG4gICAgICAgIH1cbiAgICAgICAgdGhyb3cgbmV3IFZlcmlmaWNhdGlvbkV4Y2VwdGlvbihWZXJpZmljYXRpb25TdGF0dXMuVkVSSUZJQ0FUSU9OX0ZBSUxVUkUpXG4gICAgICB9XG4gICAgfVxuXG4gICAgcHJvdGVjdGVkIGFzeW5jIHZlcmlmeUNlcnRpZmljYXRlQ2hhaW4odHJ1c3RlZFJvb3RzOiBYNTA5Q2VydGlmaWNhdGVbXSwgbGVhZjogWDUwOUNlcnRpZmljYXRlLCBpbnRlcm1lZGlhdGU6IFg1MDlDZXJ0aWZpY2F0ZSwgZWZmZWN0aXZlRGF0ZTogRGF0ZSk6IFByb21pc2U8S2V5T2JqZWN0PiB7XG4gICAgICBsZXQgY2FjaGVLZXkgPSBsZWFmLnRvU3RyaW5nKCkgKyBpbnRlcm1lZGlhdGUudG9TdHJpbmcoKVxuICAgICAgaWYgKHRoaXMuZW5hYmxlT25saW5lQ2hlY2tzKSB7XG4gICAgICAgIGlmIChjYWNoZUtleSBpbiB0aGlzLnZlcmlmaWVkUHVibGljS2V5Q2FjaGUpIHtcbiAgICAgICAgICBpZiAodGhpcy52ZXJpZmllZFB1YmxpY0tleUNhY2hlW2NhY2hlS2V5XS5jYWNoZUV4cGlyeSA+IG5ldyBEYXRlKCkuZ2V0VGltZSgpKSB7XG4gICAgICAgICAgICByZXR1cm4gdGhpcy52ZXJpZmllZFB1YmxpY0tleUNhY2hlW2NhY2hlS2V5XS5wdWJsaWNLZXlcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH1cblxuICAgICAgbGV0IHB1YmxpY0tleSA9IGF3YWl0IHRoaXMudmVyaWZ5Q2VydGlmaWNhdGVDaGFpbldpdGhvdXRDYWNoaW5nKHRydXN0ZWRSb290cywgbGVhZiwgaW50ZXJtZWRpYXRlLCBlZmZlY3RpdmVEYXRlKVxuXG4gICAgICBpZiAodGhpcy5lbmFibGVPbmxpbmVDaGVja3MpIHtcbiAgICAgICAgdGhpcy52ZXJpZmllZFB1YmxpY0tleUNhY2hlW2NhY2hlS2V5XSA9IG5ldyBDYWNoZVZhbHVlKGxlYWYucHVibGljS2V5LCBuZXcgRGF0ZSgpLmdldFRpbWUoKSArIENBQ0hFX1RJTUVfTElNSVQpXG4gICAgICAgIGlmIChPYmplY3Qua2V5cyh0aGlzLnZlcmlmaWVkUHVibGljS2V5Q2FjaGUpLmxlbmd0aCA+IE1BWElNVU1fQ0FDSEVfU0laRSkge1xuICAgICAgICAgIGZvciAobGV0IGtleSBpbiBPYmplY3Qua2V5cyh0aGlzLnZlcmlmaWVkUHVibGljS2V5Q2FjaGUpKSB7XG4gICAgICAgICAgICBpZiAodGhpcy52ZXJpZmllZFB1YmxpY0tleUNhY2hlW2tleV0uY2FjaGVFeHBpcnkgPCBuZXcgRGF0ZSgpLmdldFRpbWUoKSkge1xuICAgICAgICAgICAgICBkZWxldGUgdGhpcy52ZXJpZmllZFB1YmxpY0tleUNhY2hlW2tleV1cbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICAgIHJldHVybiBwdWJsaWNLZXlcbiAgICB9XG5cbiAgICBwcm90ZWN0ZWQgYXN5bmMgdmVyaWZ5Q2VydGlmaWNhdGVDaGFpbldpdGhvdXRDYWNoaW5nKHRydXN0ZWRSb290czogWDUwOUNlcnRpZmljYXRlW10sIGxlYWY6IFg1MDlDZXJ0aWZpY2F0ZSwgaW50ZXJtZWRpYXRlOiBYNTA5Q2VydGlmaWNhdGUsIGVmZmVjdGl2ZURhdGU6IERhdGUpOiBQcm9taXNlPEtleU9iamVjdD4ge1xuICAgICAgbGV0IHZhbGlkaXR5ID0gZmFsc2VcbiAgICAgIGxldCByb290Q2VydFxuICAgICAgZm9yIChjb25zdCByb290IG9mIHRydXN0ZWRSb290cykge1xuICAgICAgICBpZiAoaW50ZXJtZWRpYXRlLnZlcmlmeShyb290LnB1YmxpY0tleSkgJiYgaW50ZXJtZWRpYXRlLmlzc3VlciA9PT0gcm9vdC5zdWJqZWN0KSB7XG4gICAgICAgICAgdmFsaWRpdHkgPSB0cnVlXG4gICAgICAgICAgcm9vdENlcnQgPSByb290XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICAgIHZhbGlkaXR5ID0gdmFsaWRpdHkgJiYgbGVhZi52ZXJpZnkoaW50ZXJtZWRpYXRlLnB1YmxpY0tleSkgJiYgbGVhZi5pc3N1ZXIgPT09IGludGVybWVkaWF0ZS5zdWJqZWN0XG4gICAgICB2YWxpZGl0eSA9IHZhbGlkaXR5ICYmIGludGVybWVkaWF0ZS5jYVxuICAgICAgY29uc3QganNyc2Fzc2lnblg1MDlMZWFmID0gbmV3IFg1MDkoKVxuICAgICAganNyc2Fzc2lnblg1MDlMZWFmLnJlYWRDZXJ0SGV4KGxlYWYucmF3LnRvU3RyaW5nKCdoZXgnKSlcbiAgICAgIGNvbnN0IGpzcmFzc2lnblg1MDlJbnRlcm1lZGlhdGUgPSBuZXcgWDUwOSgpXG4gICAgICBqc3Jhc3NpZ25YNTA5SW50ZXJtZWRpYXRlLnJlYWRDZXJ0SGV4KGludGVybWVkaWF0ZS5yYXcudG9TdHJpbmcoJ2hleCcpKVxuICAgICAgdmFsaWRpdHkgPSB2YWxpZGl0eSAmJiBqc3JzYXNzaWduWDUwOUxlYWYuZ2V0RXh0SW5mbyhcIjEuMi44NDAuMTEzNjM1LjEwMC42LjExLjFcIikgIT09IHVuZGVmaW5lZFxuICAgICAgdmFsaWRpdHkgPSB2YWxpZGl0eSAmJiBqc3Jhc3NpZ25YNTA5SW50ZXJtZWRpYXRlLmdldEV4dEluZm8oXCIxLjIuODQwLjExMzYzNS4xMDAuNi4yLjFcIikgIT09IHVuZGVmaW5lZFxuICAgICAgaWYgKCF2YWxpZGl0eSkge1xuICAgICAgICB0aHJvdyBuZXcgVmVyaWZpY2F0aW9uRXhjZXB0aW9uKFZlcmlmaWNhdGlvblN0YXR1cy5WRVJJRklDQVRJT05fRkFJTFVSRSk7XG4gICAgICB9XG4gICAgICByb290Q2VydCA9IHJvb3RDZXJ0IGFzIFg1MDlDZXJ0aWZpY2F0ZVxuICAgICAgdGhpcy5jaGVja0RhdGVzKGxlYWYsIGVmZmVjdGl2ZURhdGUpXG4gICAgICB0aGlzLmNoZWNrRGF0ZXMoaW50ZXJtZWRpYXRlLCBlZmZlY3RpdmVEYXRlKVxuICAgICAgdGhpcy5jaGVja0RhdGVzKHJvb3RDZXJ0LCBlZmZlY3RpdmVEYXRlKVxuICAgICAgaWYgKHRoaXMuZW5hYmxlT25saW5lQ2hlY2tzKSB7XG4gICAgICAgIGF3YWl0IFByb21pc2UuYWxsKFt0aGlzLmNoZWNrT0NTUFN0YXR1cyhsZWFmLCBpbnRlcm1lZGlhdGUpLCB0aGlzLmNoZWNrT0NTUFN0YXR1cyhpbnRlcm1lZGlhdGUsIHJvb3RDZXJ0KV0pXG4gICAgICB9XG4gICAgICByZXR1cm4gbGVhZi5wdWJsaWNLZXlcbiAgICB9XG4gICAgcHJvdGVjdGVkIGFzeW5jIGNoZWNrT0NTUFN0YXR1cyhjZXJ0OiBYNTA5Q2VydGlmaWNhdGUsIGlzc3VlcjogWDUwOUNlcnRpZmljYXRlKTogUHJvbWlzZTx2b2lkPiB7XG4gICAgICBjb25zdCBhdXRob3JpdHlSZXggPSAvXk9DU1AgLSBVUkk6KC4qKSQvbVxuICAgICAgY29uc3QgbWF0Y2hSZXN1bHQgPSBjZXJ0LmluZm9BY2Nlc3MgPyBhdXRob3JpdHlSZXguZXhlYyhjZXJ0LmluZm9BY2Nlc3MpIDogXCJcIlxuICAgICAgaWYgKG1hdGNoUmVzdWx0ID09PSBudWxsIHx8IG1hdGNoUmVzdWx0Lmxlbmd0aCAhPT0gMikge1xuICAgICAgICB0aHJvdyBuZXcgVmVyaWZpY2F0aW9uRXhjZXB0aW9uKFZlcmlmaWNhdGlvblN0YXR1cy5JTlZBTElEX0NFUlRJRklDQVRFKVxuICAgICAgfVxuICAgICAgY29uc3QgcmVxdWVzdCA9IG5ldyBLSlVSLmFzbjEub2NzcC5PQ1NQUmVxdWVzdCh7cmVxTGlzdDogW3tpc3N1ZXJDZXJ0OiBpc3N1ZXIudG9TdHJpbmcoKSwgc3ViamVjdENlcnQ6IGNlcnQudG9TdHJpbmcoKSAsIGFsZzogXCJzaGEyNTZcIn1dfSlcbiAgICAgIGNvbnN0IGhlYWRlcnMgPSBuZXcgSGVhZGVycygpXG4gICAgICBoZWFkZXJzLmFwcGVuZCgnQ29udGVudC1UeXBlJywgJ2FwcGxpY2F0aW9uL29jc3AtcmVxdWVzdCcpXG5cbiAgICAgIGxldCByZXNwb25zZVxuICAgICAgdHJ5IHtcbiAgICAgICAgcmVzcG9uc2UgPSBhd2FpdCBmZXRjaChtYXRjaFJlc3VsdFsxXSwge1xuICAgICAgICAgIGhlYWRlcnM6IGhlYWRlcnMsXG4gICAgICAgICAgbWV0aG9kOiAnUE9TVCcsXG4gICAgICAgICAgYm9keTogQnVmZmVyLmZyb20ocmVxdWVzdC5nZXRFbmNvZGVkSGV4KCksICdoZXgnKSxcbiAgICAgICAgICB0aW1lb3V0OiAzMDAwMFxuICAgICAgICB9KVxuXG4gICAgICAgIGlmICghcmVzcG9uc2Uub2spIHtcbiAgICAgICAgICB0aHJvdyBuZXcgVmVyaWZpY2F0aW9uRXhjZXB0aW9uKFZlcmlmaWNhdGlvblN0YXR1cy5SRVRSWUFCTEVfVkVSSUZJQ0FUSU9OX0ZBSUxVUkUpXG4gICAgICAgIH1cbiAgICAgIH0gY2F0Y2ggKGVycm9yKSB7XG4gICAgICAgIGlmIChlcnJvciBpbnN0YW5jZW9mIFZlcmlmaWNhdGlvbkV4Y2VwdGlvbikge1xuICAgICAgICAgIHRocm93IGVycm9yXG4gICAgICAgIH1cbiAgICAgICAgLy8gTmV0d29yayBlcnJvcnNcbiAgICAgICAgdGhyb3cgbmV3IFZlcmlmaWNhdGlvbkV4Y2VwdGlvbihWZXJpZmljYXRpb25TdGF0dXMuUkVUUllBQkxFX1ZFUklGSUNBVElPTl9GQUlMVVJFLCBlcnJvciBpbnN0YW5jZW9mIEVycm9yID8gZXJyb3IgOiB1bmRlZmluZWQpXG4gICAgICB9XG5cbiAgICAgIGNvbnN0IHJlc3BvbnNlQnVmZmVyID0gYXdhaXQgcmVzcG9uc2UuYnVmZmVyKClcbiAgICAgIGNvbnN0IHBhcnNlZFJlc3BvbnNlID0gbmV3IChLSlVSLmFzbjEub2NzcCBhcyBhbnkpLk9DU1BQYXJzZXIoKS5nZXRPQ1NQUmVzcG9uc2UocmVzcG9uc2VCdWZmZXIudG9TdHJpbmcoJ2hleCcpKVxuICAgICAgLy8gVGhlIGlzc3VlciBjb3VsZCBhbHNvIGJlIHRoZSBzaWduZXJcbiAgICAgIGNvbnN0IGpzcmFzc2lnblg1MDlJc3N1ZXIgPSBuZXcgWDUwOSgpXG4gICAgICBqc3Jhc3NpZ25YNTA5SXNzdWVyLnJlYWRDZXJ0SGV4KGlzc3Vlci5yYXcudG9TdHJpbmcoJ2hleCcpKVxuICAgICAgY29uc3QgYWxsQ2VydHM6IFg1MDlbXSA9IFtqc3Jhc3NpZ25YNTA5SXNzdWVyXVxuICAgICAgZm9yIChjb25zdCBjZXJ0SGV4IG9mIHBhcnNlZFJlc3BvbnNlLmNlcnRzKSB7XG4gICAgICAgIGNvbnN0IGNlcnQgPSBuZXcgWDUwOSgpXG4gICAgICAgIGNlcnQucmVhZENlcnRIZXgoY2VydEhleClcbiAgICAgICAgYWxsQ2VydHMucHVzaChjZXJ0KVxuICAgICAgfVxuICAgICAgbGV0IHNpZ25pbmdDZXJ0OiBYNTA5Q2VydGlmaWNhdGUgfCBudWxsID0gbnVsbFxuICAgICAgaWYgKHBhcnNlZFJlc3BvbnNlLnJlc3BpZC5rZXkpIHtcbiAgICAgICAgZm9yIChjb25zdCBjZXJ0IG9mIGFsbENlcnRzKSB7XG4gICAgICAgICAgY29uc3Qgc2hhc3VtID0gY3JlYXRlSGFzaCgnc2hhMScpXG4gICAgICAgICAgc2hhc3VtLnVwZGF0ZShCdWZmZXIuZnJvbShjZXJ0LmdldFNQS0lWYWx1ZSgpLCAnaGV4JykpXG4gICAgICAgICAgY29uc3Qgc3BraUhhc2ggPSBzaGFzdW0uZGlnZXN0KCdoZXgnKVxuICAgICAgICAgIGlmIChzcGtpSGFzaCA9PT0gcGFyc2VkUmVzcG9uc2UucmVzcGlkLmtleSkge1xuICAgICAgICAgICAgc2lnbmluZ0NlcnQgPSBuZXcgWDUwOUNlcnRpZmljYXRlKEJ1ZmZlci5mcm9tKGNlcnQuaGV4LCAnaGV4JykpXG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9IGVsc2UgaWYgKHBhcnNlZFJlc3BvbnNlLnJlc3BpZC5uYW1lKSB7XG4gICAgICAgIGZvciAoY29uc3QgY2VydCBvZiBhbGxDZXJ0cykge1xuICAgICAgICAgIGlmIChjZXJ0LmdldFN1YmplY3QoKS5zdHIgPT09IHBhcnNlZFJlc3BvbnNlLnJlc3BpZC5uYW1lLnN0cikge1xuICAgICAgICAgICAgc2lnbmluZ0NlcnQgPSBuZXcgWDUwOUNlcnRpZmljYXRlKEJ1ZmZlci5mcm9tKGNlcnQuaGV4LCAnaGV4JykpXG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9XG4gICAgICBpZiAoc2lnbmluZ0NlcnQgPT0gbnVsbCkge1xuICAgICAgICB0aHJvdyBuZXcgVmVyaWZpY2F0aW9uRXhjZXB0aW9uKFZlcmlmaWNhdGlvblN0YXR1cy5GQUlMVVJFKVxuICAgICAgfVxuICAgICAgLy8gVmVyaWZ5IFNpZ25pbmcgQ2VydCBpcyBpc3N1ZWQgYnkgaXNzdWVyXG4gICAgICBpZiAoc2lnbmluZ0NlcnQucHVibGljS2V5ID09PSBpc3N1ZXIucHVibGljS2V5ICYmIHNpZ25pbmdDZXJ0LnN1YmplY3QgPT09IGlzc3Vlci5zdWJqZWN0KSB7XG4gICAgICAgIC8vIFRoaXMgaXMgZGlyZWN0bHkgc2lnbmVkIGJ5IHRoZSBpc3N1ZXJcbiAgICAgIH0gZWxzZSBpZiAoc2lnbmluZ0NlcnQudmVyaWZ5KGlzc3Vlci5wdWJsaWNLZXkpKSB7XG4gICAgICAgIC8vIFRoaXMgaXMgaXNzdWVkIGJ5IHRoZSBpc3N1ZXIsIGxldCdzIGNoZWNrIHRoZSBkYXRlcyBhbmQgcHVycG9zZVxuICAgICAgICBjb25zdCBzaWduaW5nQ2VydEFzc2lnbiA9IG5ldyBYNTA5KClcbiAgICAgICAgc2lnbmluZ0NlcnRBc3NpZ24ucmVhZENlcnRQRU0oc2lnbmluZ0NlcnQudG9TdHJpbmcoKSlcbiAgICAgICAgaWYgKCFzaWduaW5nQ2VydEFzc2lnbi5nZXRFeHRFeHRLZXlVc2FnZSgpLmFycmF5LmluY2x1ZGVzKFwib2NzcFNpZ25pbmdcIikpIHtcbiAgICAgICAgICB0aHJvdyBuZXcgVmVyaWZpY2F0aW9uRXhjZXB0aW9uKFZlcmlmaWNhdGlvblN0YXR1cy5JTlZBTElEX0NFUlRJRklDQVRFKVxuICAgICAgICB9XG4gICAgICAgIHRoaXMuY2hlY2tEYXRlcyhzaWduaW5nQ2VydCwgbmV3IERhdGUoKSlcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIHRocm93IG5ldyBWZXJpZmljYXRpb25FeGNlcHRpb24oVmVyaWZpY2F0aW9uU3RhdHVzLklOVkFMSURfQ0VSVElGSUNBVEUpXG4gICAgICB9XG4gICAgXG4gICAgICAvLyBFeHRyYWN0IHJhdyByZXNwb25zZURhdGFcbiAgICAgIGNvbnN0IHJlc3BvbnNlRGF0YSA9IEFTTjFIRVguZ2V0VExWYnlMaXN0KHJlc3BvbnNlQnVmZmVyLnRvU3RyaW5nKCdoZXgnKSwgMCwgWzEsIDAsIDEsIDAsIDBdKSBhcyBzdHJpbmdcbiAgICAgIC8vIFZlcmlmeSBQYXlsb2FkIHNpZ25lZCBieSBjZXJ0XG4gICAgICBjb25zdCBzaG9ydEFsZyA9IHBhcnNlZFJlc3BvbnNlLmFsZy5zdWJzdHJpbmcoMCwgNikudG9VcHBlckNhc2UoKVxuICAgICAgaWYgKHNob3J0QWxnICE9PSBcIlNIQTI1NlwiICYmIHNob3J0QWxnICE9PSBcIlNIQTM4NFwiICYmIHNob3J0QWxnICE9PSBcIlNIQTUxMlwiKSB7XG4gICAgICAgIHRocm93IG5ldyBWZXJpZmljYXRpb25FeGNlcHRpb24oVmVyaWZpY2F0aW9uU3RhdHVzLkZBSUxVUkUpXG4gICAgICB9XG5cbiAgICAgIGlmICghdmVyaWZ5KHNob3J0QWxnLCBCdWZmZXIuZnJvbShyZXNwb25zZURhdGEsICdoZXgnKSwgc2lnbmluZ0NlcnQucHVibGljS2V5LCBCdWZmZXIuZnJvbShwYXJzZWRSZXNwb25zZS5zaWdoZXgsICdoZXgnKSkpIHtcbiAgICAgICAgdGhyb3cgbmV3IFZlcmlmaWNhdGlvbkV4Y2VwdGlvbihWZXJpZmljYXRpb25TdGF0dXMuRkFJTFVSRSlcbiAgICAgIH1cbiAgICAgIFxuICAgICAgZm9yIChjb25zdCBzaW5nbGVSZXNwb25zZSBvZiBwYXJzZWRSZXNwb25zZS5hcnJheSkge1xuICAgICAgICAvLyBDb25maXJtIGVudHJ5IGlzIGZvciB0aGlzIGNlcnRcbiAgICAgICAgY29uc3QgY2VydElkQnVpbGRlciA9IG5ldyBLSlVSLmFzbjEub2NzcC5DZXJ0SUQoKSBhcyBhbnlcbiAgICAgICAgY29uc3QgY3VycmVudENlcnRDZXJ0SWQgPSBjZXJ0SWRCdWlsZGVyLmdldFBhcmFtQnlDZXJ0cyhpc3N1ZXIudG9TdHJpbmcoKSwgY2VydC50b1N0cmluZygpLCAnc2hhMjU2JylcbiAgICAgICAgaWYgKCEoY3VycmVudENlcnRDZXJ0SWQuYWxnID09PSBzaW5nbGVSZXNwb25zZS5jZXJ0aWQuYWxnICYmIGN1cnJlbnRDZXJ0Q2VydElkLmlzc25hbWUgPT09IHNpbmdsZVJlc3BvbnNlLmNlcnRpZC5pc3NuYW1lICYmXG4gICAgICAgICAgICAgIGN1cnJlbnRDZXJ0Q2VydElkLmlzc2tleSA9PT0gc2luZ2xlUmVzcG9uc2UuY2VydGlkLmlzc2tleSAmJiBjdXJyZW50Q2VydENlcnRJZC5zYmpzbiA9PT0gc2luZ2xlUmVzcG9uc2UuY2VydGlkLnNianNuKSkge1xuICAgICAgICAgIGNvbnRpbnVlXG4gICAgICAgIH1cbiAgICAgICAgLy8gVmFsaWRhdGUgY29udGVudHNcbiAgICAgICAgY29uc3QgaXNzdWVEYXRlID0gdGhpcy5wYXJzZVg1MDlEYXRlKHNpbmdsZVJlc3BvbnNlLnRoaXN1cGRhdGUpXG4gICAgICAgIGNvbnN0IG5leHREYXRlID0gdGhpcy5wYXJzZVg1MDlEYXRlKHNpbmdsZVJlc3BvbnNlLm5leHR1cGRhdGUpXG4gICAgICAgIFxuICAgICAgICBpZiAoc2luZ2xlUmVzcG9uc2Uuc3RhdHVzLnN0YXR1cyAhPT0gJ2dvb2QnIHx8IG5ldyBEYXRlKCkuZ2V0VGltZSgpICsgTUFYX1NLRVcgPCBpc3N1ZURhdGUuZ2V0VGltZSgpIHx8IG5leHREYXRlLmdldFRpbWUoKSA8IG5ldyBEYXRlKCkuZ2V0VGltZSgpIC0gTUFYX1NLRVcpIHtcbiAgICAgICAgICB0aHJvdyBuZXcgVmVyaWZpY2F0aW9uRXhjZXB0aW9uKFZlcmlmaWNhdGlvblN0YXR1cy5GQUlMVVJFKVxuICAgICAgICB9XG4gICAgICAgIC8vIFN1Y2Nlc3NcbiAgICAgICAgcmV0dXJuXG4gICAgICB9XG4gICAgICB0aHJvdyBuZXcgVmVyaWZpY2F0aW9uRXhjZXB0aW9uKFZlcmlmaWNhdGlvblN0YXR1cy5GQUlMVVJFKVxuICAgIH1cblxuICAgIHByaXZhdGUgY2hlY2tEYXRlcyhjZXJ0OiBYNTA5Q2VydGlmaWNhdGUsIGVmZmVjdGl2ZURhdGU6IERhdGUpIHtcbiAgICAgIGlmIChuZXcgRGF0ZShjZXJ0LnZhbGlkRnJvbSkuZ2V0VGltZSgpID4gKGVmZmVjdGl2ZURhdGUuZ2V0VGltZSgpICsgTUFYX1NLRVcpfHxcbiAgICAgICAgICBuZXcgRGF0ZShjZXJ0LnZhbGlkVG8pLmdldFRpbWUoKSA8IChlZmZlY3RpdmVEYXRlLmdldFRpbWUoKSAtIE1BWF9TS0VXKSkge1xuICAgICAgICB0aHJvdyBuZXcgVmVyaWZpY2F0aW9uRXhjZXB0aW9uKFZlcmlmaWNhdGlvblN0YXR1cy5JTlZBTElEX0NFUlRJRklDQVRFKVxuICAgICAgfVxuICAgIH1cblxuICAgIHByaXZhdGUgcGFyc2VYNTA5RGF0ZShkYXRlOiBzdHJpbmcpIHtcbiAgICAgIHJldHVybiBuZXcgRGF0ZShkYXRlLnJlcGxhY2UoXG4gICAgICAgIC9eKFxcZHs0fSkoXFxkXFxkKShcXGRcXGQpKFxcZFxcZCkoXFxkXFxkKShcXGRcXGQpJC8sXG4gICAgICAgICckNDokNTokNiAkMi8kMy8kMSdcbiAgICAgICkpO1xuICAgIH1cblxuICAgIHByaXZhdGUgZXh0cmFjdFNpZ25lZERhdGUoZGVjb2RlZEpXVDogRGVjb2RlZFNpZ25lZERhdGEpOiBEYXRlIHtcbiAgICAgIHJldHVybiBkZWNvZGVkSldULnNpZ25lZERhdGUgPT09IHVuZGVmaW5lZCA/IG5ldyBEYXRlKCkgOiBuZXcgRGF0ZShkZWNvZGVkSldULnNpZ25lZERhdGUpXG4gICAgfVxufVxuXG5leHBvcnQgZW51bSBWZXJpZmljYXRpb25TdGF0dXMge1xuICBPSyxcbiAgVkVSSUZJQ0FUSU9OX0ZBSUxVUkUsXG4gIFJFVFJZQUJMRV9WRVJJRklDQVRJT05fRkFJTFVSRSxcbiAgSU5WQUxJRF9BUFBfSURFTlRJRklFUixcbiAgSU5WQUxJRF9FTlZJUk9OTUVOVCxcbiAgSU5WQUxJRF9DSEFJTl9MRU5HVEgsXG4gIElOVkFMSURfQ0VSVElGSUNBVEUsXG4gIEZBSUxVUkVcbn1cblxuZXhwb3J0IGNsYXNzIFZlcmlmaWNhdGlvbkV4Y2VwdGlvbiBleHRlbmRzIEVycm9yIHtcbiAgc3RhdHVzOiBWZXJpZmljYXRpb25TdGF0dXNcbiAgY2F1c2U/OiBFcnJvclxuXG4gIGNvbnN0cnVjdG9yKHN0YXR1czogVmVyaWZpY2F0aW9uU3RhdHVzLCBjYXVzZT86IEVycm9yKSB7XG4gICAgc3VwZXIoKTtcbiAgICB0aGlzLnN0YXR1cyA9IHN0YXR1c1xuICAgIHRoaXMuY2F1c2UgPSBjYXVzZVxuICB9XG59Il19