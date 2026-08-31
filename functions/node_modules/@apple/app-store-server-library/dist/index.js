"use strict";
// Copyright (c) 2023 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdvancedCommerceRefundReason = exports.AdvancedCommerceOfferReason = exports.AdvancedCommerceOfferPeriod = exports.AdvancedCommercePeriod = exports.AdvancedCommerceEffective = exports.AdvancedCommerceReason = exports.IntroductoryOfferEligibilitySignatureCreator = exports.AdvancedCommerceInAppSignatureCreator = exports.PromotionalOfferV2SignatureCreator = exports.PromotionalOfferSignatureCreator = exports.UserStatus = exports.Type = exports.TransactionReason = exports.ProductType = exports.Order = exports.Subtype = exports.Status = exports.RevocationReason = exports.RevocationType = exports.RefundPreferenceV1 = exports.RefundPreference = exports.PurchasePlatform = exports.PriceIncreaseStatus = exports.PlayTime = exports.Platform = exports.PerformanceTestStatus = exports.OrderLookupStatus = exports.OfferDiscountType = exports.OfferType = exports.NotificationTypeV2 = exports.MessageState = exports.LifetimeDollarsRefunded = exports.LifetimeDollarsPurchased = exports.InAppOwnershipType = exports.ImageSize = exports.ImageState = exports.SendAttemptResult = exports.HeaderPosition = exports.ExtendReasonCode = exports.ExpirationIntent = exports.Environment = exports.DeliveryStatusV1 = exports.DeliveryStatus = exports.ConsumptionStatus = exports.AutoRenewStatus = exports.AccountTenure = exports.ReceiptUtility = exports.VerificationStatus = exports.VerificationException = exports.SignedDataVerifier = void 0;
exports.GetTransactionHistoryVersion = exports.APIError = exports.APIException = exports.AppStoreServerAPIClient = exports.RenewalBillingPlanType = exports.BillingPlanType = exports.AdvancedCommercePriceIncreaseInfoStatus = exports.AdvancedCommerceRefundType = void 0;
const node_fetch_1 = require("node-fetch");
const CheckTestNotificationResponse_1 = require("./models/CheckTestNotificationResponse");
const DefaultConfigurationResponse_1 = require("./models/DefaultConfigurationResponse");
const Environment_1 = require("./models/Environment");
const ExtendRenewalDateResponse_1 = require("./models/ExtendRenewalDateResponse");
const GetImageListResponse_1 = require("./models/GetImageListResponse");
const GetMessageListResponse_1 = require("./models/GetMessageListResponse");
const HistoryResponse_1 = require("./models/HistoryResponse");
const MassExtendRenewalDateResponse_1 = require("./models/MassExtendRenewalDateResponse");
const MassExtendRenewalDateStatusResponse_1 = require("./models/MassExtendRenewalDateStatusResponse");
const OrderLookupResponse_1 = require("./models/OrderLookupResponse");
const RefundHistoryResponse_1 = require("./models/RefundHistoryResponse");
const SendTestNotificationResponse_1 = require("./models/SendTestNotificationResponse");
const StatusResponse_1 = require("./models/StatusResponse");
const TransactionInfoResponse_1 = require("./models/TransactionInfoResponse");
const PerformanceTestResponse_1 = require("./models/PerformanceTestResponse");
const PerformanceTestResultResponse_1 = require("./models/PerformanceTestResultResponse");
const RealtimeUrlResponse_1 = require("./models/RealtimeUrlResponse");
var jws_verification_1 = require("./jws_verification");
Object.defineProperty(exports, "SignedDataVerifier", { enumerable: true, get: function () { return jws_verification_1.SignedDataVerifier; } });
Object.defineProperty(exports, "VerificationException", { enumerable: true, get: function () { return jws_verification_1.VerificationException; } });
Object.defineProperty(exports, "VerificationStatus", { enumerable: true, get: function () { return jws_verification_1.VerificationStatus; } });
var receipt_utility_1 = require("./receipt_utility");
Object.defineProperty(exports, "ReceiptUtility", { enumerable: true, get: function () { return receipt_utility_1.ReceiptUtility; } });
var AccountTenure_1 = require("./models/AccountTenure");
Object.defineProperty(exports, "AccountTenure", { enumerable: true, get: function () { return AccountTenure_1.AccountTenure; } });
var AutoRenewStatus_1 = require("./models/AutoRenewStatus");
Object.defineProperty(exports, "AutoRenewStatus", { enumerable: true, get: function () { return AutoRenewStatus_1.AutoRenewStatus; } });
var ConsumptionStatus_1 = require("./models/ConsumptionStatus");
Object.defineProperty(exports, "ConsumptionStatus", { enumerable: true, get: function () { return ConsumptionStatus_1.ConsumptionStatus; } });
var DeliveryStatus_1 = require("./models/DeliveryStatus");
Object.defineProperty(exports, "DeliveryStatus", { enumerable: true, get: function () { return DeliveryStatus_1.DeliveryStatus; } });
var DeliveryStatusV1_1 = require("./models/DeliveryStatusV1");
Object.defineProperty(exports, "DeliveryStatusV1", { enumerable: true, get: function () { return DeliveryStatusV1_1.DeliveryStatusV1; } });
var Environment_2 = require("./models/Environment");
Object.defineProperty(exports, "Environment", { enumerable: true, get: function () { return Environment_2.Environment; } });
var ExpirationIntent_1 = require("./models/ExpirationIntent");
Object.defineProperty(exports, "ExpirationIntent", { enumerable: true, get: function () { return ExpirationIntent_1.ExpirationIntent; } });
var ExtendReasonCode_1 = require("./models/ExtendReasonCode");
Object.defineProperty(exports, "ExtendReasonCode", { enumerable: true, get: function () { return ExtendReasonCode_1.ExtendReasonCode; } });
var HeaderPosition_1 = require("./models/HeaderPosition");
Object.defineProperty(exports, "HeaderPosition", { enumerable: true, get: function () { return HeaderPosition_1.HeaderPosition; } });
var SendAttemptResult_1 = require("./models/SendAttemptResult");
Object.defineProperty(exports, "SendAttemptResult", { enumerable: true, get: function () { return SendAttemptResult_1.SendAttemptResult; } });
var ImageState_1 = require("./models/ImageState");
Object.defineProperty(exports, "ImageState", { enumerable: true, get: function () { return ImageState_1.ImageState; } });
var ImageSize_1 = require("./models/ImageSize");
Object.defineProperty(exports, "ImageSize", { enumerable: true, get: function () { return ImageSize_1.ImageSize; } });
var InAppOwnershipType_1 = require("./models/InAppOwnershipType");
Object.defineProperty(exports, "InAppOwnershipType", { enumerable: true, get: function () { return InAppOwnershipType_1.InAppOwnershipType; } });
var LifetimeDollarsPurchased_1 = require("./models/LifetimeDollarsPurchased");
Object.defineProperty(exports, "LifetimeDollarsPurchased", { enumerable: true, get: function () { return LifetimeDollarsPurchased_1.LifetimeDollarsPurchased; } });
var LifetimeDollarsRefunded_1 = require("./models/LifetimeDollarsRefunded");
Object.defineProperty(exports, "LifetimeDollarsRefunded", { enumerable: true, get: function () { return LifetimeDollarsRefunded_1.LifetimeDollarsRefunded; } });
var MessageState_1 = require("./models/MessageState");
Object.defineProperty(exports, "MessageState", { enumerable: true, get: function () { return MessageState_1.MessageState; } });
var NotificationTypeV2_1 = require("./models/NotificationTypeV2");
Object.defineProperty(exports, "NotificationTypeV2", { enumerable: true, get: function () { return NotificationTypeV2_1.NotificationTypeV2; } });
var OfferType_1 = require("./models/OfferType");
Object.defineProperty(exports, "OfferType", { enumerable: true, get: function () { return OfferType_1.OfferType; } });
var OfferDiscountType_1 = require("./models/OfferDiscountType");
Object.defineProperty(exports, "OfferDiscountType", { enumerable: true, get: function () { return OfferDiscountType_1.OfferDiscountType; } });
var OrderLookupStatus_1 = require("./models/OrderLookupStatus");
Object.defineProperty(exports, "OrderLookupStatus", { enumerable: true, get: function () { return OrderLookupStatus_1.OrderLookupStatus; } });
var PerformanceTestStatus_1 = require("./models/PerformanceTestStatus");
Object.defineProperty(exports, "PerformanceTestStatus", { enumerable: true, get: function () { return PerformanceTestStatus_1.PerformanceTestStatus; } });
var Platform_1 = require("./models/Platform");
Object.defineProperty(exports, "Platform", { enumerable: true, get: function () { return Platform_1.Platform; } });
var PlayTime_1 = require("./models/PlayTime");
Object.defineProperty(exports, "PlayTime", { enumerable: true, get: function () { return PlayTime_1.PlayTime; } });
var PriceIncreaseStatus_1 = require("./models/PriceIncreaseStatus");
Object.defineProperty(exports, "PriceIncreaseStatus", { enumerable: true, get: function () { return PriceIncreaseStatus_1.PriceIncreaseStatus; } });
var PurchasePlatform_1 = require("./models/PurchasePlatform");
Object.defineProperty(exports, "PurchasePlatform", { enumerable: true, get: function () { return PurchasePlatform_1.PurchasePlatform; } });
var RefundPreference_1 = require("./models/RefundPreference");
Object.defineProperty(exports, "RefundPreference", { enumerable: true, get: function () { return RefundPreference_1.RefundPreference; } });
var RefundPreferenceV1_1 = require("./models/RefundPreferenceV1");
Object.defineProperty(exports, "RefundPreferenceV1", { enumerable: true, get: function () { return RefundPreferenceV1_1.RefundPreferenceV1; } });
var RevocationType_1 = require("./models/RevocationType");
Object.defineProperty(exports, "RevocationType", { enumerable: true, get: function () { return RevocationType_1.RevocationType; } });
var RevocationReason_1 = require("./models/RevocationReason");
Object.defineProperty(exports, "RevocationReason", { enumerable: true, get: function () { return RevocationReason_1.RevocationReason; } });
var Status_1 = require("./models/Status");
Object.defineProperty(exports, "Status", { enumerable: true, get: function () { return Status_1.Status; } });
var Subtype_1 = require("./models/Subtype");
Object.defineProperty(exports, "Subtype", { enumerable: true, get: function () { return Subtype_1.Subtype; } });
var TransactionHistoryRequest_1 = require("./models/TransactionHistoryRequest");
Object.defineProperty(exports, "Order", { enumerable: true, get: function () { return TransactionHistoryRequest_1.Order; } });
Object.defineProperty(exports, "ProductType", { enumerable: true, get: function () { return TransactionHistoryRequest_1.ProductType; } });
var TransactionReason_1 = require("./models/TransactionReason");
Object.defineProperty(exports, "TransactionReason", { enumerable: true, get: function () { return TransactionReason_1.TransactionReason; } });
var Type_1 = require("./models/Type");
Object.defineProperty(exports, "Type", { enumerable: true, get: function () { return Type_1.Type; } });
var UserStatus_1 = require("./models/UserStatus");
Object.defineProperty(exports, "UserStatus", { enumerable: true, get: function () { return UserStatus_1.UserStatus; } });
var promotional_offer_1 = require("./promotional_offer");
Object.defineProperty(exports, "PromotionalOfferSignatureCreator", { enumerable: true, get: function () { return promotional_offer_1.PromotionalOfferSignatureCreator; } });
var jws_signature_creator_1 = require("./jws_signature_creator");
Object.defineProperty(exports, "PromotionalOfferV2SignatureCreator", { enumerable: true, get: function () { return jws_signature_creator_1.PromotionalOfferV2SignatureCreator; } });
Object.defineProperty(exports, "AdvancedCommerceInAppSignatureCreator", { enumerable: true, get: function () { return jws_signature_creator_1.AdvancedCommerceInAppSignatureCreator; } });
Object.defineProperty(exports, "IntroductoryOfferEligibilitySignatureCreator", { enumerable: true, get: function () { return jws_signature_creator_1.IntroductoryOfferEligibilitySignatureCreator; } });
var AdvancedCommerceReason_1 = require("./models/AdvancedCommerceReason");
Object.defineProperty(exports, "AdvancedCommerceReason", { enumerable: true, get: function () { return AdvancedCommerceReason_1.AdvancedCommerceReason; } });
var AdvancedCommerceEffective_1 = require("./models/AdvancedCommerceEffective");
Object.defineProperty(exports, "AdvancedCommerceEffective", { enumerable: true, get: function () { return AdvancedCommerceEffective_1.AdvancedCommerceEffective; } });
var AdvancedCommercePeriod_1 = require("./models/AdvancedCommercePeriod");
Object.defineProperty(exports, "AdvancedCommercePeriod", { enumerable: true, get: function () { return AdvancedCommercePeriod_1.AdvancedCommercePeriod; } });
var AdvancedCommerceOfferPeriod_1 = require("./models/AdvancedCommerceOfferPeriod");
Object.defineProperty(exports, "AdvancedCommerceOfferPeriod", { enumerable: true, get: function () { return AdvancedCommerceOfferPeriod_1.AdvancedCommerceOfferPeriod; } });
var AdvancedCommerceOfferReason_1 = require("./models/AdvancedCommerceOfferReason");
Object.defineProperty(exports, "AdvancedCommerceOfferReason", { enumerable: true, get: function () { return AdvancedCommerceOfferReason_1.AdvancedCommerceOfferReason; } });
var AdvancedCommerceRefundReason_1 = require("./models/AdvancedCommerceRefundReason");
Object.defineProperty(exports, "AdvancedCommerceRefundReason", { enumerable: true, get: function () { return AdvancedCommerceRefundReason_1.AdvancedCommerceRefundReason; } });
var AdvancedCommerceRefundType_1 = require("./models/AdvancedCommerceRefundType");
Object.defineProperty(exports, "AdvancedCommerceRefundType", { enumerable: true, get: function () { return AdvancedCommerceRefundType_1.AdvancedCommerceRefundType; } });
var AdvancedCommercePriceIncreaseInfoStatus_1 = require("./models/AdvancedCommercePriceIncreaseInfoStatus");
Object.defineProperty(exports, "AdvancedCommercePriceIncreaseInfoStatus", { enumerable: true, get: function () { return AdvancedCommercePriceIncreaseInfoStatus_1.AdvancedCommercePriceIncreaseInfoStatus; } });
var BillingPlanType_1 = require("./models/BillingPlanType");
Object.defineProperty(exports, "BillingPlanType", { enumerable: true, get: function () { return BillingPlanType_1.BillingPlanType; } });
var RenewalBillingPlanType_1 = require("./models/RenewalBillingPlanType");
Object.defineProperty(exports, "RenewalBillingPlanType", { enumerable: true, get: function () { return RenewalBillingPlanType_1.RenewalBillingPlanType; } });
const jsonwebtoken = require("jsonwebtoken");
const AppTransactionInfoResponse_1 = require("./models/AppTransactionInfoResponse");
const NotificationHistoryResponse_1 = require("./models/NotificationHistoryResponse");
const url_1 = require("url");
class AppStoreServerAPIClient {
    /**
     * Create an App Store Server API client
     * @param signingKey Your private key downloaded from App Store Connect
     * @param keyId Your private key ID from App Store Connect
     * @param issuerId Your issuer ID from the Keys page in App Store Connect
     * @param bundleId Your app’s bundle ID
     * @param environment The environment to target
     */
    constructor(signingKey, keyId, issuerId, bundleId, environment) {
        this.issuerId = issuerId;
        this.keyId = keyId;
        this.bundleId = bundleId;
        this.signingKey = signingKey;
        switch (environment) {
            case Environment_1.Environment.XCODE:
                throw new Error("Xcode is not a supported environment for an AppStoreServerAPIClient");
            case Environment_1.Environment.PRODUCTION:
                this.urlBase = AppStoreServerAPIClient.PRODUCTION_URL;
                break;
            case Environment_1.Environment.LOCAL_TESTING:
                this.urlBase = AppStoreServerAPIClient.LOCAL_TESTING_URL;
                break;
            case Environment_1.Environment.SANDBOX:
                this.urlBase = AppStoreServerAPIClient.SANDBOX_URL;
                break;
        }
    }
    async makeRequest(path, method, queryParameters, body, validator, contentType) {
        const headers = {
            'User-Agent': AppStoreServerAPIClient.USER_AGENT,
            'Authorization': 'Bearer ' + this.createBearerToken(),
            'Accept': 'application/json',
        };
        const parsedQueryParameters = new url_1.URLSearchParams();
        for (const queryParam in queryParameters) {
            for (const queryVal of queryParameters[queryParam]) {
                parsedQueryParameters.append(queryParam, queryVal);
            }
        }
        let requestBody = undefined;
        if (body instanceof Buffer) {
            requestBody = body;
            if (contentType) {
                headers['Content-Type'] = contentType;
            }
        }
        else if (body != null) {
            requestBody = JSON.stringify(body);
            headers['Content-Type'] = 'application/json';
        }
        const response = await this.makeFetchRequest(path, parsedQueryParameters, method, requestBody, headers);
        if (response.ok) {
            // Success
            if (validator == null) {
                return null;
            }
            const responseBody = await response.json();
            if (!validator.validate(responseBody)) {
                throw new Error("Unexpected response body format");
            }
            return responseBody;
        }
        try {
            const responseBody = await response.json();
            const errorCode = responseBody['errorCode'];
            const errorMessage = responseBody['errorMessage'];
            if (errorCode) {
                throw new APIException(response.status, errorCode, errorMessage);
            }
            throw new APIException(response.status);
        }
        catch (e) {
            if (e instanceof APIException) {
                throw e;
            }
            throw new APIException(response.status);
        }
    }
    async makeFetchRequest(path, parsedQueryParameters, method, requestBody, headers) {
        return await (0, node_fetch_1.default)(this.urlBase + path + '?' + parsedQueryParameters, {
            method: method,
            body: requestBody,
            headers: headers
        });
    }
    /**
     * Uses a subscription’s product identifier to extend the renewal date for all of its eligible active subscribers.
     *
     * @param massExtendRenewalDateRequest The request body for extending a subscription renewal date for all of its active subscribers.
     * @return A response that indicates the server successfully received the subscription-renewal-date extension request.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/appstoreserverapi/extend_subscription_renewal_dates_for_all_active_subscribers Extend Subscription Renewal Dates for All Active Subscribers}
     */
    async extendRenewalDateForAllActiveSubscribers(massExtendRenewalDateRequest) {
        return await this.makeRequest("/inApps/v1/subscriptions/extend/mass", "POST", {}, massExtendRenewalDateRequest, new MassExtendRenewalDateResponse_1.MassExtendRenewalDateResponseValidator(), 'application/json');
    }
    /**
     * Extends the renewal date of a customer’s active subscription using the original transaction identifier.
     *
     * @param originalTransactionId    The original transaction identifier of the subscription receiving a renewal date extension.
     * @param extendRenewalDateRequest The request body containing subscription-renewal-extension data.
     * @return A response that indicates whether an individual renewal-date extension succeeded, and related details.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/appstoreserverapi/extend_a_subscription_renewal_date Extend a Subscription Renewal Date}
     */
    async extendSubscriptionRenewalDate(originalTransactionId, extendRenewalDateRequest) {
        return await this.makeRequest("/inApps/v1/subscriptions/extend/" + originalTransactionId, "PUT", {}, extendRenewalDateRequest, new ExtendRenewalDateResponse_1.ExtendRenewalDateResponseValidator(), 'application/json');
    }
    /**
     * Get the statuses for all of a customer’s auto-renewable subscriptions in your app.
     *
     * @param anyTransactionId Any transactionId, originalTransactionId, or appTransactionId that belongs to the customer for your app.
     * @param status An optional filter that indicates the status of subscriptions to include in the response. Your query may specify more than one status query parameter.
     * @return A response that contains status information for all of a customer’s auto-renewable subscriptions in your app.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/appstoreserverapi/get_all_subscription_statuses Get All Subscription Statuses}
     */
    async getAllSubscriptionStatuses(anyTransactionId, status = undefined) {
        const queryParameters = {};
        if (status != null) {
            queryParameters["status"] = status.map(s => s.toString());
        }
        return await this.makeRequest("/inApps/v1/subscriptions/" + anyTransactionId, "GET", queryParameters, null, new StatusResponse_1.StatusResponseValidator(), undefined);
    }
    /**
     * Get a paginated list of all of a customer’s refunded in-app purchases for your app.
     *
     * @param anyTransactionId Any transactionId, originalTransactionId, or appTransactionId that belongs to the customer for your app.
     * @param revision              A token you provide to get the next set of up to 20 transactions. All responses include a revision token. Use the revision token from the previous RefundHistoryResponse.
     * @return A response that contains status information for all of a customer’s auto-renewable subscriptions in your app.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/appstoreserverapi/get_refund_history Get Refund History}
     */
    async getRefundHistory(anyTransactionId, revision) {
        const queryParameters = {};
        if (revision !== null) {
            queryParameters["revision"] = [revision];
        }
        return await this.makeRequest("/inApps/v2/refund/lookup/" + anyTransactionId, "GET", queryParameters, null, new RefundHistoryResponse_1.RefundHistoryResponseValidator(), undefined);
    }
    /**
     * Checks whether a renewal date extension request completed, and provides the final count of successful or failed extensions.
     *
     * @param requestIdentifier The UUID that represents your request to the Extend Subscription Renewal Dates for All Active Subscribers endpoint.
     * @param productId         The product identifier of the auto-renewable subscription that you request a renewal-date extension for.
     * @return A response that indicates the current status of a request to extend the subscription renewal date to all eligible subscribers.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/appstoreserverapi/get_status_of_subscription_renewal_date_extensions Get Status of Subscription Renewal Date Extensions}
     */
    async getStatusOfSubscriptionRenewalDateExtensions(requestIdentifier, productId) {
        return await this.makeRequest("/inApps/v1/subscriptions/extend/mass/" + productId + "/" + requestIdentifier, "GET", {}, null, new MassExtendRenewalDateStatusResponse_1.MassExtendRenewalDateStatusResponseValidator(), undefined);
    }
    /**
     * Check the status of the test App Store server notification sent to your server.
     *
     * @param testNotificationToken The test notification token received from the Request a Test Notification endpoint
     * @return A response that contains the contents of the test notification sent by the App Store server and the result from your server.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/appstoreserverapi/get_test_notification_status Get Test Notification Status}
     */
    async getTestNotificationStatus(testNotificationToken) {
        return await this.makeRequest("/inApps/v1/notifications/test/" + testNotificationToken, "GET", {}, null, new CheckTestNotificationResponse_1.CheckTestNotificationResponseValidator(), undefined);
    }
    /**
     * Get a list of notifications that the App Store server attempted to send to your server.
     *
     * @param paginationToken An optional token you use to get the next set of up to 20 notification history records. All responses that have more records available include a paginationToken. Omit this parameter the first time you call this endpoint.
     * @param notificationHistoryRequest The request body that includes the start and end dates, and optional query constraints.
     * @return A response that contains the App Store Server Notifications history for your app.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/appstoreserverapi/get_notification_history Get Notification History}
     */
    async getNotificationHistory(paginationToken, notificationHistoryRequest) {
        const queryParameters = {};
        if (paginationToken != null) {
            queryParameters["paginationToken"] = [paginationToken];
        }
        return await this.makeRequest("/inApps/v1/notifications/history", "POST", queryParameters, notificationHistoryRequest, new NotificationHistoryResponse_1.NotificationHistoryResponseValidator(), 'application/json');
    }
    /**
     * Get a customer’s in-app purchase transaction history for your app.
     *
     * @param anyTransactionId Any transactionId, originalTransactionId, or appTransactionId that belongs to the customer for your app.
     * @param revision              A token you provide to get the next set of up to 20 transactions. All responses include a revision token. Note: For requests that use the revision token, include the same query parameters from the initial request. Use the revision token from the previous HistoryResponse.
     * @param version The version of the Get Transaction History endpoint to use. V2 is recommended.
     * @return A response that contains the customer’s transaction history for an app.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/appstoreserverapi/get_transaction_history Get Transaction History}
     */
    async getTransactionHistory(anyTransactionId, revision, transactionHistoryRequest, version = GetTransactionHistoryVersion.V1) {
        const queryParameters = {};
        if (revision != null) {
            queryParameters["revision"] = [revision];
        }
        if (transactionHistoryRequest.startDate) {
            queryParameters["startDate"] = [transactionHistoryRequest.startDate.toString()];
        }
        if (transactionHistoryRequest.endDate) {
            queryParameters["endDate"] = [transactionHistoryRequest.endDate.toString()];
        }
        if (transactionHistoryRequest.productIds) {
            queryParameters["productId"] = transactionHistoryRequest.productIds;
        }
        if (transactionHistoryRequest.productTypes) {
            queryParameters["productType"] = transactionHistoryRequest.productTypes;
        }
        if (transactionHistoryRequest.sort) {
            queryParameters["sort"] = [transactionHistoryRequest.sort];
        }
        if (transactionHistoryRequest.subscriptionGroupIdentifiers) {
            queryParameters["subscriptionGroupIdentifier"] = transactionHistoryRequest.subscriptionGroupIdentifiers;
        }
        if (transactionHistoryRequest.inAppOwnershipType) {
            queryParameters["inAppOwnershipType"] = [transactionHistoryRequest.inAppOwnershipType];
        }
        if (transactionHistoryRequest.revoked !== undefined) {
            queryParameters["revoked"] = [transactionHistoryRequest.revoked.toString()];
        }
        return await this.makeRequest("/inApps/" + version + "/history/" + anyTransactionId, "GET", queryParameters, null, new HistoryResponse_1.HistoryResponseValidator(), undefined);
    }
    /**
     * Get information about a single transaction for your app.
     *
     * @param transactionId The identifier of a transaction that belongs to the customer, and which may be an original transaction identifier.
     * @return A response that contains signed transaction information for a single transaction.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/appstoreserverapi/get_transaction_info Get Transaction Info}
     */
    async getTransactionInfo(transactionId) {
        return await this.makeRequest("/inApps/v1/transactions/" + transactionId, "GET", {}, null, new TransactionInfoResponse_1.TransactionInfoResponseValidator(), undefined);
    }
    /**
     * Get a customer’s in-app purchases from a receipt using the order ID.
     *
     * @param orderId The order ID for in-app purchases that belong to the customer.
     * @return A response that includes the order lookup status and an array of signed transactions for the in-app purchases in the order.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/appstoreserverapi/look_up_order_id Look Up Order ID}
     */
    async lookUpOrderId(orderId) {
        return await this.makeRequest("/inApps/v1/lookup/" + orderId, "GET", {}, null, new OrderLookupResponse_1.OrderLookupResponseValidator(), undefined);
    }
    /**
     * Ask App Store Server Notifications to send a test notification to your server.
     *
     * @return A response that contains the test notification token.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/appstoreserverapi/request_a_test_notification Request a Test Notification}
     */
    async requestTestNotification() {
        return await this.makeRequest("/inApps/v1/notifications/test", "POST", {}, null, new SendTestNotificationResponse_1.SendTestNotificationResponseValidator(), undefined);
    }
    /**
     * Send consumption information about a consumable in-app purchase to the App Store after your server receives a consumption request notification.
     *
     * @param transactionId The transaction identifier for which you're providing consumption information. You receive this identifier in the CONSUMPTION_REQUEST notification the App Store sends to your server.
     * @param consumptionRequest    The request body containing consumption information.
     * @throws APIException If a response was returned indicating the request could not be processed
     * @deprecated Use {@link sendConsumptionInformation} instead
     * {@link https://developer.apple.com/documentation/appstoreserverapi/send-consumption-information-v1 Send Consumption Information}
     */
    async sendConsumptionData(transactionId, consumptionRequest) {
        await this.makeRequest("/inApps/v1/transactions/consumption/" + transactionId, "PUT", {}, consumptionRequest, null, 'application/json');
    }
    /**
     * Send consumption information about an In-App Purchase to the App Store after your server receives a consumption request notification.
     *
     * @param transactionId The transaction identifier for which you're providing consumption information. You receive this identifier in the CONSUMPTION_REQUEST notification the App Store sends to your server's App Store Server Notifications V2 endpoint.
     * @param consumptionRequest The request body containing consumption information.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/appstoreserverapi/send-consumption-information Send Consumption Information}
     */
    async sendConsumptionInformation(transactionId, consumptionRequest) {
        await this.makeRequest("/inApps/v2/transactions/consumption/" + transactionId, "PUT", {}, consumptionRequest, null, 'application/json');
    }
    /**
     * Sets the app account token value for a purchase the customer makes outside your app, or updates its value in an existing transaction.
     *
     * @param originalTransactionId The original transaction identifier of the transaction to receive the app account token update.
     * @param updateAppAccountTokenRequest The request body that contains a valid app account token value.
     * @throws APIException If a response was returned indicating the request could not be processed.
     * {@link https://developer.apple.com/documentation/appstoreserverapi/set-app-account-token Set App Account Token}
     */
    async setAppAccountToken(originalTransactionId, updateAppAccountTokenRequest) {
        await this.makeRequest("/inApps/v1/transactions/" + originalTransactionId + "/appAccountToken", "PUT", {}, updateAppAccountTokenRequest, null, 'application/json');
    }
    /**
     * Upload an image to use for retention messaging.
     *
     * @param imageIdentifier A UUID you provide to uniquely identify the image you upload. Must be lowercase.
     * @param image The image file to upload.
     * @param imageSize The size of the image you upload.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/retentionmessaging/upload-image Upload Image}
     */
    async uploadImage(imageIdentifier, image, imageSize) {
        const queryParameters = {};
        if (imageSize != null) {
            queryParameters["imageSize"] = [imageSize];
        }
        await this.makeRequest("/inApps/v1/messaging/image/" + imageIdentifier, "PUT", queryParameters, image, null, 'image/png');
    }
    /**
     * Delete a previously uploaded image.
     *
     * @param imageIdentifier The identifier of the image to delete.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/retentionmessaging/delete-image Delete Image}
     */
    async deleteImage(imageIdentifier) {
        await this.makeRequest("/inApps/v1/messaging/image/" + imageIdentifier, "DELETE", {}, null, null, undefined);
    }
    /**
     * Get the image identifier and state for all uploaded images.
     *
     * @return A response that contains status information for all images.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/retentionmessaging/get-image-list Get Image List}
     */
    async getImageList() {
        return await this.makeRequest("/inApps/v1/messaging/image/list", "GET", {}, null, new GetImageListResponse_1.GetImageListResponseValidator(), undefined);
    }
    /**
     * Upload a message to use for retention messaging.
     *
     * @param messageIdentifier A UUID you provide to uniquely identify the message you upload. Must be lowercase.
     * @param uploadMessageRequestBody The message text to upload.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/retentionmessaging/upload-message Upload Message}
     */
    async uploadMessage(messageIdentifier, uploadMessageRequestBody) {
        await this.makeRequest("/inApps/v1/messaging/message/" + messageIdentifier, "PUT", {}, uploadMessageRequestBody, null, 'application/json');
    }
    /**
     * Delete a previously uploaded message.
     *
     * @param messageIdentifier The identifier of the message to delete.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/retentionmessaging/delete-message Delete Message}
     */
    async deleteMessage(messageIdentifier) {
        await this.makeRequest("/inApps/v1/messaging/message/" + messageIdentifier, "DELETE", {}, null, null, undefined);
    }
    /**
     * Get the message identifier and state of all uploaded messages.
     *
     * @return A response that contains status information for all messages.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/retentionmessaging/get-message-list Get Message List}
     */
    async getMessageList() {
        return await this.makeRequest("/inApps/v1/messaging/message/list", "GET", {}, null, new GetMessageListResponse_1.GetMessageListResponseValidator(), undefined);
    }
    /**
     * Configure a default message for a specific product in a specific locale.
     *
     * @param productId The product identifier for the default configuration.
     * @param locale The locale for the default configuration.
     * @param defaultConfigurationRequest The request body that includes the message identifier to configure as the default message.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/retentionmessaging/configure-default-message Configure Default Message}
     */
    async configureDefaultMessage(productId, locale, defaultConfigurationRequest) {
        await this.makeRequest("/inApps/v1/messaging/default/" + productId + "/" + locale, "PUT", {}, defaultConfigurationRequest, null, 'application/json');
    }
    /**
     * Delete a default message for a product in a locale.
     *
     * @param productId The product ID of the default message configuration.
     * @param locale The locale of the default message configuration.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/retentionmessaging/delete-default-message Delete Default Message}
     */
    async deleteDefaultMessage(productId, locale) {
        await this.makeRequest("/inApps/v1/messaging/default/" + productId + "/" + locale, "DELETE", {}, null, null, undefined);
    }
    /**
     * Gets the default message for a specific product in a specific locale, if it’s configured.
     *
     * @param productId The product identifier of the message.
     * @param locale The locale of the message.
     * @return The response body that contains the default configuration information.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/retentionmessaging/get-default-message Get Default Message}
     */
    async getDefaultMessage(productId, locale) {
        return await this.makeRequest("/inApps/v1/messaging/default/" + productId + "/" + locale, "GET", {}, null, new DefaultConfigurationResponse_1.DefaultConfigurationResponseValidator(), undefined);
    }
    /**
     * Configures the URL for your Get Retention Message endpoint in the sandbox and production environments.
     *
     * @param realtimeUrlRequest The request body that includes your endpoint’s URL.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/retentionmessaging/configure-realtime-url Configure Realtime URL}
     */
    async configureRealtimeURL(realtimeUrlRequest) {
        await this.makeRequest("/inApps/v1/messaging/realtime/url", "PUT", {}, realtimeUrlRequest, null, 'application/json');
    }
    /**
     * Deletes the URL for your Get Retention Message endpoint, in the sandbox or production environments.
     *
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/retentionmessaging/delete-realtime-url Delete Realtime URL}
     */
    async deleteRealtimeURL() {
        await this.makeRequest("/inApps/v1/messaging/realtime/url", "DELETE", {}, null, null, undefined);
    }
    /**
     * Gets the URL for real-time messages that points to your Get Retention Message endpoint, which you previously configured.
     *
     * @return The response body that contains the URL for your Get Retention Message endpoint.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/retentionmessaging/get-realtime-url Get Realtime URL}
     */
    async getRealtimeURL() {
        return await this.makeRequest("/inApps/v1/messaging/realtime/url", "GET", {}, null, new RealtimeUrlResponse_1.RealtimeUrlResponseValidator(), undefined);
    }
    /**
     * Initiates a performance test of your Get Retention Message endpoint in the sandbox environment.
     *
     * @param performanceTestRequest The request body which specifies a transaction identifier of an In-App Purchase to use for this test.
     * @return The performance test response object.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/retentionmessaging/initiate-performance-test Initiate Performance Test}
     */
    async initiatePerformanceTest(performanceTestRequest) {
        return await this.makeRequest("/inApps/v1/messaging/performanceTest", "POST", {}, performanceTestRequest, new PerformanceTestResponse_1.PerformanceTestResponseValidator(), 'application/json');
    }
    /**
     * Gets the results of the performance test for the specified identifier.
     *
     * @param requestId The ID of the performance test to return, which you receive in the PerformanceTestResponse when you call Initiate Performance Test.
     * @return An object the API returns that describes the performance test results.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/retentionmessaging/get-performance-test-results Get Performance Test Results}
     */
    async getPerformanceTestResults(requestId) {
        return await this.makeRequest("/inApps/v1/messaging/performanceTest/result/" + requestId, "GET", {}, null, new PerformanceTestResultResponse_1.PerformanceTestResultResponseValidator(), undefined);
    }
    /**
      * Get a customer's app transaction information for your app.
      *
      * @param anyTransactionId Any transactionId, originalTransactionId, or appTransactionId that belongs to the customer for your app.
      * @return A response that contains signed app transaction information for a customer.
      * @throws APIException If a response was returned indicating the request could not be processed
      * {@link https://developer.apple.com/documentation/appstoreserverapi/get-app-transaction-info Get App Transaction Info}
      */
    async getAppTransactionInfo(anyTransactionId) {
        return await this.makeRequest("/inApps/v1/transactions/appTransactions/" + anyTransactionId, "GET", {}, null, new AppTransactionInfoResponse_1.AppTransactionInfoResponseValidator(), undefined);
    }
    /**
     * Notifies the App Store server that your system has finished processing the customer's transaction.
     *
     * @param transactionId The transaction identifier of the transaction to mark as finished.
     * @throws APIException If a response was returned indicating the request could not be processed
     * {@link https://developer.apple.com/documentation/appstoreserverapi/finish-transaction Finish Transaction}
     */
    async finishTransaction(transactionId) {
        await this.makeRequest("/inApps/v1/transactions/" + transactionId + "/finish", "POST", {}, null, null, undefined);
    }
    createBearerToken() {
        const payload = {
            bid: this.bundleId
        };
        return jsonwebtoken.sign(payload, this.signingKey, { algorithm: 'ES256', keyid: this.keyId, issuer: this.issuerId, audience: 'appstoreconnect-v1', expiresIn: '5m' });
    }
}
exports.AppStoreServerAPIClient = AppStoreServerAPIClient;
AppStoreServerAPIClient.PRODUCTION_URL = "https://api.storekit.apple.com";
AppStoreServerAPIClient.SANDBOX_URL = "https://api.storekit-sandbox.apple.com";
AppStoreServerAPIClient.LOCAL_TESTING_URL = "https://local-testing-base-url";
AppStoreServerAPIClient.USER_AGENT = "app-store-server-library/node/3.1.0";
class APIException extends Error {
    constructor(httpStatusCode, apiError = null, errorMessage = null) {
        super();
        this.httpStatusCode = httpStatusCode;
        this.apiError = apiError;
        this.errorMessage = errorMessage;
    }
}
exports.APIException = APIException;
/**
 * Error codes that App Store Server API responses return.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/error_codes Error codes}
 */
var APIError;
(function (APIError) {
    /**
     * An error that indicates an invalid request.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/generalbadrequesterror GeneralBadRequestError}
     */
    APIError[APIError["GENERAL_BAD_REQUEST"] = 4000000] = "GENERAL_BAD_REQUEST";
    /**
     * An error that indicates an invalid app identifier.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidappidentifiererror InvalidAppIdentifierError}
     */
    APIError[APIError["INVALID_APP_IDENTIFIER"] = 4000002] = "INVALID_APP_IDENTIFIER";
    /**
     * An error that indicates an invalid request revision.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidrequestrevisionerror InvalidRequestRevisionError}
     */
    APIError[APIError["INVALID_REQUEST_REVISION"] = 4000005] = "INVALID_REQUEST_REVISION";
    /**
     * An error that indicates an invalid transaction identifier.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidtransactioniderror InvalidTransactionIdError}
     */
    APIError[APIError["INVALID_TRANSACTION_ID"] = 4000006] = "INVALID_TRANSACTION_ID";
    /**
     * An error that indicates an invalid original transaction identifier.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidoriginaltransactioniderror InvalidOriginalTransactionIdError}
     */
    APIError[APIError["INVALID_ORIGINAL_TRANSACTION_ID"] = 4000008] = "INVALID_ORIGINAL_TRANSACTION_ID";
    /**
     * An error that indicates an invalid extend-by-days value.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidextendbydayserror InvalidExtendByDaysError}
     */
    APIError[APIError["INVALID_EXTEND_BY_DAYS"] = 4000009] = "INVALID_EXTEND_BY_DAYS";
    /**
     * An error that indicates an invalid reason code.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidextendreasoncodeerror InvalidExtendReasonCodeError}
     */
    APIError[APIError["INVALID_EXTEND_REASON_CODE"] = 4000010] = "INVALID_EXTEND_REASON_CODE";
    /**
     * An error that indicates an invalid request identifier.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidrequestidentifiererror InvalidRequestIdentifierError}
     */
    APIError[APIError["INVALID_REQUEST_IDENTIFIER"] = 4000011] = "INVALID_REQUEST_IDENTIFIER";
    /**
     * An error that indicates that the start date is earlier than the earliest allowed date.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/startdatetoofarinpasterror StartDateTooFarInPastError}
     */
    APIError[APIError["START_DATE_TOO_FAR_IN_PAST"] = 4000012] = "START_DATE_TOO_FAR_IN_PAST";
    /**
     * An error that indicates that the end date precedes the start date, or the two dates are equal.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/startdateafterenddateerror StartDateAfterEndDateError}
     */
    APIError[APIError["START_DATE_AFTER_END_DATE"] = 4000013] = "START_DATE_AFTER_END_DATE";
    /**
     * An error that indicates the pagination token is invalid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidpaginationtokenerror InvalidPaginationTokenError}
     */
    APIError[APIError["INVALID_PAGINATION_TOKEN"] = 4000014] = "INVALID_PAGINATION_TOKEN";
    /**
     * An error that indicates the start date is invalid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidstartdateerror InvalidStartDateError}
     */
    APIError[APIError["INVALID_START_DATE"] = 4000015] = "INVALID_START_DATE";
    /**
     * An error that indicates the end date is invalid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidenddateerror InvalidEndDateError}
     */
    APIError[APIError["INVALID_END_DATE"] = 4000016] = "INVALID_END_DATE";
    /**
     * An error that indicates the pagination token expired.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/paginationtokenexpirederror PaginationTokenExpiredError}
     */
    APIError[APIError["PAGINATION_TOKEN_EXPIRED"] = 4000017] = "PAGINATION_TOKEN_EXPIRED";
    /**
     * An error that indicates the notification type or subtype is invalid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidnotificationtypeerror InvalidNotificationTypeError}
     */
    APIError[APIError["INVALID_NOTIFICATION_TYPE"] = 4000018] = "INVALID_NOTIFICATION_TYPE";
    /**
     * An error that indicates the request is invalid because it has too many constraints applied.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/multiplefilterssuppliederror MultipleFiltersSuppliedError}
     */
    APIError[APIError["MULTIPLE_FILTERS_SUPPLIED"] = 4000019] = "MULTIPLE_FILTERS_SUPPLIED";
    /**
     * An error that indicates the test notification token is invalid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidtestnotificationtokenerror InvalidTestNotificationTokenError}
     */
    APIError[APIError["INVALID_TEST_NOTIFICATION_TOKEN"] = 4000020] = "INVALID_TEST_NOTIFICATION_TOKEN";
    /**
     * An error that indicates an invalid sort parameter.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidsorterror InvalidSortError}
     */
    APIError[APIError["INVALID_SORT"] = 4000021] = "INVALID_SORT";
    /**
     * An error that indicates an invalid product type parameter.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidproducttypeerror InvalidProductTypeError}
     */
    APIError[APIError["INVALID_PRODUCT_TYPE"] = 4000022] = "INVALID_PRODUCT_TYPE";
    /**
     * An error that indicates the product ID parameter is invalid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidproductiderror InvalidProductIdError}
     */
    APIError[APIError["INVALID_PRODUCT_ID"] = 4000023] = "INVALID_PRODUCT_ID";
    /**
     * An error that indicates an invalid subscription group identifier.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidsubscriptiongroupidentifiererror InvalidSubscriptionGroupIdentifierError}
     */
    APIError[APIError["INVALID_SUBSCRIPTION_GROUP_IDENTIFIER"] = 4000024] = "INVALID_SUBSCRIPTION_GROUP_IDENTIFIER";
    /**
     * An error that indicates the query parameter exclude-revoked is invalid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidexcluderevokederror InvalidExcludeRevokedError}
     *
     * @deprecated
     */
    APIError[APIError["INVALID_EXCLUDE_REVOKED"] = 4000025] = "INVALID_EXCLUDE_REVOKED";
    /**
     * An error that indicates an invalid in-app ownership type parameter.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidinappownershiptypeerror InvalidInAppOwnershipTypeError}
     */
    APIError[APIError["INVALID_IN_APP_OWNERSHIP_TYPE"] = 4000026] = "INVALID_IN_APP_OWNERSHIP_TYPE";
    /**
     * An error that indicates a required storefront country code is empty.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidemptystorefrontcountrycodelisterror InvalidEmptyStorefrontCountryCodeListError}
     */
    APIError[APIError["INVALID_EMPTY_STOREFRONT_COUNTRY_CODE_LIST"] = 4000027] = "INVALID_EMPTY_STOREFRONT_COUNTRY_CODE_LIST";
    /**
     * An error that indicates a storefront code is invalid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidstorefrontcountrycodeerror InvalidStorefrontCountryCodeError}
     */
    APIError[APIError["INVALID_STOREFRONT_COUNTRY_CODE"] = 4000028] = "INVALID_STOREFRONT_COUNTRY_CODE";
    /**
     * An error that indicates the revoked parameter contains an invalid value.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidrevokederror InvalidRevokedError}
     */
    APIError[APIError["INVALID_REVOKED"] = 4000030] = "INVALID_REVOKED";
    /**
     * An error that indicates the status parameter is invalid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidstatuserror InvalidStatusError}
     */
    APIError[APIError["INVALID_STATUS"] = 4000031] = "INVALID_STATUS";
    /**
     * An error that indicates the value of the account tenure field is invalid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidaccounttenureerror InvalidAccountTenureError}
     */
    APIError[APIError["INVALID_ACCOUNT_TENURE"] = 4000032] = "INVALID_ACCOUNT_TENURE";
    /**
     * An error that indicates the value of the app account token field is invalid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidappaccounttokenerror InvalidAppAccountTokenError}
     */
    APIError[APIError["INVALID_APP_ACCOUNT_TOKEN"] = 4000033] = "INVALID_APP_ACCOUNT_TOKEN";
    /**
     * An error that indicates the value of the consumption status field is invalid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidconsumptionstatuserror InvalidConsumptionStatusError}
     */
    APIError[APIError["INVALID_CONSUMPTION_STATUS"] = 4000034] = "INVALID_CONSUMPTION_STATUS";
    /**
     * An error that indicates the customer consented field is invalid or doesn’t indicate that the customer consented.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidcustomerconsentederror InvalidCustomerConsentedError}
     */
    APIError[APIError["INVALID_CUSTOMER_CONSENTED"] = 4000035] = "INVALID_CUSTOMER_CONSENTED";
    /**
     * An error that indicates the value in the delivery status field is invalid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invaliddeliverystatuserror InvalidDeliveryStatusError}
     */
    APIError[APIError["INVALID_DELIVERY_STATUS"] = 4000036] = "INVALID_DELIVERY_STATUS";
    /**
     * An error that indicates the value in the lifetime dollars purchased field is invalid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidlifetimedollarspurchasederror InvalidLifetimeDollarsPurchasedError}
     */
    APIError[APIError["INVALID_LIFETIME_DOLLARS_PURCHASED"] = 4000037] = "INVALID_LIFETIME_DOLLARS_PURCHASED";
    /**
     * An error that indicates the value in the lifetime dollars refunded field is invalid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidlifetimedollarsrefundederror InvalidLifetimeDollarsRefundedError}
     */
    APIError[APIError["INVALID_LIFETIME_DOLLARS_REFUNDED"] = 4000038] = "INVALID_LIFETIME_DOLLARS_REFUNDED";
    /**
     * An error that indicates the value in the platform field is invalid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidplatformerror InvalidPlatformError}
     */
    APIError[APIError["INVALID_PLATFORM"] = 4000039] = "INVALID_PLATFORM";
    /**
     * An error that indicates the value in the playtime field is invalid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidplaytimeerror InvalidPlayTimeError}
     */
    APIError[APIError["INVALID_PLAY_TIME"] = 4000040] = "INVALID_PLAY_TIME";
    /**
     * An error that indicates the value in the sample content provided field is invalid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidsamplecontentprovidederror InvalidSampleContentProvidedError}
     */
    APIError[APIError["INVALID_SAMPLE_CONTENT_PROVIDED"] = 4000041] = "INVALID_SAMPLE_CONTENT_PROVIDED";
    /**
     * An error that indicates the value in the user status field is invalid.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invaliduserstatuserror InvalidUserStatusError}
     */
    APIError[APIError["INVALID_USER_STATUS"] = 4000042] = "INVALID_USER_STATUS";
    /**
     * An error that indicates the transaction identifier doesn’t represent a consumable in-app purchase.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidtransactionnotconsumableerror InvalidTransactionNotConsumableError}
     *
     * @deprecated
     */
    APIError[APIError["INVALID_TRANSACTION_NOT_CONSUMABLE"] = 4000043] = "INVALID_TRANSACTION_NOT_CONSUMABLE";
    /**
     * An error that indicates the transaction identifier represents an unsupported in-app purchase type.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidtransactiontypenotsupportederror InvalidTransactionTypeNotSupportedError}
     */
    APIError[APIError["INVALID_TRANSACTION_TYPE_NOT_SUPPORTED"] = 4000047] = "INVALID_TRANSACTION_TYPE_NOT_SUPPORTED";
    /**
     * An error that indicates the endpoint doesn't support an app transaction ID.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/apptransactionidnotsupportederror AppTransactionIdNotSupportedError}
     */
    APIError[APIError["APP_TRANSACTION_ID_NOT_SUPPORTED_ERROR"] = 4000048] = "APP_TRANSACTION_ID_NOT_SUPPORTED_ERROR";
    /**
     * An error that indicates the image that's uploading is invalid.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/invalidimageerror InvalidImageError}
     */
    APIError[APIError["INVALID_IMAGE"] = 4000161] = "INVALID_IMAGE";
    /**
     * An error that indicates the header text is too long.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/headertoolongerror HeaderTooLongError}
     */
    APIError[APIError["HEADER_TOO_LONG"] = 4000162] = "HEADER_TOO_LONG";
    /**
     * An error that indicates the body text is too long.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/bodytoolongerror BodyTooLongError}
     */
    APIError[APIError["BODY_TOO_LONG"] = 4000163] = "BODY_TOO_LONG";
    /**
     * An error that indicates the locale is invalid.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/invalidlocaleerror InvalidLocaleError}
     */
    APIError[APIError["INVALID_LOCALE"] = 4000164] = "INVALID_LOCALE";
    /**
     * An error that indicates the alternative text for an image is too long.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/alttexttoolongerror AltTextTooLongError}
     */
    APIError[APIError["ALT_TEXT_TOO_LONG"] = 4000175] = "ALT_TEXT_TOO_LONG";
    /**
     * An error that indicates the app account token value is not a valid UUID.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/invalidappaccounttokenuuiderror InvalidAppAccountTokenUUIDError}
     */
    APIError[APIError["INVALID_APP_ACCOUNT_TOKEN_UUID_ERROR"] = 4000183] = "INVALID_APP_ACCOUNT_TOKEN_UUID_ERROR";
    /**
     * An error that indicates the transaction is for a product the customer obtains through Family Sharing, which the endpoint doesn’t support.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/familytransactionnotsupportederror FamilyTransactionNotSupportedError}
     */
    APIError[APIError["FAMILY_TRANSACTION_NOT_SUPPORTED_ERROR"] = 4000185] = "FAMILY_TRANSACTION_NOT_SUPPORTED_ERROR";
    /**
     * An error that indicates the endpoint expects an original transaction identifier.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/transactionidisnotoriginaltransactioniderror TransactionIdIsNotOriginalTransactionIdError}
     */
    APIError[APIError["TRANSACTION_ID_IS_NOT_ORIGINAL_TRANSACTION_ID_ERROR"] = 4000187] = "TRANSACTION_ID_IS_NOT_ORIGINAL_TRANSACTION_ID_ERROR";
    /**
     * An error the API returns that indicates the performance test request is invalid.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/invalidperformancetestrequesterror InvalidPerformanceTestRequestError}
     */
    APIError[APIError["INVALID_PERFORMANCE_TEST_REQUEST"] = 4000211] = "INVALID_PERFORMANCE_TEST_REQUEST";
    /**
     * An error that indicates the request ID is invalid.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/invalidrequestiderror InvalidRequestIdError}
     */
    APIError[APIError["INVALID_REQUEST_ID"] = 4000212] = "INVALID_REQUEST_ID";
    /**
     * An error that indicates an error with an existing test.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/existingperformancetestrunerror ExistingPerformanceTestRunError}
     */
    APIError[APIError["EXISTING_PERFORMANCE_TEST_RUN"] = 4000213] = "EXISTING_PERFORMANCE_TEST_RUN";
    /**
     * An error that indicates the URL is invalid.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/badrequestreaaltimeurlerror BadRequestRealtimeUrlError}
     */
    APIError[APIError["BAD_REQUEST_REALTIME_URL"] = 4000215] = "BAD_REQUEST_REALTIME_URL";
    /**
     * An error that indicates the image size provided is invalid.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/badrequestimagesizeerror BadRequestImageSizeError}
     */
    APIError[APIError["BAD_REQUEST_IMAGE_SIZE"] = 4000216] = "BAD_REQUEST_IMAGE_SIZE";
    /**
     * An error that indicates there are too many bullet points.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/badrequesttoomanybulletpointserror BadRequestTooManyBulletPointsError}
     */
    APIError[APIError["BAD_REQUEST_TOO_MANY_BULLET_POINTS"] = 4000218] = "BAD_REQUEST_TOO_MANY_BULLET_POINTS";
    /**
     * An error that indicates the text for a bullet point is too long.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/badrequestbulletpointtexttoolongerror BadRequestBulletPointTextTooLongError}
     */
    APIError[APIError["BAD_REQUEST_BULLET_POINT_TEXT_TOO_LONG"] = 4000219] = "BAD_REQUEST_BULLET_POINT_TEXT_TOO_LONG";
    /**
     * An error that indicates that no image object is included, but the request indicates that the header should be placed above the image.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/badrequestaboveimageerequiresanimageerror BadRequestAboveImageRequiresAnImageError}
     */
    APIError[APIError["BAD_REQUEST_ABOVE_IMAGE_REQUIRES_AN_IMAGE"] = 4000224] = "BAD_REQUEST_ABOVE_IMAGE_REQUIRES_AN_IMAGE";
    /**
     * An error that indicates the subscription doesn't qualify for a renewal-date extension due to its subscription state.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/subscriptionextensionineligibleerror SubscriptionExtensionIneligibleError}
     */
    APIError[APIError["SUBSCRIPTION_EXTENSION_INELIGIBLE"] = 4030004] = "SUBSCRIPTION_EXTENSION_INELIGIBLE";
    /**
     * An error that indicates the subscription doesn’t qualify for a renewal-date extension because it has already received the maximum extensions.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/subscriptionmaxextensionerror SubscriptionMaxExtensionError}
     */
    APIError[APIError["SUBSCRIPTION_MAX_EXTENSION"] = 4030005] = "SUBSCRIPTION_MAX_EXTENSION";
    /**
     * An error that indicates a subscription isn't directly eligible for a renewal date extension because the user obtained it through Family Sharing.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/familysharedsubscriptionextensionineligibleerror FamilySharedSubscriptionExtensionIneligibleError}
     */
    APIError[APIError["FAMILY_SHARED_SUBSCRIPTION_EXTENSION_INELIGIBLE"] = 4030007] = "FAMILY_SHARED_SUBSCRIPTION_EXTENSION_INELIGIBLE";
    /**
     * An error that indicates when you reach the maximum number of uploaded images.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/maximumnumberofimagesreachederror MaximumNumberOfImagesReachedError}
     */
    APIError[APIError["MAXIMUM_NUMBER_OF_IMAGES_REACHED"] = 4030014] = "MAXIMUM_NUMBER_OF_IMAGES_REACHED";
    /**
     * An error that indicates when you reach the maximum number of uploaded messages.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/maximumnumberofmessagesreachederror MaximumNumberOfMessagesReachedError}
     */
    APIError[APIError["MAXIMUM_NUMBER_OF_MESSAGES_REACHED"] = 4030016] = "MAXIMUM_NUMBER_OF_MESSAGES_REACHED";
    /**
     * An error that indicates the message isn't in the approved state, so you can't configure it as a default message.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/messagenotapprovederror MessageNotApprovedError}
     */
    APIError[APIError["MESSAGE_NOT_APPROVED"] = 4030017] = "MESSAGE_NOT_APPROVED";
    /**
     * An error that indicates the image isn't in the approved state, so you can't configure it as part of a default message.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/imagenotapprovederror ImageNotApprovedError}
     */
    APIError[APIError["IMAGE_NOT_APPROVED"] = 4030018] = "IMAGE_NOT_APPROVED";
    /**
     * An error that indicates the image is currently in use as part of a message, so you can't delete it.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/imageinuseerror ImageInUseError}
     */
    APIError[APIError["IMAGE_IN_USE"] = 4030019] = "IMAGE_IN_USE";
    /**
     * An error that indicates that passing a performance test is required before you can set a URL for the production environment.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/forbiddennopassingtesterror ForbiddenNoPassingTestError}
     */
    APIError[APIError["FORBIDDEN_NO_PASSING_TEST"] = 4030026] = "FORBIDDEN_NO_PASSING_TEST";
    /**
     * An error that indicates the App Store account wasn't found.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/accountnotfounderror AccountNotFoundError}
     */
    APIError[APIError["ACCOUNT_NOT_FOUND"] = 4040001] = "ACCOUNT_NOT_FOUND";
    /**
     * An error response that indicates the App Store account wasn’t found, but you can try again.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/accountnotfoundretryableerror AccountNotFoundRetryableError}
     */
    APIError[APIError["ACCOUNT_NOT_FOUND_RETRYABLE"] = 4040002] = "ACCOUNT_NOT_FOUND_RETRYABLE";
    /**
     * An error that indicates the app wasn’t found.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/appnotfounderror AppNotFoundError}
     */
    APIError[APIError["APP_NOT_FOUND"] = 4040003] = "APP_NOT_FOUND";
    /**
     * An error response that indicates the app wasn’t found, but you can try again.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/appnotfoundretryableerror AppNotFoundRetryableError}
     */
    APIError[APIError["APP_NOT_FOUND_RETRYABLE"] = 4040004] = "APP_NOT_FOUND_RETRYABLE";
    /**
     * An error that indicates an original transaction identifier wasn't found.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/originaltransactionidnotfounderror OriginalTransactionIdNotFoundError}
     */
    APIError[APIError["ORIGINAL_TRANSACTION_ID_NOT_FOUND"] = 4040005] = "ORIGINAL_TRANSACTION_ID_NOT_FOUND";
    /**
     * An error response that indicates the original transaction identifier wasn’t found, but you can try again.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/originaltransactionidnotfoundretryableerror OriginalTransactionIdNotFoundRetryableError}
     */
    APIError[APIError["ORIGINAL_TRANSACTION_ID_NOT_FOUND_RETRYABLE"] = 4040006] = "ORIGINAL_TRANSACTION_ID_NOT_FOUND_RETRYABLE";
    /**
     * An error that indicates that the App Store server couldn’t find a notifications URL for your app in this environment.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/servernotificationurlnotfounderror ServerNotificationUrlNotFoundError}
     */
    APIError[APIError["SERVER_NOTIFICATION_URL_NOT_FOUND"] = 4040007] = "SERVER_NOTIFICATION_URL_NOT_FOUND";
    /**
     * An error that indicates that the test notification token is expired or the test notification status isn’t available.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/testnotificationnotfounderror TestNotificationNotFoundError}
     */
    APIError[APIError["TEST_NOTIFICATION_NOT_FOUND"] = 4040008] = "TEST_NOTIFICATION_NOT_FOUND";
    /**
     * An error that indicates the server didn't find a subscription-renewal-date extension request for the request identifier and product identifier you provided.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/statusrequestnotfounderror StatusRequestNotFoundError}
     */
    APIError[APIError["STATUS_REQUEST_NOT_FOUND"] = 4040009] = "STATUS_REQUEST_NOT_FOUND";
    /**
     * An error that indicates a transaction identifier wasn't found.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/transactionidnotfounderror TransactionIdNotFoundError}
     */
    APIError[APIError["TRANSACTION_ID_NOT_FOUND"] = 4040010] = "TRANSACTION_ID_NOT_FOUND";
    /**
     * An error that indicates the system can't find the image identifier.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/imagenotfounderror ImageNotFoundError}
     */
    APIError[APIError["IMAGE_NOT_FOUND"] = 4040014] = "IMAGE_NOT_FOUND";
    /**
     * An error that indicates the system can't find the message identifier.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/messagenotfounderror MessageNotFoundError}
     */
    APIError[APIError["MESSAGE_NOT_FOUND"] = 4040015] = "MESSAGE_NOT_FOUND";
    /**
     * An error the API returns if the service can’t find the specified test run.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/performancetestrunnotfounderror PerformanceTestRunNotFoundError}
     */
    APIError[APIError["PERFORMANCE_TEST_RUN_NOT_FOUND"] = 4040018] = "PERFORMANCE_TEST_RUN_NOT_FOUND";
    /**
     * An error response that indicates an app transaction doesn’t exist for the specified customer.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/apptransactiondoesnotexisterror AppTransactionDoesNotExistError}
     */
    APIError[APIError["APP_TRANSACTION_DOES_NOT_EXIST_ERROR"] = 4040019] = "APP_TRANSACTION_DOES_NOT_EXIST_ERROR";
    /**
     * An error that indicates a default message isn’t configured.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/defaultmessagenotfounderror DefaultMessageNotFoundError}
     */
    APIError[APIError["DEFAULT_MESSAGE_NOT_FOUND"] = 4040020] = "DEFAULT_MESSAGE_NOT_FOUND";
    /**
     * An error that indicates that the URL for your endpoint isn’t configured.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/realtimeurlnotfounderror RealtimeUrlNotFoundError}
     */
    APIError[APIError["REALTIME_URL_NOT_FOUND"] = 4040021] = "REALTIME_URL_NOT_FOUND";
    /**
     * An error that indicates the image identifier already exists.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/imagealreadyexistserror ImageAlreadyExistsError}
     */
    APIError[APIError["IMAGE_ALREADY_EXISTS"] = 4090000] = "IMAGE_ALREADY_EXISTS";
    /**
     * An error that indicates the message identifier already exists.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/messagealreadyexistserror MessageAlreadyExistsError}
     */
    APIError[APIError["MESSAGE_ALREADY_EXISTS"] = 4090001] = "MESSAGE_ALREADY_EXISTS";
    /**
     * An error that indicates that the request exceeded the rate limit.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/ratelimitexceedederror RateLimitExceededError}
     */
    APIError[APIError["RATE_LIMIT_EXCEEDED"] = 4290000] = "RATE_LIMIT_EXCEEDED";
    /**
     * An error that indicates a general internal error.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/generalinternalerror GeneralInternalError}
     */
    APIError[APIError["GENERAL_INTERNAL"] = 5000000] = "GENERAL_INTERNAL";
    /**
     * An error response that indicates an unknown error occurred, but you can try again.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/generalinternalretryableerror GeneralInternalRetryableError}
     */
    APIError[APIError["GENERAL_INTERNAL_RETRYABLE"] = 5000001] = "GENERAL_INTERNAL_RETRYABLE";
})(APIError || (exports.APIError = APIError = {}));
var GetTransactionHistoryVersion;
(function (GetTransactionHistoryVersion) {
    /**
     * @deprecated
     */
    GetTransactionHistoryVersion["V1"] = "v1";
    GetTransactionHistoryVersion["V2"] = "v2";
})(GetTransactionHistoryVersion || (exports.GetTransactionHistoryVersion = GetTransactionHistoryVersion = {}));
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiaW5kZXguanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi9pbmRleC50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiO0FBQUEsNERBQTREOzs7O0FBRTVELDJDQUErQjtBQUMvQiwwRkFBK0g7QUFLL0gsd0ZBQTRIO0FBQzVILHNEQUFtRDtBQUVuRCxrRkFBbUg7QUFDbkgsd0VBQW9HO0FBQ3BHLDRFQUEwRztBQUMxRyw4REFBcUY7QUFFckYsMEZBQStIO0FBQy9ILHNHQUFpSjtBQUNqSixzRUFBaUc7QUFDakcsMEVBQXVHO0FBQ3ZHLHdGQUE0SDtBQUM1SCw0REFBa0Y7QUFFbEYsOEVBQTZHO0FBRTdHLDhFQUE2RztBQUM3RywwRkFBK0g7QUFHL0gsc0VBQWlHO0FBR2pHLHVEQUFrRztBQUF6RixzSEFBQSxrQkFBa0IsT0FBQTtBQUFFLHlIQUFBLHFCQUFxQixPQUFBO0FBQUUsc0hBQUEsa0JBQWtCLE9BQUE7QUFDdEUscURBQWtEO0FBQXpDLGlIQUFBLGNBQWMsT0FBQTtBQUN2Qix3REFBc0Q7QUFBN0MsOEdBQUEsYUFBYSxPQUFBO0FBSXRCLDREQUEwRDtBQUFqRCxrSEFBQSxlQUFlLE9BQUE7QUFNeEIsZ0VBQThEO0FBQXJELHNIQUFBLGlCQUFpQixPQUFBO0FBSzFCLDBEQUF3RDtBQUEvQyxnSEFBQSxjQUFjLE9BQUE7QUFDdkIsOERBQTREO0FBQW5ELG9IQUFBLGdCQUFnQixPQUFBO0FBQ3pCLG9EQUFrRDtBQUF6QywwR0FBQSxXQUFXLE9BQUE7QUFDcEIsOERBQTREO0FBQW5ELG9IQUFBLGdCQUFnQixPQUFBO0FBQ3pCLDhEQUE0RDtBQUFuRCxvSEFBQSxnQkFBZ0IsT0FBQTtBQU96QiwwREFBd0Q7QUFBL0MsZ0hBQUEsY0FBYyxPQUFBO0FBQ3ZCLGdFQUE4RDtBQUFyRCxzSEFBQSxpQkFBaUIsT0FBQTtBQUcxQixrREFBZ0Q7QUFBdkMsd0dBQUEsVUFBVSxPQUFBO0FBQ25CLGdEQUE4QztBQUFyQyxzR0FBQSxTQUFTLE9BQUE7QUFDbEIs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OEIsQ0FBQTtJQUU5Qjs7OztPQUlHO0lBQ0gsaUZBQWdDLENBQUE7SUFFaEM7Ozs7T0FJRztJQUNILDJFQUE2QixDQUFBO0lBRTdCOzs7O09BSUc7SUFDSCxxRUFBMEIsQ0FBQTtJQUUxQjs7OztPQUlHO0lBQ0gseUZBQW9DLENBQUE7QUFDeEMsQ0FBQyxFQXJtQlcsUUFBUSx3QkFBUixRQUFRLFFBcW1CbkI7QUFFRCxJQUFZLDRCQU1YO0FBTkQsV0FBWSw0QkFBNEI7SUFDcEM7O09BRUc7SUFDSCx5Q0FBUyxDQUFBO0lBQ1QseUNBQVMsQ0FBQTtBQUNiLENBQUMsRUFOVyw0QkFBNEIsNENBQTVCLDRCQUE0QixRQU12QyIsInNvdXJjZXNDb250ZW50IjpbIi8vIENvcHlyaWdodCAoYykgMjAyMyBBcHBsZSBJbmMuIExpY2Vuc2VkIHVuZGVyIE1JVCBMaWNlbnNlLlxuXG5pbXBvcnQgZmV0Y2ggZnJvbSAnbm9kZS1mZXRjaCc7XG5pbXBvcnQgeyBDaGVja1Rlc3ROb3RpZmljYXRpb25SZXNwb25zZSwgQ2hlY2tUZXN0Tm90aWZpY2F0aW9uUmVzcG9uc2VWYWxpZGF0b3IgfSBmcm9tICcuL21vZGVscy9DaGVja1Rlc3ROb3RpZmljYXRpb25SZXNwb25zZSc7XG5pbXBvcnQgeyBDb25zdW1wdGlvblJlcXVlc3QgfSBmcm9tICcuL21vZGVscy9Db25zdW1wdGlvblJlcXVlc3QnO1xuaW1wb3J0IHsgQ29uc3VtcHRpb25SZXF1ZXN0VjEgfSBmcm9tICcuL21vZGVscy9Db25zdW1wdGlvblJlcXVlc3RWMSc7XG5pbXBvcnQgeyBVcGRhdGVBcHBBY2NvdW50VG9rZW5SZXF1ZXN0IH0gZnJvbSAnLi9tb2RlbHMvVXBkYXRlQXBwQWNjb3VudFRva2VuUmVxdWVzdCdcbmltcG9ydCB7IERlZmF1bHRDb25maWd1cmF0aW9uUmVxdWVzdCB9IGZyb20gJy4vbW9kZWxzL0RlZmF1bHRDb25maWd1cmF0aW9uUmVxdWVzdCc7XG5pbXBvcnQgeyBEZWZhdWx0Q29uZmlndXJhdGlvblJlc3BvbnNlLCBEZWZhdWx0Q29uZmlndXJhdGlvblJlc3BvbnNlVmFsaWRhdG9yIH0gZnJvbSAnLi9tb2RlbHMvRGVmYXVsdENvbmZpZ3VyYXRpb25SZXNwb25zZSc7XG5pbXBvcnQgeyBFbnZpcm9ubWVudCB9IGZyb20gJy4vbW9kZWxzL0Vudmlyb25tZW50JztcbmltcG9ydCB7IEV4dGVuZFJlbmV3YWxEYXRlUmVxdWVzdCB9IGZyb20gJy4vbW9kZWxzL0V4dGVuZFJlbmV3YWxEYXRlUmVxdWVzdCc7XG5pbXBvcnQgeyBFeHRlbmRSZW5ld2FsRGF0ZVJlc3BvbnNlLCBFeHRlbmRSZW5ld2FsRGF0ZVJlc3BvbnNlVmFsaWRhdG9yIH0gZnJvbSAnLi9tb2RlbHMvRXh0ZW5kUmVuZXdhbERhdGVSZXNwb25zZSc7XG5pbXBvcnQgeyBHZXRJbWFnZUxpc3RSZXNwb25zZSwgR2V0SW1hZ2VMaXN0UmVzcG9uc2VWYWxpZGF0b3IgfSBmcm9tICcuL21vZGVscy9HZXRJbWFnZUxpc3RSZXNwb25zZSc7XG5pbXBvcnQgeyBHZXRNZXNzYWdlTGlzdFJlc3BvbnNlLCBHZXRNZXNzYWdlTGlzdFJlc3BvbnNlVmFsaWRhdG9yIH0gZnJvbSAnLi9tb2RlbHMvR2V0TWVzc2FnZUxpc3RSZXNwb25zZSc7XG5pbXBvcnQgeyBIaXN0b3J5UmVzcG9uc2UsIEhpc3RvcnlSZXNwb25zZVZhbGlkYXRvciB9IGZyb20gJy4vbW9kZWxzL0hpc3RvcnlSZXNwb25zZSc7XG5pbXBvcnQgeyBNYXNzRXh0ZW5kUmVuZXdhbERhdGVSZXF1ZXN0IH0gZnJvbSAnLi9tb2RlbHMvTWFzc0V4dGVuZFJlbmV3YWxEYXRlUmVxdWVzdCc7XG5pbXBvcnQgeyBNYXNzRXh0ZW5kUmVuZXdhbERhdGVSZXNwb25zZSwgTWFzc0V4dGVuZFJlbmV3YWxEYXRlUmVzcG9uc2VWYWxpZGF0b3IgfSBmcm9tICcuL21vZGVscy9NYXNzRXh0ZW5kUmVuZXdhbERhdGVSZXNwb25zZSc7XG5pbXBvcnQgeyBNYXNzRXh0ZW5kUmVuZXdhbERhdGVTdGF0dXNSZXNwb25zZSwgTWFzc0V4dGVuZFJlbmV3YWxEYXRlU3RhdHVzUmVzcG9uc2VWYWxpZGF0b3IgfSBmcm9tICcuL21vZGVscy9NYXNzRXh0ZW5kUmVuZXdhbERhdGVTdGF0dXNSZXNwb25zZSc7XG5pbXBvcnQgeyBPcmRlckxvb2t1cFJlc3BvbnNlLCBPcmRlckxvb2t1cFJlc3BvbnNlVmFsaWRhdG9yIH0gZnJvbSAnLi9tb2RlbHMvT3JkZXJMb29rdXBSZXNwb25zZSc7XG5pbXBvcnQgeyBSZWZ1bmRIaXN0b3J5UmVzcG9uc2UsIFJlZnVuZEhpc3RvcnlSZXNwb25zZVZhbGlkYXRvciB9IGZyb20gJy4vbW9kZWxzL1JlZnVuZEhpc3RvcnlSZXNwb25zZSc7XG5pbXBvcnQgeyBTZW5kVGVzdE5vdGlmaWNhdGlvblJlc3BvbnNlLCBTZW5kVGVzdE5vdGlmaWNhdGlvblJlc3BvbnNlVmFsaWRhdG9yIH0gZnJvbSAnLi9tb2RlbHMvU2VuZFRlc3ROb3RpZmljYXRpb25SZXNwb25zZSc7XG5pbXBvcnQgeyBTdGF0dXNSZXNwb25zZSwgU3RhdHVzUmVzcG9uc2VWYWxpZGF0b3IgfSBmcm9tICcuL21vZGVscy9TdGF0dXNSZXNwb25zZSc7XG5pbXBvcnQgeyBUcmFuc2FjdGlvbkhpc3RvcnlSZXF1ZXN0IH0gZnJvbSAnLi9tb2RlbHMvVHJhbnNhY3Rpb25IaXN0b3J5UmVxdWVzdCc7XG5pbXBvcnQgeyBUcmFuc2FjdGlvbkluZm9SZXNwb25zZSwgVHJhbnNhY3Rpb25JbmZvUmVzcG9uc2VWYWxpZGF0b3IgfSBmcm9tICcuL21vZGVscy9UcmFuc2FjdGlvbkluZm9SZXNwb25zZSc7XG5pbXBvcnQgeyBQZXJmb3JtYW5jZVRlc3RSZXF1ZXN0IH0gZnJvbSAnLi9tb2RlbHMvUGVyZm9ybWFuY2VUZXN0UmVxdWVzdCc7XG5pbXBvcnQgeyBQZXJmb3JtYW5jZVRlc3RSZXNwb25zZSwgUGVyZm9ybWFuY2VUZXN0UmVzcG9uc2VWYWxpZGF0b3IgfSBmcm9tICcuL21vZGVscy9QZXJmb3JtYW5jZVRlc3RSZXNwb25zZSc7XG5pbXBvcnQgeyBQZXJmb3JtYW5jZVRlc3RSZXN1bHRSZXNwb25zZSwgUGVyZm9ybWFuY2VUZXN0UmVzdWx0UmVzcG9uc2VWYWxpZGF0b3IgfSBmcm9tICcuL21vZGVscy9QZXJmb3JtYW5jZVRlc3RSZXN1bHRSZXNwb25zZSc7XG5pbXBvcnQgeyBVcGxvYWRNZXNzYWdlUmVxdWVzdEJvZHkgfSBmcm9tICcuL21vZGVscy9VcGxvYWRNZXNzYWdlUmVxdWVzdEJvZHknO1xuaW1wb3J0IHsgUmVhbHRpbWVVcmxSZXF1ZXN0IH0gZnJvbSAnLi9tb2RlbHMvUmVhbHRpbWVVcmxSZXF1ZXN0JztcbmltcG9ydCB7IFJlYWx0aW1lVXJsUmVzcG9uc2UsIFJlYWx0aW1lVXJsUmVzcG9uc2VWYWxpZGF0b3IgfSBmcm9tICcuL21vZGVscy9SZWFsdGltZVVybFJlc3BvbnNlJztcbmltcG9ydCB7IFZhbGlkYXRvciB9IGZyb20gJy4vbW9kZWxzL1ZhbGlkYXRvcic7XG5pbXBvcnQgeyBTdGF0dXMgfSBmcm9tICcuL21vZGVscy9TdGF0dXMnO1xuZXhwb3J0IHsgU2lnbmVkRGF0YVZlcmlmaWVyLCBWZXJpZmljYXRpb25FeGNlcHRpb24sIFZlcmlmaWNhdGlvblN0YXR1cyB9IGZyb20gJy4vandzX3ZlcmlmaWNhdGlvbidcbmV4cG9ydCB7IFJlY2VpcHRVdGlsaXR5IH0gZnJvbSAnLi9yZWNlaXB0X3V0aWxpdHknXG5leHBvcnQgeyBBY2NvdW50VGVudXJlIH0gZnJvbSBcIi4vbW9kZWxzL0FjY291bnRUZW51cmVcIlxuZXhwb3J0IHsgQWx0ZXJuYXRlUHJvZHVjdCB9IGZyb20gJy4vbW9kZWxzL0FsdGVybmF0ZVByb2R1Y3QnXG5leHBvcnQgeyBBcHBEYXRhIH0gZnJvbSAnLi9tb2RlbHMvQXBwRGF0YSdcbmV4cG9ydCB7IEFwcFRyYW5zYWN0aW9uSW5mb1Jlc3BvbnNlIH0gZnJvbSAnLi9tb2RlbHMvQXBwVHJhbnNhY3Rpb25JbmZvUmVzcG9uc2UnO1xuZXhwb3J0IHsgQXV0b1JlbmV3U3RhdHVzIH0gZnJvbSAnLi9tb2RlbHMvQXV0b1JlbmV3U3RhdHVzJ1xuZXhwb3J0IHsgQnVsbGV0UG9pbnQgfSBmcm9tICcuL21vZGVscy9CdWxsZXRQb2ludCdcbmV4cG9ydCB7IENoZWNrVGVzdE5vdGlmaWNhdGlvblJlc3BvbnNlIH0gZnJvbSAnLi9tb2RlbHMvQ2hlY2tUZXN0Tm90aWZpY2F0aW9uUmVzcG9uc2UnXG5leHBvcnQgeyBDb25zdW1wdGlvblJlcXVlc3QgfSBmcm9tICcuL21vZGVscy9Db25zdW1wdGlvblJlcXVlc3QnXG5leHBvcnQgeyBDb25zdW1wdGlvblJlcXVlc3RWMSB9IGZyb20gJy4vbW9kZWxzL0NvbnN1bXB0aW9uUmVxdWVzdFYxJ1xuZXhwb3J0IHsgVXBkYXRlQXBwQWNjb3VudFRva2VuUmVxdWVzdCB9IGZyb20gJy4vbW9kZWxzL1VwZGF0ZUFwcEFjY291bnRUb2tlblJlcXVlc3QnXG5leHBvcnQgeyBDb25zdW1wdGlvblN0YXR1cyB9IGZyb20gJy4vbW9kZWxzL0NvbnN1bXB0aW9uU3RhdHVzJ1xuZXhwb3J0IHsgRGF0YSB9IGZyb20gJy4vbW9kZWxzL0RhdGEnXG5leHBvcnQgeyBEZWNvZGVkUmVhbHRpbWVSZXF1ZXN0Qm9keSB9IGZyb20gJy4vbW9kZWxzL0RlY29kZWRSZWFsdGltZVJlcXVlc3RCb2R5J1xuZXhwb3J0IHsgRGVmYXVsdENvbmZpZ3VyYXRpb25SZXF1ZXN0IH0gZnJvbSAnLi9tb2RlbHMvRGVmYXVsdENvbmZpZ3VyYXRpb25SZXF1ZXN0J1xuZXhwb3J0IHsgRGVmYXVsdENvbmZpZ3VyYXRpb25SZXNwb25zZSB9IGZyb20gJy4vbW9kZWxzL0RlZmF1bHRDb25maWd1cmF0aW9uUmVzcG9uc2UnXG5leHBvcnQgeyBEZWxpdmVyeVN0YXR1cyB9IGZyb20gJy4vbW9kZWxzL0RlbGl2ZXJ5U3RhdHVzJ1xuZXhwb3J0IHsgRGVsaXZlcnlTdGF0dXNWMSB9IGZyb20gJy4vbW9kZWxzL0RlbGl2ZXJ5U3RhdHVzVjEnXG5leHBvcnQgeyBFbnZpcm9ubWVudCB9IGZyb20gJy4vbW9kZWxzL0Vudmlyb25tZW50J1xuZXhwb3J0IHsgRXhwaXJhdGlvbkludGVudCB9IGZyb20gJy4vbW9kZWxzL0V4cGlyYXRpb25JbnRlbnQnXG5leHBvcnQgeyBFeHRlbmRSZWFzb25Db2RlIH0gZnJvbSAnLi9tb2RlbHMvRXh0ZW5kUmVhc29uQ29kZSdcbmV4cG9ydCB7IEV4dGVuZFJlbmV3YWxEYXRlUmVxdWVzdCB9IGZyb20gJy4vbW9kZWxzL0V4dGVuZFJlbmV3YWxEYXRlUmVxdWVzdCdcbmV4cG9ydCB7IEV4dGVuZFJlbmV3YWxEYXRlUmVzcG9uc2UgfSBmcm9tICcuL21vZGVscy9FeHRlbmRSZW5ld2FsRGF0ZVJlc3BvbnNlJ1xuZXhwb3J0IHsgR2V0SW1hZ2VMaXN0UmVzcG9uc2UgfSBmcm9tICcuL21vZGVscy9HZXRJbWFnZUxpc3RSZXNwb25zZSdcbmV4cG9ydCB7IEdldEltYWdlTGlzdFJlc3BvbnNlSXRlbSB9IGZyb20gJy4vbW9kZWxzL0dldEltYWdlTGlzdFJlc3BvbnNlSXRlbSdcbmV4cG9ydCB7IEdldE1lc3NhZ2VMaXN0UmVzcG9uc2UgfSBmcm9tICcuL21vZGVscy9HZXRNZXNzYWdlTGlzdFJlc3BvbnNlJ1xuZXhwb3J0IHsgR2V0TWVzc2FnZUxpc3RSZXNwb25zZUl0ZW0gfSBmcm9tICcuL21vZGVscy9HZXRNZXNzYWdlTGlzdFJlc3BvbnNlSXRlbSdcbmV4cG9ydCB7IEhlYWRlclBvc2l0aW9uIH0gZnJvbSAnLi9tb2RlbHMvSGVhZGVyUG9zaXRpb24nXG5leHBvcnQgeyBTZW5kQXR0ZW1wdFJlc3VsdCB9IGZyb20gJy4vbW9kZWxzL1NlbmRBdHRlbXB0UmVzdWx0J1xuZXhwb3J0IHsgU2VuZEF0dGVtcHRJdGVtIH0gZnJvbSAnLi9tb2RlbHMvU2VuZEF0dGVtcHRJdGVtJ1xuZXhwb3J0IHsgSGlzdG9yeVJlc3BvbnNlIH0gZnJvbSAnLi9tb2RlbHMvSGlzdG9yeVJlc3BvbnNlJ1xuZXhwb3J0IHsgSW1hZ2VTdGF0ZSB9IGZyb20gJy4vbW9kZWxzL0ltYWdlU3RhdGUnXG5leHBvcnQgeyBJbWFnZVNpemUgfSBmcm9tICcuL21vZGVscy9JbWFnZVNpemUnXG5leHBvcnQgeyBJbkFwcE93bmVyc2hpcFR5cGUgfSBmcm9tICcuL21vZGVscy9JbkFwcE93bmVyc2hpcFR5cGUnXG5leHBvcnQgeyBKV1NSZW5ld2FsSW5mb0RlY29kZWRQYXlsb2FkIH0gZnJvbSAnLi9tb2RlbHMvSldTUmVuZXdhbEluZm9EZWNvZGVkUGF5bG9hZCdcbmV4cG9ydCB7IEpXU1RyYW5zYWN0aW9uRGVjb2RlZFBheWxvYWQgfSBmcm9tICcuL21vZGVscy9KV1NUcmFuc2FjdGlvbkRlY29kZWRQYXlsb2FkJ1xuZXhwb3J0IHsgTGFzdFRyYW5zYWN0aW9uc0l0ZW0gfSBmcm9tICcuL21vZGVscy9MYXN0VHJhbnNhY3Rpb25zSXRlbSdcbmV4cG9ydCB7IExpZmV0aW1lRG9sbGFyc1B1cmNoYXNlZCB9IGZyb20gJy4vbW9kZWxzL0xpZmV0aW1lRG9sbGFyc1B1cmNoYXNlZCdcbmV4cG9ydCB7IExpZmV0aW1lRG9sbGFyc1JlZnVuZGVkIH0gZnJvbSAnLi9tb2RlbHMvTGlmZXRpbWVEb2xsYXJzUmVmdW5kZWQnXG5leHBvcnQgeyBNYXNzRXh0ZW5kUmVuZXdhbERhdGVSZXF1ZXN0IH0gZnJvbSAnLi9tb2RlbHMvTWFzc0V4dGVuZFJlbmV3YWxEYXRlUmVxdWVzdCdcbmV4cG9ydCB7IE1hc3NFeHRlbmRSZW5ld2FsRGF0ZVJlc3BvbnNlIH0gZnJvbSAnLi9tb2RlbHMvTWFzc0V4dGVuZFJlbmV3YWxEYXRlUmVzcG9uc2UnXG5leHBvcnQgeyBNYXNzRXh0ZW5kUmVuZXdhbERhdGVTdGF0dXNSZXNwb25zZSB9IGZyb20gJy4vbW9kZWxzL01hc3NFeHRlbmRSZW5ld2FsRGF0ZVN0YXR1c1Jlc3BvbnNlJ1xuZXhwb3J0IHsgTWVzc2FnZSB9IGZyb20gJy4vbW9kZWxzL01lc3NhZ2UnXG5leHBvcnQgeyBNZXNzYWdlU3RhdGUgfSBmcm9tICcuL21vZGVscy9NZXNzYWdlU3RhdGUnXG5leHBvcnQgeyBOb3RpZmljYXRpb25IaXN0b3J5UmVxdWVzdCB9IGZyb20gJy4vbW9kZWxzL05vdGlmaWNhdGlvbkhpc3RvcnlSZXF1ZXN0J1xuZXhwb3J0IHsgTm90aWZpY2F0aW9uSGlzdG9yeVJlc3BvbnNlIH0gZnJvbSAnLi9tb2RlbHMvTm90aWZpY2F0aW9uSGlzdG9yeVJlc3BvbnNlJ1xuZXhwb3J0IHsgTm90aWZpY2F0aW9uSGlzdG9yeVJlc3BvbnNlSXRlbSB9IGZyb20gJy4vbW9kZWxzL05vdGlmaWNhdGlvbkhpc3RvcnlSZXNwb25zZUl0ZW0nXG5leHBvcnQgeyBOb3RpZmljYXRpb25UeXBlVjIgfSBmcm9tICcuL21vZGVscy9Ob3RpZmljYXRpb25UeXBlVjInXG5leHBvcnQgeyBPZmZlclR5cGUgfSBmcm9tICcuL21vZGVscy9PZmZlclR5cGUnXG5leHBvcnQgeyBPZmZlckRpc2NvdW50VHlwZSB9IGZyb20gJy4vbW9kZWxzL09mZmVyRGlzY291bnRUeXBlJ1xuZXhwb3J0IHsgT3JkZXJMb29rdXBSZXNwb25zZSB9IGZyb20gJy4vbW9kZWxzL09yZGVyTG9va3VwUmVzcG9uc2UnXG5leHBvcnQgeyBPcmRlckxvb2t1cFN0YXR1cyB9IGZyb20gJy4vbW9kZWxzL09yZGVyTG9va3VwU3RhdHVzJ1xuZXhwb3J0IHsgUGVyZm9ybWFuY2VUZXN0Q29uZmlnIH0gZnJvbSAnLi9tb2RlbHMvUGVyZm9ybWFuY2VUZXN0Q29uZmlnJ1xuZXhwb3J0IHsgUGVyZm9ybWFuY2VUZXN0UmVxdWVzdCB9IGZyb20gJy4vbW9kZWxzL1BlcmZvcm1hbmNlVGVzdFJlcXVlc3QnXG5leHBvcnQgeyBQZXJmb3JtYW5jZVRlc3RSZXNwb25zZSB9IGZyb20gJy4vbW9kZWxzL1BlcmZvcm1hbmNlVGVzdFJlc3BvbnNlJ1xuZXhwb3J0IHsgUGVyZm9ybWFuY2VUZXN0UmVzcG9uc2VUaW1lcyB9IGZyb20gJy4vbW9kZWxzL1BlcmZvcm1hbmNlVGVzdFJlc3BvbnNlVGltZXMnXG5leHBvcnQgeyBQZXJmb3JtYW5jZVRlc3RSZXN1bHRSZXNwb25zZSB9IGZyb20gJy4vbW9kZWxzL1BlcmZvcm1hbmNlVGVzdFJlc3VsdFJlc3BvbnNlJ1xuZXhwb3J0IHsgUGVyZm9ybWFuY2VUZXN0U3RhdHVzIH0gZnJvbSAnLi9tb2RlbHMvUGVyZm9ybWFuY2VUZXN0U3RhdHVzJ1xuZXhwb3J0IHsgUGxhdGZvcm0gfSBmcm9tICcuL21vZGVscy9QbGF0Zm9ybSdcbmV4cG9ydCB7IFBsYXlUaW1lIH0gZnJvbSAnLi9tb2RlbHMvUGxheVRpbWUnXG5leHBvcnQgeyBQcmljZUluY3JlYXNlU3RhdHVzIH0gZnJvbSAnLi9tb2RlbHMvUHJpY2VJbmNyZWFzZVN0YXR1cydcbmV4cG9ydCB7IFByb21vdGlvbmFsT2ZmZXIgfSBmcm9tICcuL21vZGVscy9Qcm9tb3Rpb25hbE9mZmVyJ1xuZXhwb3J0IHsgUHJvbW90aW9uYWxPZmZlclNpZ25hdHVyZVYxIH0gZnJvbSAnLi9tb2RlbHMvUHJvbW90aW9uYWxPZmZlclNpZ25hdHVyZVYxJ1xuZXhwb3J0IHsgUHVyY2hhc2VQbGF0Zm9ybSB9IGZyb20gJy4vbW9kZWxzL1B1cmNoYXNlUGxhdGZvcm0nXG5leHBvcnQgeyBSZWFsdGltZVJlcXVlc3RCb2R5IH0gZnJvbSAnLi9tb2RlbHMvUmVhbHRpbWVSZXF1ZXN0Qm9keSdcbmV4cG9ydCB7IFJlYWx0aW1lUmVzcG9uc2VCb2R5IH0gZnJvbSAnLi9tb2RlbHMvUmVhbHRpbWVSZXNwb25zZUJvZHknXG5leHBvcnQgeyBSZWFsdGltZVVybFJlcXVlc3QgfSBmcm9tICcuL21vZGVscy9SZWFsdGltZVVybFJlcXVlc3QnXG5leHBvcnQgeyBSZWFsdGltZVVybFJlc3BvbnNlIH0gZnJvbSAnLi9tb2RlbHMvUmVhbHRpbWVVcmxSZXNwb25zZSdcbmV4cG9ydCB7IFJlZnVuZEhpc3RvcnlSZXNwb25zZSB9IGZyb20gJy4vbW9kZWxzL1JlZnVuZEhpc3RvcnlSZXNwb25zZSdcbmV4cG9ydCB7IFJlZnVuZFByZWZlcmVuY2UgfSBmcm9tICcuL21vZGVscy9SZWZ1bmRQcmVmZXJlbmNlJ1xuZXhwb3J0IHsgUmVmdW5kUHJlZmVyZW5jZVYxIH0gZnJvbSAnLi9tb2RlbHMvUmVmdW5kUHJlZmVyZW5jZVYxJ1xuZXhwb3J0IHsgUmVzcG9uc2VCb2R5VjIgfSBmcm9tICcuL21vZGVscy9SZXNwb25zZUJvZHlWMidcbmV4cG9ydCB7IFJlc3BvbnNlQm9keVYyRGVjb2RlZFBheWxvYWQgfSBmcm9tICcuL21vZGVscy9SZXNwb25zZUJvZHlWMkRlY29kZWRQYXlsb2FkJ1xuZXhwb3J0IHsgUmV2b2NhdGlvblR5cGUgfSBmcm9tICcuL21vZGVscy9SZXZvY2F0aW9uVHlwZSdcbmV4cG9ydCB7IFJldm9jYXRpb25SZWFzb24gfSBmcm9tICcuL21vZGVscy9SZXZvY2F0aW9uUmVhc29uJ1xuZXhwb3J0IHsgU2VuZFRlc3ROb3RpZmljYXRpb25SZXNwb25zZSB9IGZyb20gJy4vbW9kZWxzL1NlbmRUZXN0Tm90aWZpY2F0aW9uUmVzcG9uc2UnXG5leHBvcnQgeyBTdGF0dXMgfSBmcm9tICcuL21vZGVscy9TdGF0dXMnXG5leHBvcnQgeyBTdGF0dXNSZXNwb25zZSB9IGZyb20gJy4vbW9kZWxzL1N0YXR1c1Jlc3BvbnNlJ1xuZXhwb3J0IHsgU3Vic2NyaXB0aW9uR3JvdXBJZGVudGlmaWVySXRlbSB9IGZyb20gJy4vbW9kZWxzL1N1YnNjcmlwdGlvbkdyb3VwSWRlbnRpZmllckl0ZW0nXG5leHBvcnQgeyBTdWJ0eXBlIH0gZnJvbSAnLi9tb2RlbHMvU3VidHlwZSdcbmV4cG9ydCB7IFN1bW1hcnkgfSBmcm9tICcuL21vZGVscy9TdW1tYXJ5J1xuZXhwb3J0IHsgVHJhbnNhY3Rpb25IaXN0b3J5UmVxdWVzdCwgT3JkZXIsIFByb2R1Y3RUeXBlIH0gZnJvbSAnLi9tb2RlbHMvVHJhbnNhY3Rpb25IaXN0b3J5UmVxdWVzdCdcbmV4cG9ydCB7IFRyYW5zYWN0aW9uSW5mb1Jlc3BvbnNlIH0gZnJvbSAnLi9tb2RlbHMvVHJhbnNhY3Rpb25JbmZvUmVzcG9uc2UnXG5leHBvcnQgeyBUcmFuc2FjdGlvblJlYXNvbiB9IGZyb20gJy4vbW9kZWxzL1RyYW5zYWN0aW9uUmVhc29uJ1xuZXhwb3J0IHsgVHlwZSB9IGZyb20gJy4vbW9kZWxzL1R5cGUnXG5leHBvcnQgeyBVcGxvYWRNZXNzYWdlSW1hZ2UgfSBmcm9tICcuL21vZGVscy9VcGxvYWRNZXNzYWdlSW1hZ2UnXG5leHBvcnQgeyBVcGxvYWRNZXNzYWdlUmVxdWVzdEJvZHkgfSBmcm9tICcuL21vZGVscy9VcGxvYWRNZXNzYWdlUmVxdWVzdEJvZHknXG5leHBvcnQgeyBVc2VyU3RhdHVzIH0gZnJvbSAnLi9tb2RlbHMvVXNlclN0YXR1cydcbmV4cG9ydCB7IFByb21vdGlvbmFsT2ZmZXJTaWduYXR1cmVDcmVhdG9yIH0gZnJvbSAnLi9wcm9tb3Rpb25hbF9vZmZlcidcbmV4cG9ydCB7IFByb21vdGlvbmFsT2ZmZXJWMlNpZ25hdHVyZUNyZWF0b3IsIEFkdmFuY2VkQ29tbWVyY2VJbkFwcFNpZ25hdHVyZUNyZWF0b3IsIEFkdmFuY2VkQ29tbWVyY2VJbkFwcFJlcXVlc3QsIEludHJvZHVjdG9yeU9mZmVyRWxpZ2liaWxpdHlTaWduYXR1cmVDcmVhdG9yIH0gZnJvbSAnLi9qd3Nfc2lnbmF0dXJlX2NyZWF0b3InXG5leHBvcnQgeyBEZWNvZGVkU2lnbmVkRGF0YSB9IGZyb20gJy4vbW9kZWxzL0RlY29kZWRTaWduZWREYXRhJ1xuZXhwb3J0IHsgQXBwVHJhbnNhY3Rpb24gfSBmcm9tICcuL21vZGVscy9BcHBUcmFuc2FjdGlvbidcbmV4cG9ydCB7IEV4dGVybmFsUHVyY2hhc2VUb2tlbiB9IGZyb20gJy4vbW9kZWxzL0V4dGVybmFsUHVyY2hhc2VUb2tlbidcblxuZXhwb3J0IHsgQWJzdHJhY3RBZHZhbmNlZENvbW1lcmNlQmFzZUl0ZW0gfSBmcm9tICcuL21vZGVscy9BYnN0cmFjdEFkdmFuY2VkQ29tbWVyY2VCYXNlSXRlbSdcbmV4cG9ydCB7IEFic3RyYWN0QWR2YW5jZWRDb21tZXJjZUl0ZW0gfSBmcm9tICcuL21vZGVscy9BYnN0cmFjdEFkdmFuY2VkQ29tbWVyY2VJdGVtJ1xuZXhwb3J0IHsgQWJzdHJhY3RBZHZhbmNlZENvbW1lcmNlSW5BcHBSZXF1ZXN0IH0gZnJvbSAnLi9tb2RlbHMvQWJzdHJhY3RBZHZhbmNlZENvbW1lcmNlSW5BcHBSZXF1ZXN0J1xuZXhwb3J0IHsgQWJzdHJhY3RBZHZhbmNlZENvbW1lcmNlUmVzcG9uc2UgfSBmcm9tICcuL21vZGVscy9BYnN0cmFjdEFkdmFuY2VkQ29tbWVyY2VSZXNwb25zZSdcbmV4cG9ydCB7IEFkdmFuY2VkQ29tbWVyY2VSZXF1ZXN0IH0gZnJvbSAnLi9tb2RlbHMvQWR2YW5jZWRDb21tZXJjZVJlcXVlc3QnXG5leHBvcnQgeyBBZHZhbmNlZENvbW1lcmNlUmVxdWVzdEluZm8gfSBmcm9tICcuL21vZGVscy9BZHZhbmNlZENvbW1lcmNlUmVxdWVzdEluZm8nXG5leHBvcnQgeyBBZHZhbmNlZENvbW1lcmNlUmVxdWVzdFJlZnVuZFJlcXVlc3QgfSBmcm9tICcuL21vZGVscy9BZHZhbmNlZENvbW1lcmNlUmVxdWVzdFJlZnVuZFJlcXVlc3QnXG5leHBvcnQgeyBBZHZhbmNlZENvbW1lcmNlUmVxdWVzdFJlZnVuZFJlc3BvbnNlIH0gZnJvbSAnLi9tb2RlbHMvQWR2YW5jZWRDb21tZXJjZVJlcXVlc3RSZWZ1bmRSZXNwb25zZSdcbmV4cG9ydCB7IEFkdmFuY2VkQ29tbWVyY2VSZXF1ZXN0UmVmdW5kSXRlbSB9IGZyb20gJy4vbW9kZWxzL0FkdmFuY2VkQ29tbWVyY2VSZXF1ZXN0UmVmdW5kSXRlbSdcbmV4cG9ydCB7IEFkdmFuY2VkQ29tbWVyY2VTdWJzY3JpcHRpb25DcmVhdGVSZXF1ZXN0IH0gZnJvbSAnLi9tb2RlbHMvQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvbkNyZWF0ZVJlcXVlc3QnXG5leHBvcnQgeyBBZHZhbmNlZENvbW1lcmNlU3Vic2NyaXB0aW9uQ3JlYXRlSXRlbSB9IGZyb20gJy4vbW9kZWxzL0FkdmFuY2VkQ29tbWVyY2VTdWJzY3JpcHRpb25DcmVhdGVJdGVtJ1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvbk1vZGlmeUluQXBwUmVxdWVzdCB9IGZyb20gJy4vbW9kZWxzL0FkdmFuY2VkQ29tbWVyY2VTdWJzY3JpcHRpb25Nb2RpZnlJbkFwcFJlcXVlc3QnXG5leHBvcnQgeyBBZHZhbmNlZENvbW1lcmNlU3Vic2NyaXB0aW9uTW9kaWZ5QWRkSXRlbSB9IGZyb20gJy4vbW9kZWxzL0FkdmFuY2VkQ29tbWVyY2VTdWJzY3JpcHRpb25Nb2RpZnlBZGRJdGVtJ1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvbk1vZGlmeUNoYW5nZUl0ZW0gfSBmcm9tICcuL21vZGVscy9BZHZhbmNlZENvbW1lcmNlU3Vic2NyaXB0aW9uTW9kaWZ5Q2hhbmdlSXRlbSdcbmV4cG9ydCB7IEFkdmFuY2VkQ29tbWVyY2VTdWJzY3JpcHRpb25Nb2RpZnlSZW1vdmVJdGVtIH0gZnJvbSAnLi9tb2RlbHMvQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvbk1vZGlmeVJlbW92ZUl0ZW0nXG5leHBvcnQgeyBBZHZhbmNlZENvbW1lcmNlU3Vic2NyaXB0aW9uTW9kaWZ5UGVyaW9kQ2hhbmdlIH0gZnJvbSAnLi9tb2RlbHMvQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvbk1vZGlmeVBlcmlvZENoYW5nZSdcbmV4cG9ydCB7IEFkdmFuY2VkQ29tbWVyY2VTdWJzY3JpcHRpb25Nb2RpZnlEZXNjcmlwdG9ycyB9IGZyb20gJy4vbW9kZWxzL0FkdmFuY2VkQ29tbWVyY2VTdWJzY3JpcHRpb25Nb2RpZnlEZXNjcmlwdG9ycydcbmV4cG9ydCB7IEFkdmFuY2VkQ29tbWVyY2VTdWJzY3JpcHRpb25QcmljZUNoYW5nZVJlcXVlc3QgfSBmcm9tICcuL21vZGVscy9BZHZhbmNlZENvbW1lcmNlU3Vic2NyaXB0aW9uUHJpY2VDaGFuZ2VSZXF1ZXN0J1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvblByaWNlQ2hhbmdlUmVzcG9uc2UgfSBmcm9tICcuL21vZGVscy9BZHZhbmNlZENvbW1lcmNlU3Vic2NyaXB0aW9uUHJpY2VDaGFuZ2VSZXNwb25zZSdcbmV4cG9ydCB7IEFkdmFuY2VkQ29tbWVyY2VTdWJzY3JpcHRpb25QcmljZUNoYW5nZUl0ZW0gfSBmcm9tICcuL21vZGVscy9BZHZhbmNlZENvbW1lcmNlU3Vic2NyaXB0aW9uUHJpY2VDaGFuZ2VJdGVtJ1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvblJldm9rZVJlcXVlc3QgfSBmcm9tICcuL21vZGVscy9BZHZhbmNlZENvbW1lcmNlU3Vic2NyaXB0aW9uUmV2b2tlUmVxdWVzdCdcbmV4cG9ydCB7IEFkdmFuY2VkQ29tbWVyY2VTdWJzY3JpcHRpb25SZXZva2VSZXNwb25zZSB9IGZyb20gJy4vbW9kZWxzL0FkdmFuY2VkQ29tbWVyY2VTdWJzY3JpcHRpb25SZXZva2VSZXNwb25zZSdcbmV4cG9ydCB7IEFkdmFuY2VkQ29tbWVyY2VTdWJzY3JpcHRpb25DYW5jZWxSZXF1ZXN0IH0gZnJvbSAnLi9tb2RlbHMvQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvbkNhbmNlbFJlcXVlc3QnXG5leHBvcnQgeyBBZHZhbmNlZENvbW1lcmNlU3Vic2NyaXB0aW9uQ2FuY2VsUmVzcG9uc2UgfSBmcm9tICcuL21vZGVscy9BZHZhbmNlZENvbW1lcmNlU3Vic2NyaXB0aW9uQ2FuY2VsUmVzcG9uc2UnXG5leHBvcnQgeyBBZHZhbmNlZENvbW1lcmNlU3Vic2NyaXB0aW9uUmVhY3RpdmF0ZUluQXBwUmVxdWVzdCB9IGZyb20gJy4vbW9kZWxzL0FkdmFuY2VkQ29tbWVyY2VTdWJzY3JpcHRpb25SZWFjdGl2YXRlSW5BcHBSZXF1ZXN0J1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvblJlYWN0aXZhdGVJdGVtIH0gZnJvbSAnLi9tb2RlbHMvQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvblJlYWN0aXZhdGVJdGVtJ1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvbkNoYW5nZU1ldGFkYXRhUmVxdWVzdCB9IGZyb20gJy4vbW9kZWxzL0FkdmFuY2VkQ29tbWVyY2VTdWJzY3JpcHRpb25DaGFuZ2VNZXRhZGF0YVJlcXVlc3QnXG5leHBvcnQgeyBBZHZhbmNlZENvbW1lcmNlU3Vic2NyaXB0aW9uQ2hhbmdlTWV0YWRhdGFSZXNwb25zZSB9IGZyb20gJy4vbW9kZWxzL0FkdmFuY2VkQ29tbWVyY2VTdWJzY3JpcHRpb25DaGFuZ2VNZXRhZGF0YVJlc3BvbnNlJ1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvbkNoYW5nZU1ldGFkYXRhSXRlbSB9IGZyb20gJy4vbW9kZWxzL0FkdmFuY2VkQ29tbWVyY2VTdWJzY3JpcHRpb25DaGFuZ2VNZXRhZGF0YUl0ZW0nXG5leHBvcnQgeyBBZHZhbmNlZENvbW1lcmNlU3Vic2NyaXB0aW9uQ2hhbmdlTWV0YWRhdGFEZXNjcmlwdG9ycyB9IGZyb20gJy4vbW9kZWxzL0FkdmFuY2VkQ29tbWVyY2VTdWJzY3JpcHRpb25DaGFuZ2VNZXRhZGF0YURlc2NyaXB0b3JzJ1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvbk1pZ3JhdGVSZXF1ZXN0IH0gZnJvbSAnLi9tb2RlbHMvQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvbk1pZ3JhdGVSZXF1ZXN0J1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvbk1pZ3JhdGVSZXNwb25zZSB9IGZyb20gJy4vbW9kZWxzL0FkdmFuY2VkQ29tbWVyY2VTdWJzY3JpcHRpb25NaWdyYXRlUmVzcG9uc2UnXG5leHBvcnQgeyBBZHZhbmNlZENvbW1lcmNlU3Vic2NyaXB0aW9uTWlncmF0ZUl0ZW0gfSBmcm9tICcuL21vZGVscy9BZHZhbmNlZENvbW1lcmNlU3Vic2NyaXB0aW9uTWlncmF0ZUl0ZW0nXG5leHBvcnQgeyBBZHZhbmNlZENvbW1lcmNlU3Vic2NyaXB0aW9uTWlncmF0ZVJlbmV3YWxJdGVtIH0gZnJvbSAnLi9tb2RlbHMvQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvbk1pZ3JhdGVSZW5ld2FsSXRlbSdcbmV4cG9ydCB7IEFkdmFuY2VkQ29tbWVyY2VTdWJzY3JpcHRpb25NaWdyYXRlRGVzY3JpcHRvcnMgfSBmcm9tICcuL21vZGVscy9BZHZhbmNlZENvbW1lcmNlU3Vic2NyaXB0aW9uTWlncmF0ZURlc2NyaXB0b3JzJ1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZU9uZVRpbWVDaGFyZ2VDcmVhdGVSZXF1ZXN0IH0gZnJvbSAnLi9tb2RlbHMvQWR2YW5jZWRDb21tZXJjZU9uZVRpbWVDaGFyZ2VDcmVhdGVSZXF1ZXN0J1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZU9uZVRpbWVDaGFyZ2VJdGVtIH0gZnJvbSAnLi9tb2RlbHMvQWR2YW5jZWRDb21tZXJjZU9uZVRpbWVDaGFyZ2VJdGVtJ1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZVJlYXNvbiB9IGZyb20gJy4vbW9kZWxzL0FkdmFuY2VkQ29tbWVyY2VSZWFzb24nXG5leHBvcnQgeyBBZHZhbmNlZENvbW1lcmNlRWZmZWN0aXZlIH0gZnJvbSAnLi9tb2RlbHMvQWR2YW5jZWRDb21tZXJjZUVmZmVjdGl2ZSdcbmV4cG9ydCB7IEFkdmFuY2VkQ29tbWVyY2VQZXJpb2QgfSBmcm9tICcuL21vZGVscy9BZHZhbmNlZENvbW1lcmNlUGVyaW9kJ1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZU9mZmVyIH0gZnJvbSAnLi9tb2RlbHMvQWR2YW5jZWRDb21tZXJjZU9mZmVyJ1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZU9mZmVyUGVyaW9kIH0gZnJvbSAnLi9tb2RlbHMvQWR2YW5jZWRDb21tZXJjZU9mZmVyUGVyaW9kJ1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZU9mZmVyUmVhc29uIH0gZnJvbSAnLi9tb2RlbHMvQWR2YW5jZWRDb21tZXJjZU9mZmVyUmVhc29uJ1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZVJlZnVuZFJlYXNvbiB9IGZyb20gJy4vbW9kZWxzL0FkdmFuY2VkQ29tbWVyY2VSZWZ1bmRSZWFzb24nXG5leHBvcnQgeyBBZHZhbmNlZENvbW1lcmNlUmVmdW5kVHlwZSB9IGZyb20gJy4vbW9kZWxzL0FkdmFuY2VkQ29tbWVyY2VSZWZ1bmRUeXBlJ1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZURlc2NyaXB0b3JzIH0gZnJvbSAnLi9tb2RlbHMvQWR2YW5jZWRDb21tZXJjZURlc2NyaXB0b3JzJ1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZUluZm8gfSBmcm9tICcuL21vZGVscy9BZHZhbmNlZENvbW1lcmNlSW5mbydcbmV4cG9ydCB7IEFkdmFuY2VkQ29tbWVyY2VQcmljZUluY3JlYXNlSW5mbyB9IGZyb20gJy4vbW9kZWxzL0FkdmFuY2VkQ29tbWVyY2VQcmljZUluY3JlYXNlSW5mbydcbmV4cG9ydCB7IEFkdmFuY2VkQ29tbWVyY2VQcmljZUluY3JlYXNlSW5mb1N0YXR1cyB9IGZyb20gJy4vbW9kZWxzL0FkdmFuY2VkQ29tbWVyY2VQcmljZUluY3JlYXNlSW5mb1N0YXR1cydcbmV4cG9ydCB7IEFkdmFuY2VkQ29tbWVyY2VSZWZ1bmQgfSBmcm9tICcuL21vZGVscy9BZHZhbmNlZENvbW1lcmNlUmVmdW5kJ1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZVJlbmV3YWxJbmZvIH0gZnJvbSAnLi9tb2RlbHMvQWR2YW5jZWRDb21tZXJjZVJlbmV3YWxJbmZvJ1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZVJlbmV3YWxJdGVtIH0gZnJvbSAnLi9tb2RlbHMvQWR2YW5jZWRDb21tZXJjZVJlbmV3YWxJdGVtJ1xuZXhwb3J0IHsgQWR2YW5jZWRDb21tZXJjZVRyYW5zYWN0aW9uSW5mbyB9IGZyb20gJy4vbW9kZWxzL0FkdmFuY2VkQ29tbWVyY2VUcmFuc2FjdGlvbkluZm8nXG5leHBvcnQgeyBBZHZhbmNlZENvbW1lcmNlVHJhbnNhY3Rpb25JdGVtIH0gZnJvbSAnLi9tb2RlbHMvQWR2YW5jZWRDb21tZXJjZVRyYW5zYWN0aW9uSXRlbSdcbmV4cG9ydCB7IEJpbGxpbmdQbGFuVHlwZSB9IGZyb20gJy4vbW9kZWxzL0JpbGxpbmdQbGFuVHlwZSdcbmV4cG9ydCB7IFJlbmV3YWxCaWxsaW5nUGxhblR5cGUgfSBmcm9tICcuL21vZGVscy9SZW5ld2FsQmlsbGluZ1BsYW5UeXBlJ1xuZXhwb3J0IHsgUmVuZXdhbENvbW1pdG1lbnRJbmZvIH0gZnJvbSAnLi9tb2RlbHMvUmVuZXdhbENvbW1pdG1lbnRJbmZvJ1xuZXhwb3J0IHsgVHJhbnNhY3Rpb25Db21taXRtZW50SW5mbyB9IGZyb20gJy4vbW9kZWxzL1RyYW5zYWN0aW9uQ29tbWl0bWVudEluZm8nXG5cbmltcG9ydCBqc29ud2VidG9rZW4gPSByZXF1aXJlKCdqc29ud2VidG9rZW4nKTtcbmltcG9ydCB7IEFwcFRyYW5zYWN0aW9uSW5mb1Jlc3BvbnNlLCBBcHBUcmFuc2FjdGlvbkluZm9SZXNwb25zZVZhbGlkYXRvciB9IGZyb20gJy4vbW9kZWxzL0FwcFRyYW5zYWN0aW9uSW5mb1Jlc3BvbnNlJztcbmltcG9ydCB7IE5vdGlmaWNhdGlvbkhpc3RvcnlSZXF1ZXN0IH0gZnJvbSAnLi9tb2RlbHMvTm90aWZpY2F0aW9uSGlzdG9yeVJlcXVlc3QnO1xuaW1wb3J0IHsgTm90aWZpY2F0aW9uSGlzdG9yeVJlc3BvbnNlLCBOb3RpZmljYXRpb25IaXN0b3J5UmVzcG9uc2VWYWxpZGF0b3IgfSBmcm9tICcuL21vZGVscy9Ob3RpZmljYXRpb25IaXN0b3J5UmVzcG9uc2UnO1xuaW1wb3J0IHsgVVJMU2VhcmNoUGFyYW1zIH0gZnJvbSAndXJsJztcblxuZXhwb3J0IGNsYXNzIEFwcFN0b3JlU2VydmVyQVBJQ2xpZW50IHtcbiAgICBwcml2YXRlIHN0YXRpYyBQUk9EVUNUSU9OX1VSTCA9IFwiaHR0cHM6Ly9hcGkuc3RvcmVraXQuYXBwbGUuY29tXCI7XG4gICAgcHJpdmF0ZSBzdGF0aWMgU0FOREJPWF9VUkwgPSBcImh0dHBzOi8vYXBpLnN0b3Jla2l0LXNhbmRib3guYXBwbGUuY29tXCI7XG4gICAgcHJpdmF0ZSBzdGF0aWMgTE9DQUxfVEVTVElOR19VUkwgPSBcImh0dHBzOi8vbG9jYWwtdGVzdGluZy1iYXNlLXVybFwiO1xuICAgIHByaXZhdGUgc3RhdGljIFVTRVJfQUdFTlQgPSBcImFwcC1zdG9yZS1zZXJ2ZXItbGlicmFyeS9ub2RlLzMuMS4wXCI7XG5cbiAgICBwcml2YXRlIGlzc3VlcklkOiBzdHJpbmdcbiAgICBwcml2YXRlIGtleUlkOiBzdHJpbmdcbiAgICBwcml2YXRlIHNpZ25pbmdLZXk6IHN0cmluZ1xuICAgIHByaXZhdGUgYnVuZGxlSWQ6IHN0cmluZ1xuICAgIHByaXZhdGUgdXJsQmFzZTogc3RyaW5nXG5cbiAgICAvKipcbiAgICAgKiBDcmVhdGUgYW4gQXBwIFN0b3JlIFNlcnZlciBBUEkgY2xpZW50XG4gICAgICogQHBhcmFtIHNpZ25pbmdLZXkgWW91ciBwcml2YXRlIGtleSBkb3dubG9hZGVkIGZyb20gQXBwIFN0b3JlIENvbm5lY3RcbiAgICAgKiBAcGFyYW0ga2V5SWQgWW91ciBwcml2YXRlIGtleSBJRCBmcm9tIEFwcCBTdG9yZSBDb25uZWN0XG4gICAgICogQHBhcmFtIGlzc3VlcklkIFlvdXIgaXNzdWVyIElEIGZyb20gdGhlIEtleXMgcGFnZSBpbiBBcHAgU3RvcmUgQ29ubmVjdFxuICAgICAqIEBwYXJhbSBidW5kbGVJZCBZb3VyIGFwcOKAmXMgYnVuZGxlIElEXG4gICAgICogQHBhcmFtIGVudmlyb25tZW50IFRoZSBlbnZpcm9ubWVudCB0byB0YXJnZXRcbiAgICAgKi9cbiAgICBwdWJsaWMgY29uc3RydWN0b3Ioc2lnbmluZ0tleTogc3RyaW5nLCBrZXlJZDogc3RyaW5nLCBpc3N1ZXJJZDogc3RyaW5nLCBidW5kbGVJZDogc3RyaW5nLCBlbnZpcm9ubWVudDogRW52aXJvbm1lbnQpIHtcbiAgICAgICAgdGhpcy5pc3N1ZXJJZCA9IGlzc3VlcklkXG4gICAgICAgIHRoaXMua2V5SWQgPSBrZXlJZFxuICAgICAgICB0aGlzLmJ1bmRsZUlkID0gYnVuZGxlSWRcbiAgICAgICAgdGhpcy5zaWduaW5nS2V5ID0gc2lnbmluZ0tleVxuICAgICAgICBzd2l0Y2goZW52aXJvbm1lbnQpIHtcbiAgICAgICAgICAgIGNhc2UgRW52aXJvbm1lbnQuWENPREU6XG4gICAgICAgICAgICAgICAgdGhyb3cgbmV3IEVycm9yKFwiWGNvZGUgaXMgbm90IGEgc3VwcG9ydGVkIGVudmlyb25tZW50IGZvciBhbiBBcHBTdG9yZVNlcnZlckFQSUNsaWVudFwiKVxuICAgICAgICAgICAgY2FzZSBFbnZpcm9ubWVudC5QUk9EVUNUSU9OOlxuICAgICAgICAgICAgICAgIHRoaXMudXJsQmFzZSA9IEFwcFN0b3JlU2VydmVyQVBJQ2xpZW50LlBST0RVQ1RJT05fVVJMXG4gICAgICAgICAgICAgICAgYnJlYWtcbiAgICAgICAgICAgIGNhc2UgRW52aXJvbm1lbnQuTE9DQUxfVEVTVElORzpcbiAgICAgICAgICAgICAgICB0aGlzLnVybEJhc2UgPSBBcHBTdG9yZVNlcnZlckFQSUNsaWVudC5MT0NBTF9URVNUSU5HX1VSTFxuICAgICAgICAgICAgICAgIGJyZWFrXG4gICAgICAgICAgICBjYXNlIEVudmlyb25tZW50LlNBTkRCT1g6XG4gICAgICAgICAgICAgICAgdGhpcy51cmxCYXNlID0gQXBwU3RvcmVTZXJ2ZXJBUElDbGllbnQuU0FOREJPWF9VUkxcbiAgICAgICAgICAgICAgICBicmVha1xuICAgICAgICB9XG4gICAgfVxuXG4gICAgcHJvdGVjdGVkIGFzeW5jIG1ha2VSZXF1ZXN0PFQ+KHBhdGg6IHN0cmluZywgbWV0aG9kOiBzdHJpbmcsIHF1ZXJ5UGFyYW1ldGVyczogeyBba2V5OiBzdHJpbmddOiBzdHJpbmdbXX0sIGJvZHk6IG9iamVjdCB8IEJ1ZmZlciB8IG51bGwsIHZhbGlkYXRvcjogVmFsaWRhdG9yPFQ+IHwgbnVsbCwgY29udGVudFR5cGU/OiBzdHJpbmcpOiBQcm9taXNlPFQ+IHtcbiAgICAgICAgY29uc3QgaGVhZGVyczogeyBba2V5OiBzdHJpbmddOiBzdHJpbmcgfSA9IHtcbiAgICAgICAgICAgICdVc2VyLUFnZW50JzogQXBwU3RvcmVTZXJ2ZXJBUElDbGllbnQuVVNFUl9BR0VOVCxcbiAgICAgICAgICAgICdBdXRob3JpemF0aW9uJzogJ0JlYXJlciAnICsgdGhpcy5jcmVhdGVCZWFyZXJUb2tlbigpLFxuICAgICAgICAgICAgJ0FjY2VwdCc6ICdhcHBsaWNhdGlvbi9qc29uJyxcbiAgICAgICAgfVxuICAgICAgICBjb25zdCBwYXJzZWRRdWVyeVBhcmFtZXRlcnMgPSBuZXcgVVJMU2VhcmNoUGFyYW1zKClcbiAgICAgICAgZm9yIChjb25zdCBxdWVyeVBhcmFtIGluIHF1ZXJ5UGFyYW1ldGVycykge1xuICAgICAgICAgICAgZm9yIChjb25zdCBxdWVyeVZhbCBvZiBxdWVyeVBhcmFtZXRlcnNbcXVlcnlQYXJhbV0pIHtcbiAgICAgICAgICAgICAgICBwYXJzZWRRdWVyeVBhcmFtZXRlcnMuYXBwZW5kKHF1ZXJ5UGFyYW0sIHF1ZXJ5VmFsKVxuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICAgIGxldCByZXF1ZXN0Qm9keTogc3RyaW5nIHwgQnVmZmVyIHwgdW5kZWZpbmVkID0gdW5kZWZpbmVkXG4gICAgICAgIGlmIChib2R5IGluc3RhbmNlb2YgQnVmZmVyKSB7XG4gICAgICAgICAgICByZXF1ZXN0Qm9keSA9IGJvZHlcbiAgICAgICAgICAgIGlmIChjb250ZW50VHlwZSkge1xuICAgICAgICAgICAgICAgIGhlYWRlcnNbJ0NvbnRlbnQtVHlwZSddID0gY29udGVudFR5cGVcbiAgICAgICAgICAgIH1cbiAgICAgICAgfSBlbHNlIGlmIChib2R5ICE9IG51bGwpIHtcbiAgICAgICAgICAgIHJlcXVlc3RCb2R5ID0gSlNPTi5zdHJpbmdpZnkoYm9keSlcbiAgICAgICAgICAgIGhlYWRlcnNbJ0NvbnRlbnQtVHlwZSddID0gJ2FwcGxpY2F0aW9uL2pzb24nXG4gICAgICAgIH1cblxuICAgICAgICBjb25zdCByZXNwb25zZSA9IGF3YWl0IHRoaXMubWFrZUZldGNoUmVxdWVzdChwYXRoLCBwYXJzZWRRdWVyeVBhcmFtZXRlcnMsIG1ldGhvZCwgcmVxdWVzdEJvZHksIGhlYWRlcnMpXG5cbiAgICAgICAgaWYocmVzcG9uc2Uub2spIHtcbiAgICAgICAgICAgIC8vIFN1Y2Nlc3NcbiAgICAgICAgICAgIGlmICh2YWxpZGF0b3IgPT0gbnVsbCkge1xuICAgICAgICAgICAgICAgIHJldHVybiBudWxsIGFzIFRcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgY29uc3QgcmVzcG9uc2VCb2R5ID0gYXdhaXQgcmVzcG9uc2UuanNvbigpXG5cbiAgICAgICAgICAgIGlmICghdmFsaWRhdG9yLnZhbGlkYXRlKHJlc3BvbnNlQm9keSkpIHtcbiAgICAgICAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoXCJVbmV4cGVjdGVkIHJlc3BvbnNlIGJvZHkgZm9ybWF0XCIpXG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIHJldHVybiByZXNwb25zZUJvZHlcbiAgICAgICAgfVxuXG4gICAgICAgIHRyeSB7XG4gICAgICAgICAgICBjb25zdCByZXNwb25zZUJvZHkgPSBhd2FpdCByZXNwb25zZS5qc29uKClcbiAgICAgICAgICAgIGNvbnN0IGVycm9yQ29kZSA9IHJlc3BvbnNlQm9keVsnZXJyb3JDb2RlJ11cbiAgICAgICAgICAgIGNvbnN0IGVycm9yTWVzc2FnZSA9IHJlc3BvbnNlQm9keVsnZXJyb3JNZXNzYWdlJ11cblxuICAgICAgICAgICAgaWYgKGVycm9yQ29kZSkge1xuICAgICAgICAgICAgICAgIHRocm93IG5ldyBBUElFeGNlcHRpb24ocmVzcG9uc2Uuc3RhdHVzLCBlcnJvckNvZGUsIGVycm9yTWVzc2FnZSlcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgdGhyb3cgbmV3IEFQSUV4Y2VwdGlvbihyZXNwb25zZS5zdGF0dXMpXG4gICAgICAgIH0gY2F0Y2ggKGUpIHtcbiAgICAgICAgICAgIGlmIChlIGluc3RhbmNlb2YgQVBJRXhjZXB0aW9uKSB7XG4gICAgICAgICAgICAgICAgdGhyb3cgZVxuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICB0aHJvdyBuZXcgQVBJRXhjZXB0aW9uKHJlc3BvbnNlLnN0YXR1cylcbiAgICAgICAgfVxuICAgIH1cblxuICAgIHByb3RlY3RlZCBhc3luYyBtYWtlRmV0Y2hSZXF1ZXN0KHBhdGg6IHN0cmluZywgcGFyc2VkUXVlcnlQYXJhbWV0ZXJzOiBVUkxTZWFyY2hQYXJhbXMsIG1ldGhvZDogc3RyaW5nLCByZXF1ZXN0Qm9keTogc3RyaW5nIHwgQnVmZmVyIHwgdW5kZWZpbmVkLCBoZWFkZXJzOiB7IFtrZXk6IHN0cmluZ106IHN0cmluZzsgfSkge1xuICAgICAgICByZXR1cm4gYXdhaXQgZmV0Y2godGhpcy51cmxCYXNlICsgcGF0aCArICc/JyArIHBhcnNlZFF1ZXJ5UGFyYW1ldGVycywge1xuICAgICAgICAgICAgbWV0aG9kOiBtZXRob2QsXG4gICAgICAgICAgICBib2R5OiByZXF1ZXN0Qm9keSxcbiAgICAgICAgICAgIGhlYWRlcnM6IGhlYWRlcnNcbiAgICAgICAgfSk7XG4gICAgfVxuXG4gICAgLyoqXG4gICAgICogVXNlcyBhIHN1YnNjcmlwdGlvbuKAmXMgcHJvZHVjdCBpZGVudGlmaWVyIHRvIGV4dGVuZCB0aGUgcmVuZXdhbCBkYXRlIGZvciBhbGwgb2YgaXRzIGVsaWdpYmxlIGFjdGl2ZSBzdWJzY3JpYmVycy5cbiAgICAgKlxuICAgICAqIEBwYXJhbSBtYXNzRXh0ZW5kUmVuZXdhbERhdGVSZXF1ZXN0IFRoZSByZXF1ZXN0IGJvZHkgZm9yIGV4dGVuZGluZyBhIHN1YnNjcmlwdGlvbiByZW5ld2FsIGRhdGUgZm9yIGFsbCBvZiBpdHMgYWN0aXZlIHN1YnNjcmliZXJzLlxuICAgICAqIEByZXR1cm4gQSByZXNwb25zZSB0aGF0IGluZGljYXRlcyB0aGUgc2VydmVyIHN1Y2Nlc3NmdWxseSByZWNlaXZlZCB0aGUgc3Vic2NyaXB0aW9uLXJlbmV3YWwtZGF0ZSBleHRlbnNpb24gcmVxdWVzdC5cbiAgICAgKiBAdGhyb3dzIEFQSUV4Y2VwdGlvbiBJZiBhIHJlc3BvbnNlIHdhcyByZXR1cm5lZCBpbmRpY2F0aW5nIHRoZSByZXF1ZXN0IGNvdWxkIG5vdCBiZSBwcm9jZXNzZWRcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvZXh0ZW5kX3N1YnNjcmlwdGlvbl9yZW5ld2FsX2RhdGVzX2Zvcl9hbGxfYWN0aXZlX3N1YnNjcmliZXJzIEV4dGVuZCBTdWJzY3JpcHRpb24gUmVuZXdhbCBEYXRlcyBmb3IgQWxsIEFjdGl2ZSBTdWJzY3JpYmVyc31cbiAgICAgKi9cbiAgICBwdWJsaWMgYXN5bmMgZXh0ZW5kUmVuZXdhbERhdGVGb3JBbGxBY3RpdmVTdWJzY3JpYmVycyhtYXNzRXh0ZW5kUmVuZXdhbERhdGVSZXF1ZXN0OiBNYXNzRXh0ZW5kUmVuZXdhbERhdGVSZXF1ZXN0KTogUHJvbWlzZTxNYXNzRXh0ZW5kUmVuZXdhbERhdGVSZXNwb25zZT4ge1xuICAgICAgICByZXR1cm4gYXdhaXQgdGhpcy5tYWtlUmVxdWVzdChcIi9pbkFwcHMvdjEvc3Vic2NyaXB0aW9ucy9leHRlbmQvbWFzc1wiLCBcIlBPU1RcIiwge30sIG1hc3NFeHRlbmRSZW5ld2FsRGF0ZVJlcXVlc3QsIG5ldyBNYXNzRXh0ZW5kUmVuZXdhbERhdGVSZXNwb25zZVZhbGlkYXRvcigpLCAnYXBwbGljYXRpb24vanNvbicpO1xuICAgIH1cblxuICAgIC8qKlxuICAgICAqIEV4dGVuZHMgdGhlIHJlbmV3YWwgZGF0ZSBvZiBhIGN1c3RvbWVy4oCZcyBhY3RpdmUgc3Vic2NyaXB0aW9uIHVzaW5nIHRoZSBvcmlnaW5hbCB0cmFuc2FjdGlvbiBpZGVudGlmaWVyLlxuICAgICAqXG4gICAgICogQHBhcmFtIG9yaWdpbmFsVHJhbnNhY3Rpb25JZCAgICBUaGUgb3JpZ2luYWwgdHJhbnNhY3Rpb24gaWRlbnRpZmllciBvZiB0aGUgc3Vic2NyaXB0aW9uIHJlY2VpdmluZyBhIHJlbmV3YWwgZGF0ZSBleHRlbnNpb24uXG4gICAgICogQHBhcmFtIGV4dGVuZFJlbmV3YWxEYXRlUmVxdWVzdCBUaGUgcmVxdWVzdCBib2R5IGNvbnRhaW5pbmcgc3Vic2NyaXB0aW9uLXJlbmV3YWwtZXh0ZW5zaW9uIGRhdGEuXG4gICAgICogQHJldHVybiBBIHJlc3BvbnNlIHRoYXQgaW5kaWNhdGVzIHdoZXRoZXIgYW4gaW5kaXZpZHVhbCByZW5ld2FsLWRhdGUgZXh0ZW5zaW9uIHN1Y2NlZWRlZCwgYW5kIHJlbGF0ZWQgZGV0YWlscy5cbiAgICAgKiBAdGhyb3dzIEFQSUV4Y2VwdGlvbiBJZiBhIHJlc3BvbnNlIHdhcyByZXR1cm5lZCBpbmRpY2F0aW5nIHRoZSByZXF1ZXN0IGNvdWxkIG5vdCBiZSBwcm9jZXNzZWRcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvZXh0ZW5kX2Ffc3Vic2NyaXB0aW9uX3JlbmV3YWxfZGF0ZSBFeHRlbmQgYSBTdWJzY3JpcHRpb24gUmVuZXdhbCBEYXRlfVxuICAgICAqL1xuICAgIHB1YmxpYyBhc3luYyBleHRlbmRTdWJzY3JpcHRpb25SZW5ld2FsRGF0ZShvcmlnaW5hbFRyYW5zYWN0aW9uSWQ6IHN0cmluZywgZXh0ZW5kUmVuZXdhbERhdGVSZXF1ZXN0OiBFeHRlbmRSZW5ld2FsRGF0ZVJlcXVlc3QpOiBQcm9taXNlPEV4dGVuZFJlbmV3YWxEYXRlUmVzcG9uc2U+IHtcbiAgICAgICAgcmV0dXJuIGF3YWl0IHRoaXMubWFrZVJlcXVlc3Q8RXh0ZW5kUmVuZXdhbERhdGVSZXNwb25zZT4oXCIvaW5BcHBzL3YxL3N1YnNjcmlwdGlvbnMvZXh0ZW5kL1wiICsgb3JpZ2luYWxUcmFuc2FjdGlvbklkLCBcIlBVVFwiLCB7fSwgZXh0ZW5kUmVuZXdhbERhdGVSZXF1ZXN0LCBuZXcgRXh0ZW5kUmVuZXdhbERhdGVSZXNwb25zZVZhbGlkYXRvcigpLCAnYXBwbGljYXRpb24vanNvbicpO1xuICAgIH1cblxuICAgIC8qKlxuICAgICAqIEdldCB0aGUgc3RhdHVzZXMgZm9yIGFsbCBvZiBhIGN1c3RvbWVy4oCZcyBhdXRvLXJlbmV3YWJsZSBzdWJzY3JpcHRpb25zIGluIHlvdXIgYXBwLlxuICAgICAqXG4gICAgICogQHBhcmFtIGFueVRyYW5zYWN0aW9uSWQgQW55IHRyYW5zYWN0aW9uSWQsIG9yaWdpbmFsVHJhbnNhY3Rpb25JZCwgb3IgYXBwVHJhbnNhY3Rpb25JZCB0aGF0IGJlbG9uZ3MgdG8gdGhlIGN1c3RvbWVyIGZvciB5b3VyIGFwcC5cbiAgICAgKiBAcGFyYW0gc3RhdHVzIEFuIG9wdGlvbmFsIGZpbHRlciB0aGF0IGluZGljYXRlcyB0aGUgc3RhdHVzIG9mIHN1YnNjcmlwdGlvbnMgdG8gaW5jbHVkZSBpbiB0aGUgcmVzcG9uc2UuIFlvdXIgcXVlcnkgbWF5IHNwZWNpZnkgbW9yZSB0aGFuIG9uZSBzdGF0dXMgcXVlcnkgcGFyYW1ldGVyLlxuICAgICAqIEByZXR1cm4gQSByZXNwb25zZSB0aGF0IGNvbnRhaW5zIHN0YXR1cyBpbmZvcm1hdGlvbiBmb3IgYWxsIG9mIGEgY3VzdG9tZXLigJlzIGF1dG8tcmVuZXdhYmxlIHN1YnNjcmlwdGlvbnMgaW4geW91ciBhcHAuXG4gICAgICogQHRocm93cyBBUElFeGNlcHRpb24gSWYgYSByZXNwb25zZSB3YXMgcmV0dXJuZWQgaW5kaWNhdGluZyB0aGUgcmVxdWVzdCBjb3VsZCBub3QgYmUgcHJvY2Vzc2VkXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2dldF9hbGxfc3Vic2NyaXB0aW9uX3N0YXR1c2VzIEdldCBBbGwgU3Vic2NyaXB0aW9uIFN0YXR1c2VzfVxuICAgICAqL1xuICAgIHB1YmxpYyBhc3luYyBnZXRBbGxTdWJzY3JpcHRpb25TdGF0dXNlcyhhbnlUcmFuc2FjdGlvbklkOiBzdHJpbmcsIHN0YXR1czogU3RhdHVzW10gfCB1bmRlZmluZWQgPSB1bmRlZmluZWQpOiBQcm9taXNlPFN0YXR1c1Jlc3BvbnNlPiB7XG4gICAgICAgIGNvbnN0IHF1ZXJ5UGFyYW1ldGVyczogeyBba2V5OiBzdHJpbmddOiBbc3RyaW5nXX0gPSB7fVxuICAgICAgICBpZiAoc3RhdHVzICE9IG51bGwpIHtcbiAgICAgICAgICAgIHF1ZXJ5UGFyYW1ldGVyc1tcInN0YXR1c1wiXSA9IHN0YXR1cy5tYXAocyA9PiBzLnRvU3RyaW5nKCkpIGFzIFtzdHJpbmddO1xuICAgICAgICB9XG5cbiAgICAgICAgcmV0dXJuIGF3YWl0IHRoaXMubWFrZVJlcXVlc3QoXCIvaW5BcHBzL3YxL3N1YnNjcmlwdGlvbnMvXCIgKyBhbnlUcmFuc2FjdGlvbklkLCBcIkdFVFwiLCBxdWVyeVBhcmFtZXRlcnMsIG51bGwsIG5ldyBTdGF0dXNSZXNwb25zZVZhbGlkYXRvcigpLCB1bmRlZmluZWQpO1xuICAgIH1cblxuICAgIC8qKlxuICAgICAqIEdldCBhIHBhZ2luYXRlZCBsaXN0IG9mIGFsbCBvZiBhIGN1c3RvbWVy4oCZcyByZWZ1bmRlZCBpbi1hcHAgcHVyY2hhc2VzIGZvciB5b3VyIGFwcC5cbiAgICAgKlxuICAgICAqIEBwYXJhbSBhbnlUcmFuc2FjdGlvbklkIEFueSB0cmFuc2FjdGlvbklkLCBvcmlnaW5hbFRyYW5zYWN0aW9uSWQsIG9yIGFwcFRyYW5zYWN0aW9uSWQgdGhhdCBiZWxvbmdzIHRvIHRoZSBjdXN0b21lciBmb3IgeW91ciBhcHAuXG4gICAgICogQHBhcmFtIHJldmlzaW9uICAgICAgICAgICAgICBBIHRva2VuIHlvdSBwcm92aWRlIHRvIGdldCB0aGUgbmV4dCBzZXQgb2YgdXAgdG8gMjAgdHJhbnNhY3Rpb25zLiBBbGwgcmVzcG9uc2VzIGluY2x1ZGUgYSByZXZpc2lvbiB0b2tlbi4gVXNlIHRoZSByZXZpc2lvbiB0b2tlbiBmcm9tIHRoZSBwcmV2aW91cyBSZWZ1bmRIaXN0b3J5UmVzcG9uc2UuXG4gICAgICogQHJldHVybiBBIHJlc3BvbnNlIHRoYXQgY29udGFpbnMgc3RhdHVzIGluZm9ybWF0aW9uIGZvciBhbGwgb2YgYSBjdXN0b21lcuKAmXMgYXV0by1yZW5ld2FibGUgc3Vic2NyaXB0aW9ucyBpbiB5b3VyIGFwcC5cbiAgICAgKiBAdGhyb3dzIEFQSUV4Y2VwdGlvbiBJZiBhIHJlc3BvbnNlIHdhcyByZXR1cm5lZCBpbmRpY2F0aW5nIHRoZSByZXF1ZXN0IGNvdWxkIG5vdCBiZSBwcm9jZXNzZWRcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvZ2V0X3JlZnVuZF9oaXN0b3J5IEdldCBSZWZ1bmQgSGlzdG9yeX1cbiAgICAgKi9cbiAgICBwdWJsaWMgYXN5bmMgZ2V0UmVmdW5kSGlzdG9yeShhbnlUcmFuc2FjdGlvbklkOiBzdHJpbmcsIHJldmlzaW9uOiBzdHJpbmcgfCBudWxsKTogUHJvbWlzZTxSZWZ1bmRIaXN0b3J5UmVzcG9uc2U+IHtcbiAgICAgICAgY29uc3QgcXVlcnlQYXJhbWV0ZXJzOiB7IFtrZXk6IHN0cmluZ106IFtzdHJpbmddfSA9IHt9XG4gICAgICAgIGlmIChyZXZpc2lvbiAhPT0gbnVsbCkge1xuICAgICAgICAgICAgcXVlcnlQYXJhbWV0ZXJzW1wicmV2aXNpb25cIl0gPSBbcmV2aXNpb25dO1xuICAgICAgICB9XG5cbiAgICAgICAgcmV0dXJuIGF3YWl0IHRoaXMubWFrZVJlcXVlc3QoXCIvaW5BcHBzL3YyL3JlZnVuZC9sb29rdXAvXCIgKyBhbnlUcmFuc2FjdGlvbklkLCBcIkdFVFwiLCBxdWVyeVBhcmFtZXRlcnMsIG51bGwsIG5ldyBSZWZ1bmRIaXN0b3J5UmVzcG9uc2VWYWxpZGF0b3IoKSwgdW5kZWZpbmVkKTtcbiAgICB9XG5cbiAgICAvKipcbiAgICAgKiBDaGVja3Mgd2hldGhlciBhIHJlbmV3YWwgZGF0ZSBleHRlbnNpb24gcmVxdWVzdCBjb21wbGV0ZWQsIGFuZCBwcm92aWRlcyB0aGUgZmluYWwgY291bnQgb2Ygc3VjY2Vzc2Z1bCBvciBmYWlsZWQgZXh0ZW5zaW9ucy5cbiAgICAgKlxuICAgICAqIEBwYXJhbSByZXF1ZXN0SWRlbnRpZmllciBUaGUgVVVJRCB0aGF0IHJlcHJlc2VudHMgeW91ciByZXF1ZXN0IHRvIHRoZSBFeHRlbmQgU3Vic2NyaXB0aW9uIFJlbmV3YWwgRGF0ZXMgZm9yIEFsbCBBY3RpdmUgU3Vic2NyaWJlcnMgZW5kcG9pbnQuXG4gICAgICogQHBhcmFtIHByb2R1Y3RJZCAgICAgICAgIFRoZSBwcm9kdWN0IGlkZW50aWZpZXIgb2YgdGhlIGF1dG8tcmVuZXdhYmxlIHN1YnNjcmlwdGlvbiB0aGF0IHlvdSByZXF1ZXN0IGEgcmVuZXdhbC1kYXRlIGV4dGVuc2lvbiBmb3IuXG4gICAgICogQHJldHVybiBBIHJlc3BvbnNlIHRoYXQgaW5kaWNhdGVzIHRoZSBjdXJyZW50IHN0YXR1cyBvZiBhIHJlcXVlc3QgdG8gZXh0ZW5kIHRoZSBzdWJzY3JpcHRpb24gcmVuZXdhbCBkYXRlIHRvIGFsbCBlbGlnaWJsZSBzdWJzY3JpYmVycy5cbiAgICAgKiBAdGhyb3dzIEFQSUV4Y2VwdGlvbiBJZiBhIHJlc3BvbnNlIHdhcyByZXR1cm5lZCBpbmRpY2F0aW5nIHRoZSByZXF1ZXN0IGNvdWxkIG5vdCBiZSBwcm9jZXNzZWRcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvZ2V0X3N0YXR1c19vZl9zdWJzY3JpcHRpb25fcmVuZXdhbF9kYXRlX2V4dGVuc2lvbnMgR2V0IFN0YXR1cyBvZiBTdWJzY3JpcHRpb24gUmVuZXdhbCBEYXRlIEV4dGVuc2lvbnN9XG4gICAgICovXG4gICAgcHVibGljIGFzeW5jIGdldFN0YXR1c09mU3Vic2NyaXB0aW9uUmVuZXdhbERhdGVFeHRlbnNpb25zKHJlcXVlc3RJZGVudGlmaWVyOiBzdHJpbmcsIHByb2R1Y3RJZDogc3RyaW5nKTogUHJvbWlzZTxNYXNzRXh0ZW5kUmVuZXdhbERhdGVTdGF0dXNSZXNwb25zZT4ge1xuICAgICAgICByZXR1cm4gYXdhaXQgdGhpcy5tYWtlUmVxdWVzdChcIi9pbkFwcHMvdjEvc3Vic2NyaXB0aW9ucy9leHRlbmQvbWFzcy9cIiArIHByb2R1Y3RJZCArIFwiL1wiICsgcmVxdWVzdElkZW50aWZpZXIsIFwiR0VUXCIsIHt9LCBudWxsLCBuZXcgTWFzc0V4dGVuZFJlbmV3YWxEYXRlU3RhdHVzUmVzcG9uc2VWYWxpZGF0b3IoKSwgdW5kZWZpbmVkKTtcbiAgICB9XG5cbiAgICAvKipcbiAgICAgKiBDaGVjayB0aGUgc3RhdHVzIG9mIHRoZSB0ZXN0IEFwcCBTdG9yZSBzZXJ2ZXIgbm90aWZpY2F0aW9uIHNlbnQgdG8geW91ciBzZXJ2ZXIuXG4gICAgICpcbiAgICAgKiBAcGFyYW0gdGVzdE5vdGlmaWNhdGlvblRva2VuIFRoZSB0ZXN0IG5vdGlmaWNhdGlvbiB0b2tlbiByZWNlaXZlZCBmcm9tIHRoZSBSZXF1ZXN0IGEgVGVzdCBOb3RpZmljYXRpb24gZW5kcG9pbnRcbiAgICAgKiBAcmV0dXJuIEEgcmVzcG9uc2UgdGhhdCBjb250YWlucyB0aGUgY29udGVudHMgb2YgdGhlIHRlc3Qgbm90aWZpY2F0aW9uIHNlbnQgYnkgdGhlIEFwcCBTdG9yZSBzZXJ2ZXIgYW5kIHRoZSByZXN1bHQgZnJvbSB5b3VyIHNlcnZlci5cbiAgICAgKiBAdGhyb3dzIEFQSUV4Y2VwdGlvbiBJZiBhIHJlc3BvbnNlIHdhcyByZXR1cm5lZCBpbmRpY2F0aW5nIHRoZSByZXF1ZXN0IGNvdWxkIG5vdCBiZSBwcm9jZXNzZWRcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvZ2V0X3Rlc3Rfbm90aWZpY2F0aW9uX3N0YXR1cyBHZXQgVGVzdCBOb3RpZmljYXRpb24gU3RhdHVzfVxuICAgICAqL1xuICAgIHB1YmxpYyBhc3luYyBnZXRUZXN0Tm90aWZpY2F0aW9uU3RhdHVzKHRlc3ROb3RpZmljYXRpb25Ub2tlbjogc3RyaW5nKTogUHJvbWlzZTxDaGVja1Rlc3ROb3RpZmljYXRpb25SZXNwb25zZT4ge1xuICAgICAgICByZXR1cm4gYXdhaXQgdGhpcy5tYWtlUmVxdWVzdChcIi9pbkFwcHMvdjEvbm90aWZpY2F0aW9ucy90ZXN0L1wiICsgdGVzdE5vdGlmaWNhdGlvblRva2VuLCBcIkdFVFwiLCB7fSwgbnVsbCwgbmV3IENoZWNrVGVzdE5vdGlmaWNhdGlvblJlc3BvbnNlVmFsaWRhdG9yKCksIHVuZGVmaW5lZCk7XG4gICAgfVxuXG4gICAgLyoqXG4gICAgICogR2V0IGEgbGlzdCBvZiBub3RpZmljYXRpb25zIHRoYXQgdGhlIEFwcCBTdG9yZSBzZXJ2ZXIgYXR0ZW1wdGVkIHRvIHNlbmQgdG8geW91ciBzZXJ2ZXIuXG4gICAgICpcbiAgICAgKiBAcGFyYW0gcGFnaW5hdGlvblRva2VuIEFuIG9wdGlvbmFsIHRva2VuIHlvdSB1c2UgdG8gZ2V0IHRoZSBuZXh0IHNldCBvZiB1cCB0byAyMCBub3RpZmljYXRpb24gaGlzdG9yeSByZWNvcmRzLiBBbGwgcmVzcG9uc2VzIHRoYXQgaGF2ZSBtb3JlIHJlY29yZHMgYXZhaWxhYmxlIGluY2x1ZGUgYSBwYWdpbmF0aW9uVG9rZW4uIE9taXQgdGhpcyBwYXJhbWV0ZXIgdGhlIGZpcnN0IHRpbWUgeW91IGNhbGwgdGhpcyBlbmRwb2ludC5cbiAgICAgKiBAcGFyYW0gbm90aWZpY2F0aW9uSGlzdG9yeVJlcXVlc3QgVGhlIHJlcXVlc3QgYm9keSB0aGF0IGluY2x1ZGVzIHRoZSBzdGFydCBhbmQgZW5kIGRhdGVzLCBhbmQgb3B0aW9uYWwgcXVlcnkgY29uc3RyYWludHMuXG4gICAgICogQHJldHVybiBBIHJlc3BvbnNlIHRoYXQgY29udGFpbnMgdGhlIEFwcCBTdG9yZSBTZXJ2ZXIgTm90aWZpY2F0aW9ucyBoaXN0b3J5IGZvciB5b3VyIGFwcC5cbiAgICAgKiBAdGhyb3dzIEFQSUV4Y2VwdGlvbiBJZiBhIHJlc3BvbnNlIHdhcyByZXR1cm5lZCBpbmRpY2F0aW5nIHRoZSByZXF1ZXN0IGNvdWxkIG5vdCBiZSBwcm9jZXNzZWRcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvZ2V0X25vdGlmaWNhdGlvbl9oaXN0b3J5IEdldCBOb3RpZmljYXRpb24gSGlzdG9yeX1cbiAgICAgKi9cbiAgICBwdWJsaWMgYXN5bmMgZ2V0Tm90aWZpY2F0aW9uSGlzdG9yeShwYWdpbmF0aW9uVG9rZW46IHN0cmluZyB8IG51bGwsIG5vdGlmaWNhdGlvbkhpc3RvcnlSZXF1ZXN0OiBOb3RpZmljYXRpb25IaXN0b3J5UmVxdWVzdCk6IFByb21pc2U8Tm90aWZpY2F0aW9uSGlzdG9yeVJlc3BvbnNlPiB7XG4gICAgICAgIGNvbnN0IHF1ZXJ5UGFyYW1ldGVyczogeyBba2V5OiBzdHJpbmddOiBbc3RyaW5nXX0gPSB7fVxuICAgICAgICBpZiAocGFnaW5hdGlvblRva2VuICE9IG51bGwpIHtcbiAgICAgICAgICAgIHF1ZXJ5UGFyYW1ldGVyc1tcInBhZ2luYXRpb25Ub2tlblwiXSA9IFtwYWdpbmF0aW9uVG9rZW5dO1xuICAgICAgICB9XG4gICAgICAgIHJldHVybiBhd2FpdCB0aGlzLm1ha2VSZXF1ZXN0KFwiL2luQXBwcy92MS9ub3RpZmljYXRpb25zL2hpc3RvcnlcIiwgXCJQT1NUXCIsIHF1ZXJ5UGFyYW1ldGVycywgbm90aWZpY2F0aW9uSGlzdG9yeVJlcXVlc3QsIG5ldyBOb3RpZmljYXRpb25IaXN0b3J5UmVzcG9uc2VWYWxpZGF0b3IoKSwgJ2FwcGxpY2F0aW9uL2pzb24nKTtcbiAgICB9XG5cbiAgICAvKipcbiAgICAgKiBHZXQgYSBjdXN0b21lcuKAmXMgaW4tYXBwIHB1cmNoYXNlIHRyYW5zYWN0aW9uIGhpc3RvcnkgZm9yIHlvdXIgYXBwLlxuICAgICAqXG4gICAgICogQHBhcmFtIGFueVRyYW5zYWN0aW9uSWQgQW55IHRyYW5zYWN0aW9uSWQsIG9yaWdpbmFsVHJhbnNhY3Rpb25JZCwgb3IgYXBwVHJhbnNhY3Rpb25JZCB0aGF0IGJlbG9uZ3MgdG8gdGhlIGN1c3RvbWVyIGZvciB5b3VyIGFwcC5cbiAgICAgKiBAcGFyYW0gcmV2aXNpb24gICAgICAgICAgICAgIEEgdG9rZW4geW91IHByb3ZpZGUgdG8gZ2V0IHRoZSBuZXh0IHNldCBvZiB1cCB0byAyMCB0cmFuc2FjdGlvbnMuIEFsbCByZXNwb25zZXMgaW5jbHVkZSBhIHJldmlzaW9uIHRva2VuLiBOb3RlOiBGb3IgcmVxdWVzdHMgdGhhdCB1c2UgdGhlIHJldmlzaW9uIHRva2VuLCBpbmNsdWRlIHRoZSBzYW1lIHF1ZXJ5IHBhcmFtZXRlcnMgZnJvbSB0aGUgaW5pdGlhbCByZXF1ZXN0LiBVc2UgdGhlIHJldmlzaW9uIHRva2VuIGZyb20gdGhlIHByZXZpb3VzIEhpc3RvcnlSZXNwb25zZS5cbiAgICAgKiBAcGFyYW0gdmVyc2lvbiBUaGUgdmVyc2lvbiBvZiB0aGUgR2V0IFRyYW5zYWN0aW9uIEhpc3RvcnkgZW5kcG9pbnQgdG8gdXNlLiBWMiBpcyByZWNvbW1lbmRlZC5cbiAgICAgKiBAcmV0dXJuIEEgcmVzcG9uc2UgdGhhdCBjb250YWlucyB0aGUgY3VzdG9tZXLigJlzIHRyYW5zYWN0aW9uIGhpc3RvcnkgZm9yIGFuIGFwcC5cbiAgICAgKiBAdGhyb3dzIEFQSUV4Y2VwdGlvbiBJZiBhIHJlc3BvbnNlIHdhcyByZXR1cm5lZCBpbmRpY2F0aW5nIHRoZSByZXF1ZXN0IGNvdWxkIG5vdCBiZSBwcm9jZXNzZWRcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvZ2V0X3RyYW5zYWN0aW9uX2hpc3RvcnkgR2V0IFRyYW5zYWN0aW9uIEhpc3Rvcnl9XG4gICAgICovXG4gICAgcHVibGljIGFzeW5jIGdldFRyYW5zYWN0aW9uSGlzdG9yeShhbnlUcmFuc2FjdGlvbklkOiBzdHJpbmcsIHJldmlzaW9uOiBzdHJpbmcgfCBudWxsLCB0cmFuc2FjdGlvbkhpc3RvcnlSZXF1ZXN0OiBUcmFuc2FjdGlvbkhpc3RvcnlSZXF1ZXN0LCB2ZXJzaW9uOiBHZXRUcmFuc2FjdGlvbkhpc3RvcnlWZXJzaW9uID0gR2V0VHJhbnNhY3Rpb25IaXN0b3J5VmVyc2lvbi5WMSk6IFByb21pc2U8SGlzdG9yeVJlc3BvbnNlPiB7XG4gICAgICAgIGNvbnN0IHF1ZXJ5UGFyYW1ldGVyczogeyBba2V5OiBzdHJpbmddOiBzdHJpbmdbXX0gPSB7fVxuICAgICAgICBpZiAocmV2aXNpb24gIT0gbnVsbCkge1xuICAgICAgICAgICAgcXVlcnlQYXJhbWV0ZXJzW1wicmV2aXNpb25cIl0gPSBbcmV2aXNpb25dO1xuICAgICAgICB9XG4gICAgICAgIGlmICh0cmFuc2FjdGlvbkhpc3RvcnlSZXF1ZXN0LnN0YXJ0RGF0ZSkge1xuICAgICAgICAgICAgcXVlcnlQYXJhbWV0ZXJzW1wic3RhcnREYXRlXCJdID0gW3RyYW5zYWN0aW9uSGlzdG9yeVJlcXVlc3Quc3RhcnREYXRlLnRvU3RyaW5nKCldO1xuICAgICAgICB9XG4gICAgICAgIGlmICh0cmFuc2FjdGlvbkhpc3RvcnlSZXF1ZXN0LmVuZERhdGUpIHtcbiAgICAgICAgICAgIHF1ZXJ5UGFyYW1ldGVyc1tcImVuZERhdGVcIl0gPSBbdHJhbnNhY3Rpb25IaXN0b3J5UmVxdWVzdC5lbmREYXRlLnRvU3RyaW5nKCldO1xuICAgICAgICB9XG4gICAgICAgIGlmICh0cmFuc2FjdGlvbkhpc3RvcnlSZXF1ZXN0LnByb2R1Y3RJZHMpIHtcbiAgICAgICAgICAgIHF1ZXJ5UGFyYW1ldGVyc1tcInByb2R1Y3RJZFwiXSA9IHRyYW5zYWN0aW9uSGlzdG9yeVJlcXVlc3QucHJvZHVjdElkcztcbiAgICAgICAgfVxuICAgICAgICBpZiAodHJhbnNhY3Rpb25IaXN0b3J5UmVxdWVzdC5wcm9kdWN0VHlwZXMpIHtcbiAgICAgICAgICAgIHF1ZXJ5UGFyYW1ldGVyc1tcInByb2R1Y3RUeXBlXCJdID0gdHJhbnNhY3Rpb25IaXN0b3J5UmVxdWVzdC5wcm9kdWN0VHlwZXM7XG4gICAgICAgIH1cbiAgICAgICAgaWYgKHRyYW5zYWN0aW9uSGlzdG9yeVJlcXVlc3Quc29ydCkge1xuICAgICAgICAgICAgcXVlcnlQYXJhbWV0ZXJzW1wic29ydFwiXSA9IFt0cmFuc2FjdGlvbkhpc3RvcnlSZXF1ZXN0LnNvcnRdO1xuICAgICAgICB9XG4gICAgICAgIGlmICh0cmFuc2FjdGlvbkhpc3RvcnlSZXF1ZXN0LnN1YnNjcmlwdGlvbkdyb3VwSWRlbnRpZmllcnMpIHtcbiAgICAgICAgICAgIHF1ZXJ5UGFyYW1ldGVyc1tcInN1YnNjcmlwdGlvbkdyb3VwSWRlbnRpZmllclwiXSA9IHRyYW5zYWN0aW9uSGlzdG9yeVJlcXVlc3Quc3Vic2NyaXB0aW9uR3JvdXBJZGVudGlmaWVycztcbiAgICAgICAgfVxuICAgICAgICBpZiAodHJhbnNhY3Rpb25IaXN0b3J5UmVxdWVzdC5pbkFwcE93bmVyc2hpcFR5cGUpIHtcbiAgICAgICAgICAgIHF1ZXJ5UGFyYW1ldGVyc1tcImluQXBwT3duZXJzaGlwVHlwZVwiXSA9IFt0cmFuc2FjdGlvbkhpc3RvcnlSZXF1ZXN0LmluQXBwT3duZXJzaGlwVHlwZV07XG4gICAgICAgIH1cbiAgICAgICAgaWYgKHRyYW5zYWN0aW9uSGlzdG9yeVJlcXVlc3QucmV2b2tlZCAhPT0gdW5kZWZpbmVkKSB7XG4gICAgICAgICAgICBxdWVyeVBhcmFtZXRlcnNbXCJyZXZva2VkXCJdID0gW3RyYW5zYWN0aW9uSGlzdG9yeVJlcXVlc3QucmV2b2tlZC50b1N0cmluZygpXTtcbiAgICAgICAgfVxuICAgICAgICByZXR1cm4gYXdhaXQgdGhpcy5tYWtlUmVxdWVzdChcIi9pbkFwcHMvXCIgKyB2ZXJzaW9uICsgXCIvaGlzdG9yeS9cIiArIGFueVRyYW5zYWN0aW9uSWQsIFwiR0VUXCIsIHF1ZXJ5UGFyYW1ldGVycywgbnVsbCwgbmV3IEhpc3RvcnlSZXNwb25zZVZhbGlkYXRvcigpLCB1bmRlZmluZWQpO1xuICAgIH1cblxuICAgIC8qKlxuICAgICAqIEdldCBpbmZvcm1hdGlvbiBhYm91dCBhIHNpbmdsZSB0cmFuc2FjdGlvbiBmb3IgeW91ciBhcHAuXG4gICAgICpcbiAgICAgKiBAcGFyYW0gdHJhbnNhY3Rpb25JZCBUaGUgaWRlbnRpZmllciBvZiBhIHRyYW5zYWN0aW9uIHRoYXQgYmVsb25ncyB0byB0aGUgY3VzdG9tZXIsIGFuZCB3aGljaCBtYXkgYmUgYW4gb3JpZ2luYWwgdHJhbnNhY3Rpb24gaWRlbnRpZmllci5cbiAgICAgKiBAcmV0dXJuIEEgcmVzcG9uc2UgdGhhdCBjb250YWlucyBzaWduZWQgdHJhbnNhY3Rpb24gaW5mb3JtYXRpb24gZm9yIGEgc2luZ2xlIHRyYW5zYWN0aW9uLlxuICAgICAqIEB0aHJvd3MgQVBJRXhjZXB0aW9uIElmIGEgcmVzcG9uc2Ugd2FzIHJldHVybmVkIGluZGljYXRpbmcgdGhlIHJlcXVlc3QgY291bGQgbm90IGJlIHByb2Nlc3NlZFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9nZXRfdHJhbnNhY3Rpb25faW5mbyBHZXQgVHJhbnNhY3Rpb24gSW5mb31cbiAgICAgKi9cbiAgICBwdWJsaWMgYXN5bmMgZ2V0VHJhbnNhY3Rpb25JbmZvKHRyYW5zYWN0aW9uSWQ6IHN0cmluZyk6IFByb21pc2U8VHJhbnNhY3Rpb25JbmZvUmVzcG9uc2U+IHtcbiAgICAgICAgcmV0dXJuIGF3YWl0IHRoaXMubWFrZVJlcXVlc3QoXCIvaW5BcHBzL3YxL3RyYW5zYWN0aW9ucy9cIiArIHRyYW5zYWN0aW9uSWQsIFwiR0VUXCIsIHt9LCBudWxsLCBuZXcgVHJhbnNhY3Rpb25JbmZvUmVzcG9uc2VWYWxpZGF0b3IoKSwgdW5kZWZpbmVkKTtcbiAgICB9XG5cbiAgICAvKipcbiAgICAgKiBHZXQgYSBjdXN0b21lcuKAmXMgaW4tYXBwIHB1cmNoYXNlcyBmcm9tIGEgcmVjZWlwdCB1c2luZyB0aGUgb3JkZXIgSUQuXG4gICAgICpcbiAgICAgKiBAcGFyYW0gb3JkZXJJZCBUaGUgb3JkZXIgSUQgZm9yIGluLWFwcCBwdXJjaGFzZXMgdGhhdCBiZWxvbmcgdG8gdGhlIGN1c3RvbWVyLlxuICAgICAqIEByZXR1cm4gQSByZXNwb25zZSB0aGF0IGluY2x1ZGVzIHRoZSBvcmRlciBsb29rdXAgc3RhdHVzIGFuZCBhbiBhcnJheSBvZiBzaWduZWQgdHJhbnNhY3Rpb25zIGZvciB0aGUgaW4tYXBwIHB1cmNoYXNlcyBpbiB0aGUgb3JkZXIuXG4gICAgICogQHRocm93cyBBUElFeGNlcHRpb24gSWYgYSByZXNwb25zZSB3YXMgcmV0dXJuZWQgaW5kaWNhdGluZyB0aGUgcmVxdWVzdCBjb3VsZCBub3QgYmUgcHJvY2Vzc2VkXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2xvb2tfdXBfb3JkZXJfaWQgTG9vayBVcCBPcmRlciBJRH1cbiAgICAgKi9cbiAgICBwdWJsaWMgYXN5bmMgbG9va1VwT3JkZXJJZChvcmRlcklkOiBzdHJpbmcpOiBQcm9taXNlPE9yZGVyTG9va3VwUmVzcG9uc2U+IHtcbiAgICAgICAgcmV0dXJuIGF3YWl0IHRoaXMubWFrZVJlcXVlc3QoXCIvaW5BcHBzL3YxL2xvb2t1cC9cIiArIG9yZGVySWQsIFwiR0VUXCIsIHt9LCBudWxsLCBuZXcgT3JkZXJMb29rdXBSZXNwb25zZVZhbGlkYXRvcigpLCB1bmRlZmluZWQpO1xuICAgIH1cblxuICAgIC8qKlxuICAgICAqIEFzayBBcHAgU3RvcmUgU2VydmVyIE5vdGlmaWNhdGlvbnMgdG8gc2VuZCBhIHRlc3Qgbm90aWZpY2F0aW9uIHRvIHlvdXIgc2VydmVyLlxuICAgICAqXG4gICAgICogQHJldHVybiBBIHJlc3BvbnNlIHRoYXQgY29udGFpbnMgdGhlIHRlc3Qgbm90aWZpY2F0aW9uIHRva2VuLlxuICAgICAqIEB0aHJvd3MgQVBJRXhjZXB0aW9uIElmIGEgcmVzcG9uc2Ugd2FzIHJldHVybmVkIGluZGljYXRpbmcgdGhlIHJlcXVlc3QgY291bGQgbm90IGJlIHByb2Nlc3NlZFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9yZXF1ZXN0X2FfdGVzdF9ub3RpZmljYXRpb24gUmVxdWVzdCBhIFRlc3QgTm90aWZpY2F0aW9ufVxuICAgICAqL1xuICAgIHB1YmxpYyBhc3luYyByZXF1ZXN0VGVzdE5vdGlmaWNhdGlvbigpOiBQcm9taXNlPFNlbmRUZXN0Tm90aWZpY2F0aW9uUmVzcG9uc2U+IHtcbiAgICAgICAgcmV0dXJuIGF3YWl0IHRoaXMubWFrZVJlcXVlc3QoXCIvaW5BcHBzL3YxL25vdGlmaWNhdGlvbnMvdGVzdFwiLCBcIlBPU1RcIiwge30sIG51bGwsIG5ldyBTZW5kVGVzdE5vdGlmaWNhdGlvblJlc3BvbnNlVmFsaWRhdG9yKCksIHVuZGVmaW5lZCk7XG4gICAgfVxuXG4gICAgLyoqXG4gICAgICogU2VuZCBjb25zdW1wdGlvbiBpbmZvcm1hdGlvbiBhYm91dCBhIGNvbnN1bWFibGUgaW4tYXBwIHB1cmNoYXNlIHRvIHRoZSBBcHAgU3RvcmUgYWZ0ZXIgeW91ciBzZXJ2ZXIgcmVjZWl2ZXMgYSBjb25zdW1wdGlvbiByZXF1ZXN0IG5vdGlmaWNhdGlvbi5cbiAgICAgKlxuICAgICAqIEBwYXJhbSB0cmFuc2FjdGlvbklkIFRoZSB0cmFuc2FjdGlvbiBpZGVudGlmaWVyIGZvciB3aGljaCB5b3UncmUgcHJvdmlkaW5nIGNvbnN1bXB0aW9uIGluZm9ybWF0aW9uLiBZb3UgcmVjZWl2ZSB0aGlzIGlkZW50aWZpZXIgaW4gdGhlIENPTlNVTVBUSU9OX1JFUVVFU1Qgbm90aWZpY2F0aW9uIHRoZSBBcHAgU3RvcmUgc2VuZHMgdG8geW91ciBzZXJ2ZXIuXG4gICAgICogQHBhcmFtIGNvbnN1bXB0aW9uUmVxdWVzdCAgICBUaGUgcmVxdWVzdCBib2R5IGNvbnRhaW5pbmcgY29uc3VtcHRpb24gaW5mb3JtYXRpb24uXG4gICAgICogQHRocm93cyBBUElFeGNlcHRpb24gSWYgYSByZXNwb25zZSB3YXMgcmV0dXJuZWQgaW5kaWNhdGluZyB0aGUgcmVxdWVzdCBjb3VsZCBub3QgYmUgcHJvY2Vzc2VkXG4gICAgICogQGRlcHJlY2F0ZWQgVXNlIHtAbGluayBzZW5kQ29uc3VtcHRpb25JbmZvcm1hdGlvbn0gaW5zdGVhZFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9zZW5kLWNvbnN1bXB0aW9uLWluZm9ybWF0aW9uLXYxIFNlbmQgQ29uc3VtcHRpb24gSW5mb3JtYXRpb259XG4gICAgICovXG4gICAgcHVibGljIGFzeW5jIHNlbmRDb25zdW1wdGlvbkRhdGEodHJhbnNhY3Rpb25JZDogc3RyaW5nLCBjb25zdW1wdGlvblJlcXVlc3Q6IENvbnN1bXB0aW9uUmVxdWVzdFYxKTogUHJvbWlzZTx2b2lkPiB7XG4gICAgICAgIGF3YWl0IHRoaXMubWFrZVJlcXVlc3QoXCIvaW5BcHBzL3YxL3RyYW5zYWN0aW9ucy9jb25zdW1wdGlvbi9cIiArIHRyYW5zYWN0aW9uSWQsIFwiUFVUXCIsIHt9LCBjb25zdW1wdGlvblJlcXVlc3QsIG51bGwsICdhcHBsaWNhdGlvbi9qc29uJyk7XG4gICAgfVxuXG4gICAgLyoqXG4gICAgICogU2VuZCBjb25zdW1wdGlvbiBpbmZvcm1hdGlvbiBhYm91dCBhbiBJbi1BcHAgUHVyY2hhc2UgdG8gdGhlIEFwcCBTdG9yZSBhZnRlciB5b3VyIHNlcnZlciByZWNlaXZlcyBhIGNvbnN1bXB0aW9uIHJlcXVlc3Qgbm90aWZpY2F0aW9uLlxuICAgICAqXG4gICAgICogQHBhcmFtIHRyYW5zYWN0aW9uSWQgVGhlIHRyYW5zYWN0aW9uIGlkZW50aWZpZXIgZm9yIHdoaWNoIHlvdSdyZSBwcm92aWRpbmcgY29uc3VtcHRpb24gaW5mb3JtYXRpb24uIFlvdSByZWNlaXZlIHRoaXMgaWRlbnRpZmllciBpbiB0aGUgQ09OU1VNUFRJT05fUkVRVUVTVCBub3RpZmljYXRpb24gdGhlIEFwcCBTdG9yZSBzZW5kcyB0byB5b3VyIHNlcnZlcidzIEFwcCBTdG9yZSBTZXJ2ZXIgTm90aWZpY2F0aW9ucyBWMiBlbmRwb2ludC5cbiAgICAgKiBAcGFyYW0gY29uc3VtcHRpb25SZXF1ZXN0IFRoZSByZXF1ZXN0IGJvZHkgY29udGFpbmluZyBjb25zdW1wdGlvbiBpbmZvcm1hdGlvbi5cbiAgICAgKiBAdGhyb3dzIEFQSUV4Y2VwdGlvbiBJZiBhIHJlc3BvbnNlIHdhcyByZXR1cm5lZCBpbmRpY2F0aW5nIHRoZSByZXF1ZXN0IGNvdWxkIG5vdCBiZSBwcm9jZXNzZWRcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvc2VuZC1jb25zdW1wdGlvbi1pbmZvcm1hdGlvbiBTZW5kIENvbnN1bXB0aW9uIEluZm9ybWF0aW9ufVxuICAgICAqL1xuICAgIHB1YmxpYyBhc3luYyBzZW5kQ29uc3VtcHRpb25JbmZvcm1hdGlvbih0cmFuc2FjdGlvbklkOiBzdHJpbmcsIGNvbnN1bXB0aW9uUmVxdWVzdDogQ29uc3VtcHRpb25SZXF1ZXN0KTogUHJvbWlzZTx2b2lkPiB7XG4gICAgICAgIGF3YWl0IHRoaXMubWFrZVJlcXVlc3QoXCIvaW5BcHBzL3YyL3RyYW5zYWN0aW9ucy9jb25zdW1wdGlvbi9cIiArIHRyYW5zYWN0aW9uSWQsIFwiUFVUXCIsIHt9LCBjb25zdW1wdGlvblJlcXVlc3QsIG51bGwsICdhcHBsaWNhdGlvbi9qc29uJyk7XG4gICAgfVxuXG4gICAgLyoqXG4gICAgICogU2V0cyB0aGUgYXBwIGFjY291bnQgdG9rZW4gdmFsdWUgZm9yIGEgcHVyY2hhc2UgdGhlIGN1c3RvbWVyIG1ha2VzIG91dHNpZGUgeW91ciBhcHAsIG9yIHVwZGF0ZXMgaXRzIHZhbHVlIGluIGFuIGV4aXN0aW5nIHRyYW5zYWN0aW9uLlxuICAgICAqXG4gICAgICogQHBhcmFtIG9yaWdpbmFsVHJhbnNhY3Rpb25JZCBUaGUgb3JpZ2luYWwgdHJhbnNhY3Rpb24gaWRlbnRpZmllciBvZiB0aGUgdHJhbnNhY3Rpb24gdG8gcmVjZWl2ZSB0aGUgYXBwIGFjY291bnQgdG9rZW4gdXBkYXRlLlxuICAgICAqIEBwYXJhbSB1cGRhdGVBcHBBY2NvdW50VG9rZW5SZXF1ZXN0IFRoZSByZXF1ZXN0IGJvZHkgdGhhdCBjb250YWlucyBhIHZhbGlkIGFwcCBhY2NvdW50IHRva2VuIHZhbHVlLlxuICAgICAqIEB0aHJvd3MgQVBJRXhjZXB0aW9uIElmIGEgcmVzcG9uc2Ugd2FzIHJldHVybmVkIGluZGljYXRpbmcgdGhlIHJlcXVlc3QgY291bGQgbm90IGJlIHByb2Nlc3NlZC5cbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvc2V0LWFwcC1hY2NvdW50LXRva2VuIFNldCBBcHAgQWNjb3VudCBUb2tlbn1cbiAgICAgKi9cbiAgICBwdWJsaWMgYXN5bmMgc2V0QXBwQWNjb3VudFRva2VuKG9yaWdpbmFsVHJhbnNhY3Rpb25JZDogc3RyaW5nLCB1cGRhdGVBcHBBY2NvdW50VG9rZW5SZXF1ZXN0OiBVcGRhdGVBcHBBY2NvdW50VG9rZW5SZXF1ZXN0KTogUHJvbWlzZTx2b2lkPiB7XG4gICAgICAgIGF3YWl0IHRoaXMubWFrZVJlcXVlc3QoXCIvaW5BcHBzL3YxL3RyYW5zYWN0aW9ucy9cIiArIG9yaWdpbmFsVHJhbnNhY3Rpb25JZCArIFwiL2FwcEFjY291bnRUb2tlblwiLCBcIlBVVFwiLCB7fSwgdXBkYXRlQXBwQWNjb3VudFRva2VuUmVxdWVzdCwgbnVsbCwgJ2FwcGxpY2F0aW9uL2pzb24nKTtcbiAgICB9XG5cbiAgICAvKipcbiAgICAgKiBVcGxvYWQgYW4gaW1hZ2UgdG8gdXNlIGZvciByZXRlbnRpb24gbWVzc2FnaW5nLlxuICAgICAqXG4gICAgICogQHBhcmFtIGltYWdlSWRlbnRpZmllciBBIFVVSUQgeW91IHByb3ZpZGUgdG8gdW5pcXVlbHkgaWRlbnRpZnkgdGhlIGltYWdlIHlvdSB1cGxvYWQuIE11c3QgYmUgbG93ZXJjYXNlLlxuICAgICAqIEBwYXJhbSBpbWFnZSBUaGUgaW1hZ2UgZmlsZSB0byB1cGxvYWQuXG4gICAgICogQHBhcmFtIGltYWdlU2l6ZSBUaGUgc2l6ZSBvZiB0aGUgaW1hZ2UgeW91IHVwbG9hZC5cbiAgICAgKiBAdGhyb3dzIEFQSUV4Y2VwdGlvbiBJZiBhIHJlc3BvbnNlIHdhcyByZXR1cm5lZCBpbmRpY2F0aW5nIHRoZSByZXF1ZXN0IGNvdWxkIG5vdCBiZSBwcm9jZXNzZWRcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL3VwbG9hZC1pbWFnZSBVcGxvYWQgSW1hZ2V9XG4gICAgICovXG4gICAgcHVibGljIGFzeW5jIHVwbG9hZEltYWdlKGltYWdlSWRlbnRpZmllcjogc3RyaW5nLCBpbWFnZTogQnVmZmVyLCBpbWFnZVNpemU/OiBzdHJpbmcpOiBQcm9taXNlPHZvaWQ+IHtcbiAgICAgICAgY29uc3QgcXVlcnlQYXJhbWV0ZXJzOiB7IFtrZXk6IHN0cmluZ106IHN0cmluZ1tdfSA9IHt9XG4gICAgICAgIGlmIChpbWFnZVNpemUgIT0gbnVsbCkge1xuICAgICAgICAgICAgcXVlcnlQYXJhbWV0ZXJzW1wiaW1hZ2VTaXplXCJdID0gW2ltYWdlU2l6ZV1cbiAgICAgICAgfVxuICAgICAgICBhd2FpdCB0aGlzLm1ha2VSZXF1ZXN0KFwiL2luQXBwcy92MS9tZXNzYWdpbmcvaW1hZ2UvXCIgKyBpbWFnZUlkZW50aWZpZXIsIFwiUFVUXCIsIHF1ZXJ5UGFyYW1ldGVycywgaW1hZ2UsIG51bGwsICdpbWFnZS9wbmcnKTtcbiAgICB9XG5cbiAgICAvKipcbiAgICAgKiBEZWxldGUgYSBwcmV2aW91c2x5IHVwbG9hZGVkIGltYWdlLlxuICAgICAqXG4gICAgICogQHBhcmFtIGltYWdlSWRlbnRpZmllciBUaGUgaWRlbnRpZmllciBvZiB0aGUgaW1hZ2UgdG8gZGVsZXRlLlxuICAgICAqIEB0aHJvd3MgQVBJRXhjZXB0aW9uIElmIGEgcmVzcG9uc2Ugd2FzIHJldHVybmVkIGluZGljYXRpbmcgdGhlIHJlcXVlc3QgY291bGQgbm90IGJlIHByb2Nlc3NlZFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9yZXRlbnRpb25tZXNzYWdpbmcvZGVsZXRlLWltYWdlIERlbGV0ZSBJbWFnZX1cbiAgICAgKi9cbiAgICBwdWJsaWMgYXN5bmMgZGVsZXRlSW1hZ2UoaW1hZ2VJZGVudGlmaWVyOiBzdHJpbmcpOiBQcm9taXNlPHZvaWQ+IHtcbiAgICAgICAgYXdhaXQgdGhpcy5tYWtlUmVxdWVzdChcIi9pbkFwcHMvdjEvbWVzc2FnaW5nL2ltYWdlL1wiICsgaW1hZ2VJZGVudGlmaWVyLCBcIkRFTEVURVwiLCB7fSwgbnVsbCwgbnVsbCwgdW5kZWZpbmVkKTtcbiAgICB9XG5cbiAgICAvKipcbiAgICAgKiBHZXQgdGhlIGltYWdlIGlkZW50aWZpZXIgYW5kIHN0YXRlIGZvciBhbGwgdXBsb2FkZWQgaW1hZ2VzLlxuICAgICAqXG4gICAgICogQHJldHVybiBBIHJlc3BvbnNlIHRoYXQgY29udGFpbnMgc3RhdHVzIGluZm9ybWF0aW9uIGZvciBhbGwgaW1hZ2VzLlxuICAgICAqIEB0aHJvd3MgQVBJRXhjZXB0aW9uIElmIGEgcmVzcG9uc2Ugd2FzIHJldHVybmVkIGluZGljYXRpbmcgdGhlIHJlcXVlc3QgY291bGQgbm90IGJlIHByb2Nlc3NlZFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9yZXRlbnRpb25tZXNzYWdpbmcvZ2V0LWltYWdlLWxpc3QgR2V0IEltYWdlIExpc3R9XG4gICAgICovXG4gICAgcHVibGljIGFzeW5jIGdldEltYWdlTGlzdCgpOiBQcm9taXNlPEdldEltYWdlTGlzdFJlc3BvbnNlPiB7XG4gICAgICAgIHJldHVybiBhd2FpdCB0aGlzLm1ha2VSZXF1ZXN0KFwiL2luQXBwcy92MS9tZXNzYWdpbmcvaW1hZ2UvbGlzdFwiLCBcIkdFVFwiLCB7fSwgbnVsbCwgbmV3IEdldEltYWdlTGlzdFJlc3BvbnNlVmFsaWRhdG9yKCksIHVuZGVmaW5lZCk7XG4gICAgfVxuXG4gICAgLyoqXG4gICAgICogVXBsb2FkIGEgbWVzc2FnZSB0byB1c2UgZm9yIHJldGVudGlvbiBtZXNzYWdpbmcuXG4gICAgICpcbiAgICAgKiBAcGFyYW0gbWVzc2FnZUlkZW50aWZpZXIgQSBVVUlEIHlvdSBwcm92aWRlIHRvIHVuaXF1ZWx5IGlkZW50aWZ5IHRoZSBtZXNzYWdlIHlvdSB1cGxvYWQuIE11c3QgYmUgbG93ZXJjYXNlLlxuICAgICAqIEBwYXJhbSB1cGxvYWRNZXNzYWdlUmVxdWVzdEJvZHkgVGhlIG1lc3NhZ2UgdGV4dCB0byB1cGxvYWQuXG4gICAgICogQHRocm93cyBBUElFeGNlcHRpb24gSWYgYSByZXNwb25zZSB3YXMgcmV0dXJuZWQgaW5kaWNhdGluZyB0aGUgcmVxdWVzdCBjb3VsZCBub3QgYmUgcHJvY2Vzc2VkXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL3JldGVudGlvbm1lc3NhZ2luZy91cGxvYWQtbWVzc2FnZSBVcGxvYWQgTWVzc2FnZX1cbiAgICAgKi9cbiAgICBwdWJsaWMgYXN5bmMgdXBsb2FkTWVzc2FnZShtZXNzYWdlSWRlbnRpZmllcjogc3RyaW5nLCB1cGxvYWRNZXNzYWdlUmVxdWVzdEJvZHk6IFVwbG9hZE1lc3NhZ2VSZXF1ZXN0Qm9keSk6IFByb21pc2U8dm9pZD4ge1xuICAgICAgICBhd2FpdCB0aGlzLm1ha2VSZXF1ZXN0KFwiL2luQXBwcy92MS9tZXNzYWdpbmcvbWVzc2FnZS9cIiArIG1lc3NhZ2VJZGVudGlmaWVyLCBcIlBVVFwiLCB7fSwgdXBsb2FkTWVzc2FnZVJlcXVlc3RCb2R5LCBudWxsLCAnYXBwbGljYXRpb24vanNvbicpO1xuICAgIH1cblxuICAgIC8qKlxuICAgICAqIERlbGV0ZSBhIHByZXZpb3VzbHkgdXBsb2FkZWQgbWVzc2FnZS5cbiAgICAgKlxuICAgICAqIEBwYXJhbSBtZXNzYWdlSWRlbnRpZmllciBUaGUgaWRlbnRpZmllciBvZiB0aGUgbWVzc2FnZSB0byBkZWxldGUuXG4gICAgICogQHRocm93cyBBUElFeGNlcHRpb24gSWYgYSByZXNwb25zZSB3YXMgcmV0dXJuZWQgaW5kaWNhdGluZyB0aGUgcmVxdWVzdCBjb3VsZCBub3QgYmUgcHJvY2Vzc2VkXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL3JldGVudGlvbm1lc3NhZ2luZy9kZWxldGUtbWVzc2FnZSBEZWxldGUgTWVzc2FnZX1cbiAgICAgKi9cbiAgICBwdWJsaWMgYXN5bmMgZGVsZXRlTWVzc2FnZShtZXNzYWdlSWRlbnRpZmllcjogc3RyaW5nKTogUHJvbWlzZTx2b2lkPiB7XG4gICAgICAgIGF3YWl0IHRoaXMubWFrZVJlcXVlc3QoXCIvaW5BcHBzL3YxL21lc3NhZ2luZy9tZXNzYWdlL1wiICsgbWVzc2FnZUlkZW50aWZpZXIsIFwiREVMRVRFXCIsIHt9LCBudWxsLCBudWxsLCB1bmRlZmluZWQpO1xuICAgIH1cblxuICAgIC8qKlxuICAgICAqIEdldCB0aGUgbWVzc2FnZSBpZGVudGlmaWVyIGFuZCBzdGF0ZSBvZiBhbGwgdXBsb2FkZWQgbWVzc2FnZXMuXG4gICAgICpcbiAgICAgKiBAcmV0dXJuIEEgcmVzcG9uc2UgdGhhdCBjb250YWlucyBzdGF0dXMgaW5mb3JtYXRpb24gZm9yIGFsbCBtZXNzYWdlcy5cbiAgICAgKiBAdGhyb3dzIEFQSUV4Y2VwdGlvbiBJZiBhIHJlc3BvbnNlIHdhcyByZXR1cm5lZCBpbmRpY2F0aW5nIHRoZSByZXF1ZXN0IGNvdWxkIG5vdCBiZSBwcm9jZXNzZWRcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL2dldC1tZXNzYWdlLWxpc3QgR2V0IE1lc3NhZ2UgTGlzdH1cbiAgICAgKi9cbiAgICBwdWJsaWMgYXN5bmMgZ2V0TWVzc2FnZUxpc3QoKTogUHJvbWlzZTxHZXRNZXNzYWdlTGlzdFJlc3BvbnNlPiB7XG4gICAgICAgIHJldHVybiBhd2FpdCB0aGlzLm1ha2VSZXF1ZXN0KFwiL2luQXBwcy92MS9tZXNzYWdpbmcvbWVzc2FnZS9saXN0XCIsIFwiR0VUXCIsIHt9LCBudWxsLCBuZXcgR2V0TWVzc2FnZUxpc3RSZXNwb25zZVZhbGlkYXRvcigpLCB1bmRlZmluZWQpO1xuICAgIH1cblxuICAgIC8qKlxuICAgICAqIENvbmZpZ3VyZSBhIGRlZmF1bHQgbWVzc2FnZSBmb3IgYSBzcGVjaWZpYyBwcm9kdWN0IGluIGEgc3BlY2lmaWMgbG9jYWxlLlxuICAgICAqXG4gICAgICogQHBhcmFtIHByb2R1Y3RJZCBUaGUgcHJvZHVjdCBpZGVudGlmaWVyIGZvciB0aGUgZGVmYXVsdCBjb25maWd1cmF0aW9uLlxuICAgICAqIEBwYXJhbSBsb2NhbGUgVGhlIGxvY2FsZSBmb3IgdGhlIGRlZmF1bHQgY29uZmlndXJhdGlvbi5cbiAgICAgKiBAcGFyYW0gZGVmYXVsdENvbmZpZ3VyYXRpb25SZXF1ZXN0IFRoZSByZXF1ZXN0IGJvZHkgdGhhdCBpbmNsdWRlcyB0aGUgbWVzc2FnZSBpZGVudGlmaWVyIHRvIGNvbmZpZ3VyZSBhcyB0aGUgZGVmYXVsdCBtZXNzYWdlLlxuICAgICAqIEB0aHJvd3MgQVBJRXhjZXB0aW9uIElmIGEgcmVzcG9uc2Ugd2FzIHJldHVybmVkIGluZGljYXRpbmcgdGhlIHJlcXVlc3QgY291bGQgbm90IGJlIHByb2Nlc3NlZFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9yZXRlbnRpb25tZXNzYWdpbmcvY29uZmlndXJlLWRlZmF1bHQtbWVzc2FnZSBDb25maWd1cmUgRGVmYXVsdCBNZXNzYWdlfVxuICAgICAqL1xuICAgIHB1YmxpYyBhc3luYyBjb25maWd1cmVEZWZhdWx0TWVzc2FnZShwcm9kdWN0SWQ6IHN0cmluZywgbG9jYWxlOiBzdHJpbmcsIGRlZmF1bHRDb25maWd1cmF0aW9uUmVxdWVzdDogRGVmYXVsdENvbmZpZ3VyYXRpb25SZXF1ZXN0KTogUHJvbWlzZTx2b2lkPiB7XG4gICAgICAgIGF3YWl0IHRoaXMubWFrZVJlcXVlc3QoXCIvaW5BcHBzL3YxL21lc3NhZ2luZy9kZWZhdWx0L1wiICsgcHJvZHVjdElkICsgXCIvXCIgKyBsb2NhbGUsIFwiUFVUXCIsIHt9LCBkZWZhdWx0Q29uZmlndXJhdGlvblJlcXVlc3QsIG51bGwsICdhcHBsaWNhdGlvbi9qc29uJyk7XG4gICAgfVxuXG4gICAgLyoqXG4gICAgICogRGVsZXRlIGEgZGVmYXVsdCBtZXNzYWdlIGZvciBhIHByb2R1Y3QgaW4gYSBsb2NhbGUuXG4gICAgICpcbiAgICAgKiBAcGFyYW0gcHJvZHVjdElkIFRoZSBwcm9kdWN0IElEIG9mIHRoZSBkZWZhdWx0IG1lc3NhZ2UgY29uZmlndXJhdGlvbi5cbiAgICAgKiBAcGFyYW0gbG9jYWxlIFRoZSBsb2NhbGUgb2YgdGhlIGRlZmF1bHQgbWVzc2FnZSBjb25maWd1cmF0aW9uLlxuICAgICAqIEB0aHJvd3MgQVBJRXhjZXB0aW9uIElmIGEgcmVzcG9uc2Ugd2FzIHJldHVybmVkIGluZGljYXRpbmcgdGhlIHJlcXVlc3QgY291bGQgbm90IGJlIHByb2Nlc3NlZFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9yZXRlbnRpb25tZXNzYWdpbmcvZGVsZXRlLWRlZmF1bHQtbWVzc2FnZSBEZWxldGUgRGVmYXVsdCBNZXNzYWdlfVxuICAgICAqL1xuICAgIHB1YmxpYyBhc3luYyBkZWxldGVEZWZhdWx0TWVzc2FnZShwcm9kdWN0SWQ6IHN0cmluZywgbG9jYWxlOiBzdHJpbmcpOiBQcm9taXNlPHZvaWQ+IHtcbiAgICAgICAgYXdhaXQgdGhpcy5tYWtlUmVxdWVzdChcIi9pbkFwcHMvdjEvbWVzc2FnaW5nL2RlZmF1bHQvXCIgKyBwcm9kdWN0SWQgKyBcIi9cIiArIGxvY2FsZSwgXCJERUxFVEVcIiwge30sIG51bGwsIG51bGwsIHVuZGVmaW5lZCk7XG4gICAgfVxuXG4gICAgLyoqXG4gICAgICogR2V0cyB0aGUgZGVmYXVsdCBtZXNzYWdlIGZvciBhIHNwZWNpZmljIHByb2R1Y3QgaW4gYSBzcGVjaWZpYyBsb2NhbGUsIGlmIGl04oCZcyBjb25maWd1cmVkLlxuICAgICAqXG4gICAgICogQHBhcmFtIHByb2R1Y3RJZCBUaGUgcHJvZHVjdCBpZGVudGlmaWVyIG9mIHRoZSBtZXNzYWdlLlxuICAgICAqIEBwYXJhbSBsb2NhbGUgVGhlIGxvY2FsZSBvZiB0aGUgbWVzc2FnZS5cbiAgICAgKiBAcmV0dXJuIFRoZSByZXNwb25zZSBib2R5IHRoYXQgY29udGFpbnMgdGhlIGRlZmF1bHQgY29uZmlndXJhdGlvbiBpbmZvcm1hdGlvbi5cbiAgICAgKiBAdGhyb3dzIEFQSUV4Y2VwdGlvbiBJZiBhIHJlc3BvbnNlIHdhcyByZXR1cm5lZCBpbmRpY2F0aW5nIHRoZSByZXF1ZXN0IGNvdWxkIG5vdCBiZSBwcm9jZXNzZWRcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL2dldC1kZWZhdWx0LW1lc3NhZ2UgR2V0IERlZmF1bHQgTWVzc2FnZX1cbiAgICAgKi9cbiAgICBwdWJsaWMgYXN5bmMgZ2V0RGVmYXVsdE1lc3NhZ2UocHJvZHVjdElkOiBzdHJpbmcsIGxvY2FsZTogc3RyaW5nKTogUHJvbWlzZTxEZWZhdWx0Q29uZmlndXJhdGlvblJlc3BvbnNlPiB7XG4gICAgICAgIHJldHVybiBhd2FpdCB0aGlzLm1ha2VSZXF1ZXN0KFwiL2luQXBwcy92MS9tZXNzYWdpbmcvZGVmYXVsdC9cIiArIHByb2R1Y3RJZCArIFwiL1wiICsgbG9jYWxlLCBcIkdFVFwiLCB7fSwgbnVsbCwgbmV3IERlZmF1bHRDb25maWd1cmF0aW9uUmVzcG9uc2VWYWxpZGF0b3IoKSwgdW5kZWZpbmVkKTtcbiAgICB9XG5cbiAgICAvKipcbiAgICAgKiBDb25maWd1cmVzIHRoZSBVUkwgZm9yIHlvdXIgR2V0IFJldGVudGlvbiBNZXNzYWdlIGVuZHBvaW50IGluIHRoZSBzYW5kYm94IGFuZCBwcm9kdWN0aW9uIGVudmlyb25tZW50cy5cbiAgICAgKlxuICAgICAqIEBwYXJhbSByZWFsdGltZVVybFJlcXVlc3QgVGhlIHJlcXVlc3QgYm9keSB0aGF0IGluY2x1ZGVzIHlvdXIgZW5kcG9pbnTigJlzIFVSTC5cbiAgICAgKiBAdGhyb3dzIEFQSUV4Y2VwdGlvbiBJZiBhIHJlc3BvbnNlIHdhcyByZXR1cm5lZCBpbmRpY2F0aW5nIHRoZSByZXF1ZXN0IGNvdWxkIG5vdCBiZSBwcm9jZXNzZWRcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL2NvbmZpZ3VyZS1yZWFsdGltZS11cmwgQ29uZmlndXJlIFJlYWx0aW1lIFVSTH1cbiAgICAgKi9cbiAgICBwdWJsaWMgYXN5bmMgY29uZmlndXJlUmVhbHRpbWVVUkwocmVhbHRpbWVVcmxSZXF1ZXN0OiBSZWFsdGltZVVybFJlcXVlc3QpOiBQcm9taXNlPHZvaWQ+IHtcbiAgICAgICAgYXdhaXQgdGhpcy5tYWtlUmVxdWVzdChcIi9pbkFwcHMvdjEvbWVzc2FnaW5nL3JlYWx0aW1lL3VybFwiLCBcIlBVVFwiLCB7fSwgcmVhbHRpbWVVcmxSZXF1ZXN0LCBudWxsLCAnYXBwbGljYXRpb24vanNvbicpO1xuICAgIH1cblxuICAgIC8qKlxuICAgICAqIERlbGV0ZXMgdGhlIFVSTCBmb3IgeW91ciBHZXQgUmV0ZW50aW9uIE1lc3NhZ2UgZW5kcG9pbnQsIGluIHRoZSBzYW5kYm94IG9yIHByb2R1Y3Rpb24gZW52aXJvbm1lbnRzLlxuICAgICAqXG4gICAgICogQHRocm93cyBBUElFeGNlcHRpb24gSWYgYSByZXNwb25zZSB3YXMgcmV0dXJuZWQgaW5kaWNhdGluZyB0aGUgcmVxdWVzdCBjb3VsZCBub3QgYmUgcHJvY2Vzc2VkXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL3JldGVudGlvbm1lc3NhZ2luZy9kZWxldGUtcmVhbHRpbWUtdXJsIERlbGV0ZSBSZWFsdGltZSBVUkx9XG4gICAgICovXG4gICAgcHVibGljIGFzeW5jIGRlbGV0ZVJlYWx0aW1lVVJMKCk6IFByb21pc2U8dm9pZD4ge1xuICAgICAgICBhd2FpdCB0aGlzLm1ha2VSZXF1ZXN0KFwiL2luQXBwcy92MS9tZXNzYWdpbmcvcmVhbHRpbWUvdXJsXCIsIFwiREVMRVRFXCIsIHt9LCBudWxsLCBudWxsLCB1bmRlZmluZWQpO1xuICAgIH1cblxuICAgIC8qKlxuICAgICAqIEdldHMgdGhlIFVSTCBmb3IgcmVhbC10aW1lIG1lc3NhZ2VzIHRoYXQgcG9pbnRzIHRvIHlvdXIgR2V0IFJldGVudGlvbiBNZXNzYWdlIGVuZHBvaW50LCB3aGljaCB5b3UgcHJldmlvdXNseSBjb25maWd1cmVkLlxuICAgICAqXG4gICAgICogQHJldHVybiBUaGUgcmVzcG9uc2UgYm9keSB0aGF0IGNvbnRhaW5zIHRoZSBVUkwgZm9yIHlvdXIgR2V0IFJldGVudGlvbiBNZXNzYWdlIGVuZHBvaW50LlxuICAgICAqIEB0aHJvd3MgQVBJRXhjZXB0aW9uIElmIGEgcmVzcG9uc2Ugd2FzIHJldHVybmVkIGluZGljYXRpbmcgdGhlIHJlcXVlc3QgY291bGQgbm90IGJlIHByb2Nlc3NlZFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9yZXRlbnRpb25tZXNzYWdpbmcvZ2V0LXJlYWx0aW1lLXVybCBHZXQgUmVhbHRpbWUgVVJMfVxuICAgICAqL1xuICAgIHB1YmxpYyBhc3luYyBnZXRSZWFsdGltZVVSTCgpOiBQcm9taXNlPFJlYWx0aW1lVXJsUmVzcG9uc2U+IHtcbiAgICAgICAgcmV0dXJuIGF3YWl0IHRoaXMubWFrZVJlcXVlc3QoXCIvaW5BcHBzL3YxL21lc3NhZ2luZy9yZWFsdGltZS91cmxcIiwgXCJHRVRcIiwge30sIG51bGwsIG5ldyBSZWFsdGltZVVybFJlc3BvbnNlVmFsaWRhdG9yKCksIHVuZGVmaW5lZCk7XG4gICAgfVxuXG4gICAgLyoqXG4gICAgICogSW5pdGlhdGVzIGEgcGVyZm9ybWFuY2UgdGVzdCBvZiB5b3VyIEdldCBSZXRlbnRpb24gTWVzc2FnZSBlbmRwb2ludCBpbiB0aGUgc2FuZGJveCBlbnZpcm9ubWVudC5cbiAgICAgKlxuICAgICAqIEBwYXJhbSBwZXJmb3JtYW5jZVRlc3RSZXF1ZXN0IFRoZSByZXF1ZXN0IGJvZHkgd2hpY2ggc3BlY2lmaWVzIGEgdHJhbnNhY3Rpb24gaWRlbnRpZmllciBvZiBhbiBJbi1BcHAgUHVyY2hhc2UgdG8gdXNlIGZvciB0aGlzIHRlc3QuXG4gICAgICogQHJldHVybiBUaGUgcGVyZm9ybWFuY2UgdGVzdCByZXNwb25zZSBvYmplY3QuXG4gICAgICogQHRocm93cyBBUElFeGNlcHRpb24gSWYgYSByZXNwb25zZSB3YXMgcmV0dXJuZWQgaW5kaWNhdGluZyB0aGUgcmVxdWVzdCBjb3VsZCBub3QgYmUgcHJvY2Vzc2VkXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL3JldGVudGlvbm1lc3NhZ2luZy9pbml0aWF0ZS1wZXJmb3JtYW5jZS10ZXN0IEluaXRpYXRlIFBlcmZvcm1hbmNlIFRlc3R9XG4gICAgICovXG4gICAgcHVibGljIGFzeW5jIGluaXRpYXRlUGVyZm9ybWFuY2VUZXN0KHBlcmZvcm1hbmNlVGVzdFJlcXVlc3Q6IFBlcmZvcm1hbmNlVGVzdFJlcXVlc3QpOiBQcm9taXNlPFBlcmZvcm1hbmNlVGVzdFJlc3BvbnNlPiB7XG4gICAgICAgIHJldHVybiBhd2FpdCB0aGlzLm1ha2VSZXF1ZXN0KFwiL2luQXBwcy92MS9tZXNzYWdpbmcvcGVyZm9ybWFuY2VUZXN0XCIsIFwiUE9TVFwiLCB7fSwgcGVyZm9ybWFuY2VUZXN0UmVxdWVzdCwgbmV3IFBlcmZvcm1hbmNlVGVzdFJlc3BvbnNlVmFsaWRhdG9yKCksICdhcHBsaWNhdGlvbi9qc29uJyk7XG4gICAgfVxuXG4gICAgLyoqXG4gICAgICogR2V0cyB0aGUgcmVzdWx0cyBvZiB0aGUgcGVyZm9ybWFuY2UgdGVzdCBmb3IgdGhlIHNwZWNpZmllZCBpZGVudGlmaWVyLlxuICAgICAqXG4gICAgICogQHBhcmFtIHJlcXVlc3RJZCBUaGUgSUQgb2YgdGhlIHBlcmZvcm1hbmNlIHRlc3QgdG8gcmV0dXJuLCB3aGljaCB5b3UgcmVjZWl2ZSBpbiB0aGUgUGVyZm9ybWFuY2VUZXN0UmVzcG9uc2Ugd2hlbiB5b3UgY2FsbCBJbml0aWF0ZSBQZXJmb3JtYW5jZSBUZXN0LlxuICAgICAqIEByZXR1cm4gQW4gb2JqZWN0IHRoZSBBUEkgcmV0dXJucyB0aGF0IGRlc2NyaWJlcyB0aGUgcGVyZm9ybWFuY2UgdGVzdCByZXN1bHRzLlxuICAgICAqIEB0aHJvd3MgQVBJRXhjZXB0aW9uIElmIGEgcmVzcG9uc2Ugd2FzIHJldHVybmVkIGluZGljYXRpbmcgdGhlIHJlcXVlc3QgY291bGQgbm90IGJlIHByb2Nlc3NlZFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9yZXRlbnRpb25tZXNzYWdpbmcvZ2V0LXBlcmZvcm1hbmNlLXRlc3QtcmVzdWx0cyBHZXQgUGVyZm9ybWFuY2UgVGVzdCBSZXN1bHRzfVxuICAgICAqL1xuICAgIHB1YmxpYyBhc3luYyBnZXRQZXJmb3JtYW5jZVRlc3RSZXN1bHRzKHJlcXVlc3RJZDogc3RyaW5nKTogUHJvbWlzZTxQZXJmb3JtYW5jZVRlc3RSZXN1bHRSZXNwb25zZT4ge1xuICAgICAgICByZXR1cm4gYXdhaXQgdGhpcy5tYWtlUmVxdWVzdChcIi9pbkFwcHMvdjEvbWVzc2FnaW5nL3BlcmZvcm1hbmNlVGVzdC9yZXN1bHQvXCIgKyByZXF1ZXN0SWQsIFwiR0VUXCIsIHt9LCBudWxsLCBuZXcgUGVyZm9ybWFuY2VUZXN0UmVzdWx0UmVzcG9uc2VWYWxpZGF0b3IoKSwgdW5kZWZpbmVkKTtcbiAgICB9XG5cbiAgICAvKipcbiAgICAgICogR2V0IGEgY3VzdG9tZXIncyBhcHAgdHJhbnNhY3Rpb24gaW5mb3JtYXRpb24gZm9yIHlvdXIgYXBwLlxuICAgICAgKlxuICAgICAgKiBAcGFyYW0gYW55VHJhbnNhY3Rpb25JZCBBbnkgdHJhbnNhY3Rpb25JZCwgb3JpZ2luYWxUcmFuc2FjdGlvbklkLCBvciBhcHBUcmFuc2FjdGlvbklkIHRoYXQgYmVsb25ncyB0byB0aGUgY3VzdG9tZXIgZm9yIHlvdXIgYXBwLlxuICAgICAgKiBAcmV0dXJuIEEgcmVzcG9uc2UgdGhhdCBjb250YWlucyBzaWduZWQgYXBwIHRyYW5zYWN0aW9uIGluZm9ybWF0aW9uIGZvciBhIGN1c3RvbWVyLlxuICAgICAgKiBAdGhyb3dzIEFQSUV4Y2VwdGlvbiBJZiBhIHJlc3BvbnNlIHdhcyByZXR1cm5lZCBpbmRpY2F0aW5nIHRoZSByZXF1ZXN0IGNvdWxkIG5vdCBiZSBwcm9jZXNzZWRcbiAgICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2dldC1hcHAtdHJhbnNhY3Rpb24taW5mbyBHZXQgQXBwIFRyYW5zYWN0aW9uIEluZm99XG4gICAgICAqL1xuICAgICBwdWJsaWMgYXN5bmMgZ2V0QXBwVHJhbnNhY3Rpb25JbmZvKGFueVRyYW5zYWN0aW9uSWQ6IHN0cmluZyk6IFByb21pc2U8QXBwVHJhbnNhY3Rpb25JbmZvUmVzcG9uc2U+IHtcbiAgICAgICAgIHJldHVybiBhd2FpdCB0aGlzLm1ha2VSZXF1ZXN0KFwiL2luQXBwcy92MS90cmFuc2FjdGlvbnMvYXBwVHJhbnNhY3Rpb25zL1wiICsgYW55VHJhbnNhY3Rpb25JZCwgXCJHRVRcIiwge30sIG51bGwsIG5ldyBBcHBUcmFuc2FjdGlvbkluZm9SZXNwb25zZVZhbGlkYXRvcigpLCB1bmRlZmluZWQpO1xuICAgICB9XG5cbiAgICAvKipcbiAgICAgKiBOb3RpZmllcyB0aGUgQXBwIFN0b3JlIHNlcnZlciB0aGF0IHlvdXIgc3lzdGVtIGhhcyBmaW5pc2hlZCBwcm9jZXNzaW5nIHRoZSBjdXN0b21lcidzIHRyYW5zYWN0aW9uLlxuICAgICAqXG4gICAgICogQHBhcmFtIHRyYW5zYWN0aW9uSWQgVGhlIHRyYW5zYWN0aW9uIGlkZW50aWZpZXIgb2YgdGhlIHRyYW5zYWN0aW9uIHRvIG1hcmsgYXMgZmluaXNoZWQuXG4gICAgICogQHRocm93cyBBUElFeGNlcHRpb24gSWYgYSByZXNwb25zZSB3YXMgcmV0dXJuZWQgaW5kaWNhdGluZyB0aGUgcmVxdWVzdCBjb3VsZCBub3QgYmUgcHJvY2Vzc2VkXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2ZpbmlzaC10cmFuc2FjdGlvbiBGaW5pc2ggVHJhbnNhY3Rpb259XG4gICAgICovXG4gICAgcHVibGljIGFzeW5jIGZpbmlzaFRyYW5zYWN0aW9uKHRyYW5zYWN0aW9uSWQ6IHN0cmluZyk6IFByb21pc2U8dm9pZD4ge1xuICAgICAgICBhd2FpdCB0aGlzLm1ha2VSZXF1ZXN0KFwiL2luQXBwcy92MS90cmFuc2FjdGlvbnMvXCIgKyB0cmFuc2FjdGlvbklkICsgXCIvZmluaXNoXCIsIFwiUE9TVFwiLCB7fSwgbnVsbCwgbnVsbCwgdW5kZWZpbmVkKTtcbiAgICB9XG5cbiAgICBwcml2YXRlIGNyZWF0ZUJlYXJlclRva2VuKCk6IHN0cmluZyB7XG4gICAgICAgIGNvbnN0IHBheWxvYWQgPSB7XG4gICAgICAgICAgICBiaWQ6IHRoaXMuYnVuZGxlSWRcbiAgICAgICAgfVxuICAgICAgICByZXR1cm4ganNvbndlYnRva2VuLnNpZ24ocGF5bG9hZCwgdGhpcy5zaWduaW5nS2V5LCB7IGFsZ29yaXRobTogJ0VTMjU2Jywga2V5aWQ6IHRoaXMua2V5SWQsIGlzc3VlcjogdGhpcy5pc3N1ZXJJZCwgYXVkaWVuY2U6ICdhcHBzdG9yZWNvbm5lY3QtdjEnLCBleHBpcmVzSW46ICc1bSd9KTtcbiAgICB9XG59XG5cblxuZXhwb3J0IGNsYXNzIEFQSUV4Y2VwdGlvbiBleHRlbmRzIEVycm9yIHtcbiAgICBwdWJsaWMgaHR0cFN0YXR1c0NvZGU6IG51bWJlclxuICAgIHB1YmxpYyBhcGlFcnJvcjogbnVtYmVyIHwgQVBJRXJyb3IgfCBudWxsXG4gICAgcHVibGljIGVycm9yTWVzc2FnZTogc3RyaW5nIHwgbnVsbFxuXG4gICAgY29uc3RydWN0b3IoaHR0cFN0YXR1c0NvZGU6IG51bWJlciwgYXBpRXJyb3I6IG51bWJlciB8IG51bGwgPSBudWxsLCBlcnJvck1lc3NhZ2U6IHN0cmluZyB8IG51bGwgPSBudWxsKSB7XG4gICAgICAgIHN1cGVyKClcbiAgICAgICAgdGhpcy5odHRwU3RhdHVzQ29kZSA9IGh0dHBTdGF0dXNDb2RlXG4gICAgICAgIHRoaXMuYXBpRXJyb3IgPSBhcGlFcnJvclxuICAgICAgICB0aGlzLmVycm9yTWVzc2FnZSA9IGVycm9yTWVzc2FnZVxuICAgIH1cbn1cblxuLyoqXG4gKiBFcnJvciBjb2RlcyB0aGF0IEFwcCBTdG9yZSBTZXJ2ZXIgQVBJIHJlc3BvbnNlcyByZXR1cm4uXG4gKiBcbiAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9lcnJvcl9jb2RlcyBFcnJvciBjb2Rlc31cbiAqL1xuZXhwb3J0IGVudW0gQVBJRXJyb3Ige1xuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIGFuIGludmFsaWQgcmVxdWVzdC5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvZ2VuZXJhbGJhZHJlcXVlc3RlcnJvciBHZW5lcmFsQmFkUmVxdWVzdEVycm9yfVxuICAgICAqL1xuICAgIEdFTkVSQUxfQkFEX1JFUVVFU1QgPSA0MDAwMDAwLFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgYW4gaW52YWxpZCBhcHAgaWRlbnRpZmllci5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvaW52YWxpZGFwcGlkZW50aWZpZXJlcnJvciBJbnZhbGlkQXBwSWRlbnRpZmllckVycm9yfVxuICAgICAqL1xuICAgIElOVkFMSURfQVBQX0lERU5USUZJRVIgPSA0MDAwMDAyLFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgYW4gaW52YWxpZCByZXF1ZXN0IHJldmlzaW9uLlxuICAgICAqIFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9pbnZhbGlkcmVxdWVzdHJldmlzaW9uZXJyb3IgSW52YWxpZFJlcXVlc3RSZXZpc2lvbkVycm9yfVxuICAgICAqL1xuICAgIElOVkFMSURfUkVRVUVTVF9SRVZJU0lPTiA9IDQwMDAwMDUsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyBhbiBpbnZhbGlkIHRyYW5zYWN0aW9uIGlkZW50aWZpZXIuXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2ludmFsaWR0cmFuc2FjdGlvbmlkZXJyb3IgSW52YWxpZFRyYW5zYWN0aW9uSWRFcnJvcn1cbiAgICAgKi9cbiAgICBJTlZBTElEX1RSQU5TQUNUSU9OX0lEID0gNDAwMDAwNixcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIGFuIGludmFsaWQgb3JpZ2luYWwgdHJhbnNhY3Rpb24gaWRlbnRpZmllci5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvaW52YWxpZG9yaWdpbmFsdHJhbnNhY3Rpb25pZGVycm9yIEludmFsaWRPcmlnaW5hbFRyYW5zYWN0aW9uSWRFcnJvcn1cbiAgICAgKi9cbiAgICBJTlZBTElEX09SSUdJTkFMX1RSQU5TQUNUSU9OX0lEID0gNDAwMDAwOCxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIGFuIGludmFsaWQgZXh0ZW5kLWJ5LWRheXMgdmFsdWUuXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2ludmFsaWRleHRlbmRieWRheXNlcnJvciBJbnZhbGlkRXh0ZW5kQnlEYXlzRXJyb3J9XG4gICAgICovXG4gICAgSU5WQUxJRF9FWFRFTkRfQllfREFZUyA9IDQwMDAwMDksXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyBhbiBpbnZhbGlkIHJlYXNvbiBjb2RlLlxuICAgICAqIFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9pbnZhbGlkZXh0ZW5kcmVhc29uY29kZWVycm9yIEludmFsaWRFeHRlbmRSZWFzb25Db2RlRXJyb3J9XG4gICAgICovXG4gICAgSU5WQUxJRF9FWFRFTkRfUkVBU09OX0NPREUgPSA0MDAwMDEwLFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgYW4gaW52YWxpZCByZXF1ZXN0IGlkZW50aWZpZXIuXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2ludmFsaWRyZXF1ZXN0aWRlbnRpZmllcmVycm9yIEludmFsaWRSZXF1ZXN0SWRlbnRpZmllckVycm9yfVxuICAgICAqL1xuICAgIElOVkFMSURfUkVRVUVTVF9JREVOVElGSUVSID0gNDAwMDAxMSxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIHRoYXQgdGhlIHN0YXJ0IGRhdGUgaXMgZWFybGllciB0aGFuIHRoZSBlYXJsaWVzdCBhbGxvd2VkIGRhdGUuXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL3N0YXJ0ZGF0ZXRvb2ZhcmlucGFzdGVycm9yIFN0YXJ0RGF0ZVRvb0ZhckluUGFzdEVycm9yfVxuICAgICAqL1xuICAgIFNUQVJUX0RBVEVfVE9PX0ZBUl9JTl9QQVNUID0gNDAwMDAxMixcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIHRoYXQgdGhlIGVuZCBkYXRlIHByZWNlZGVzIHRoZSBzdGFydCBkYXRlLCBvciB0aGUgdHdvIGRhdGVzIGFyZSBlcXVhbC5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvc3RhcnRkYXRlYWZ0ZXJlbmRkYXRlZXJyb3IgU3RhcnREYXRlQWZ0ZXJFbmREYXRlRXJyb3J9XG4gICAgICovXG4gICAgU1RBUlRfREFURV9BRlRFUl9FTkRfREFURSA9IDQwMDAwMTMsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgcGFnaW5hdGlvbiB0b2tlbiBpcyBpbnZhbGlkLlxuICAgICAqIFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9pbnZhbGlkcGFnaW5hdGlvbnRva2VuZXJyb3IgSW52YWxpZFBhZ2luYXRpb25Ub2tlbkVycm9yfVxuICAgICAqL1xuICAgIElOVkFMSURfUEFHSU5BVElPTl9UT0tFTiA9IDQwMDAwMTQsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgc3RhcnQgZGF0ZSBpcyBpbnZhbGlkLlxuICAgICAqIFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9pbnZhbGlkc3RhcnRkYXRlZXJyb3IgSW52YWxpZFN0YXJ0RGF0ZUVycm9yfVxuICAgICAqL1xuICAgIElOVkFMSURfU1RBUlRfREFURSA9IDQwMDAwMTUsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgZW5kIGRhdGUgaXMgaW52YWxpZC5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvaW52YWxpZGVuZGRhdGVlcnJvciBJbnZhbGlkRW5kRGF0ZUVycm9yfVxuICAgICAqL1xuICAgIElOVkFMSURfRU5EX0RBVEUgPSA0MDAwMDE2LFxuICAgIFxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIHRoZSBwYWdpbmF0aW9uIHRva2VuIGV4cGlyZWQuXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL3BhZ2luYXRpb250b2tlbmV4cGlyZWRlcnJvciBQYWdpbmF0aW9uVG9rZW5FeHBpcmVkRXJyb3J9XG4gICAgICovXG4gICAgUEFHSU5BVElPTl9UT0tFTl9FWFBJUkVEID0gNDAwMDAxNyxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIHRoZSBub3RpZmljYXRpb24gdHlwZSBvciBzdWJ0eXBlIGlzIGludmFsaWQuXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2ludmFsaWRub3RpZmljYXRpb250eXBlZXJyb3IgSW52YWxpZE5vdGlmaWNhdGlvblR5cGVFcnJvcn1cbiAgICAgKi9cbiAgICBJTlZBTElEX05PVElGSUNBVElPTl9UWVBFID0gNDAwMDAxOCxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIHRoZSByZXF1ZXN0IGlzIGludmFsaWQgYmVjYXVzZSBpdCBoYXMgdG9vIG1hbnkgY29uc3RyYWludHMgYXBwbGllZC5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvbXVsdGlwbGVmaWx0ZXJzc3VwcGxpZWRlcnJvciBNdWx0aXBsZUZpbHRlcnNTdXBwbGllZEVycm9yfVxuICAgICAqL1xuICAgIE1VTFRJUExFX0ZJTFRFUlNfU1VQUExJRUQgPSA0MDAwMDE5LFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgdGhlIHRlc3Qgbm90aWZpY2F0aW9uIHRva2VuIGlzIGludmFsaWQuXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2ludmFsaWR0ZXN0bm90aWZpY2F0aW9udG9rZW5lcnJvciBJbnZhbGlkVGVzdE5vdGlmaWNhdGlvblRva2VuRXJyb3J9XG4gICAgICovXG4gICAgSU5WQUxJRF9URVNUX05PVElGSUNBVElPTl9UT0tFTiA9IDQwMDAwMjAsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyBhbiBpbnZhbGlkIHNvcnQgcGFyYW1ldGVyLlxuICAgICAqIFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9pbnZhbGlkc29ydGVycm9yIEludmFsaWRTb3J0RXJyb3J9XG4gICAgICovXG4gICAgSU5WQUxJRF9TT1JUID0gNDAwMDAyMSxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIGFuIGludmFsaWQgcHJvZHVjdCB0eXBlIHBhcmFtZXRlci5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvaW52YWxpZHByb2R1Y3R0eXBlZXJyb3IgSW52YWxpZFByb2R1Y3RUeXBlRXJyb3J9XG4gICAgICovXG4gICAgSU5WQUxJRF9QUk9EVUNUX1RZUEUgPSA0MDAwMDIyLFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgdGhlIHByb2R1Y3QgSUQgcGFyYW1ldGVyIGlzIGludmFsaWQuXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2ludmFsaWRwcm9kdWN0aWRlcnJvciBJbnZhbGlkUHJvZHVjdElkRXJyb3J9XG4gICAgICovXG4gICAgSU5WQUxJRF9QUk9EVUNUX0lEID0gNDAwMDAyMyxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIGFuIGludmFsaWQgc3Vic2NyaXB0aW9uIGdyb3VwIGlkZW50aWZpZXIuXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2ludmFsaWRzdWJzY3JpcHRpb25ncm91cGlkZW50aWZpZXJlcnJvciBJbnZhbGlkU3Vic2NyaXB0aW9uR3JvdXBJZGVudGlmaWVyRXJyb3J9XG4gICAgICovXG4gICAgSU5WQUxJRF9TVUJTQ1JJUFRJT05fR1JPVVBfSURFTlRJRklFUiA9IDQwMDAwMjQsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgcXVlcnkgcGFyYW1ldGVyIGV4Y2x1ZGUtcmV2b2tlZCBpcyBpbnZhbGlkLlxuICAgICAqIFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9pbnZhbGlkZXhjbHVkZXJldm9rZWRlcnJvciBJbnZhbGlkRXhjbHVkZVJldm9rZWRFcnJvcn1cbiAgICAgKiBcbiAgICAgKiBAZGVwcmVjYXRlZFxuICAgICAqL1xuICAgIElOVkFMSURfRVhDTFVERV9SRVZPS0VEID0gNDAwMDAyNSxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIGFuIGludmFsaWQgaW4tYXBwIG93bmVyc2hpcCB0eXBlIHBhcmFtZXRlci5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvaW52YWxpZGluYXBwb3duZXJzaGlwdHlwZWVycm9yIEludmFsaWRJbkFwcE93bmVyc2hpcFR5cGVFcnJvcn1cbiAgICAgKi9cbiAgICBJTlZBTElEX0lOX0FQUF9PV05FUlNISVBfVFlQRSA9IDQwMDAwMjYsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyBhIHJlcXVpcmVkIHN0b3JlZnJvbnQgY291bnRyeSBjb2RlIGlzIGVtcHR5LlxuICAgICAqIFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9pbnZhbGlkZW1wdHlzdG9yZWZyb250Y291bnRyeWNvZGVsaXN0ZXJyb3IgSW52YWxpZEVtcHR5U3RvcmVmcm9udENvdW50cnlDb2RlTGlzdEVycm9yfVxuICAgICAqL1xuICAgIElOVkFMSURfRU1QVFlfU1RPUkVGUk9OVF9DT1VOVFJZX0NPREVfTElTVCA9IDQwMDAwMjcsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyBhIHN0b3JlZnJvbnQgY29kZSBpcyBpbnZhbGlkLlxuICAgICAqIFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9pbnZhbGlkc3RvcmVmcm9udGNvdW50cnljb2RlZXJyb3IgSW52YWxpZFN0b3JlZnJvbnRDb3VudHJ5Q29kZUVycm9yfVxuICAgICAqL1xuICAgIElOVkFMSURfU1RPUkVGUk9OVF9DT1VOVFJZX0NPREUgPSA0MDAwMDI4LFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgdGhlIHJldm9rZWQgcGFyYW1ldGVyIGNvbnRhaW5zIGFuIGludmFsaWQgdmFsdWUuXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2ludmFsaWRyZXZva2VkZXJyb3IgSW52YWxpZFJldm9rZWRFcnJvcn1cbiAgICAgKi9cbiAgICBJTlZBTElEX1JFVk9LRUQgPSA0MDAwMDMwLFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgdGhlIHN0YXR1cyBwYXJhbWV0ZXIgaXMgaW52YWxpZC5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvaW52YWxpZHN0YXR1c2Vycm9yIEludmFsaWRTdGF0dXNFcnJvcn1cbiAgICAgKi9cbiAgICBJTlZBTElEX1NUQVRVUyA9IDQwMDAwMzEsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgdmFsdWUgb2YgdGhlIGFjY291bnQgdGVudXJlIGZpZWxkIGlzIGludmFsaWQuXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2ludmFsaWRhY2NvdW50dGVudXJlZXJyb3IgSW52YWxpZEFjY291bnRUZW51cmVFcnJvcn1cbiAgICAgKi9cbiAgICBJTlZBTElEX0FDQ09VTlRfVEVOVVJFID0gNDAwMDAzMixcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIHRoZSB2YWx1ZSBvZiB0aGUgYXBwIGFjY291bnQgdG9rZW4gZmllbGQgaXMgaW52YWxpZC5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvaW52YWxpZGFwcGFjY291bnR0b2tlbmVycm9yIEludmFsaWRBcHBBY2NvdW50VG9rZW5FcnJvcn1cbiAgICAgKi9cbiAgICBJTlZBTElEX0FQUF9BQ0NPVU5UX1RPS0VOID0gNDAwMDAzMyxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIHRoZSB2YWx1ZSBvZiB0aGUgY29uc3VtcHRpb24gc3RhdHVzIGZpZWxkIGlzIGludmFsaWQuXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2ludmFsaWRjb25zdW1wdGlvbnN0YXR1c2Vycm9yIEludmFsaWRDb25zdW1wdGlvblN0YXR1c0Vycm9yfVxuICAgICAqL1xuICAgIElOVkFMSURfQ09OU1VNUFRJT05fU1RBVFVTID0gNDAwMDAzNCxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIHRoZSBjdXN0b21lciBjb25zZW50ZWQgZmllbGQgaXMgaW52YWxpZCBvciBkb2VzbuKAmXQgaW5kaWNhdGUgdGhhdCB0aGUgY3VzdG9tZXIgY29uc2VudGVkLlxuICAgICAqIFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9pbnZhbGlkY3VzdG9tZXJjb25zZW50ZWRlcnJvciBJbnZhbGlkQ3VzdG9tZXJDb25zZW50ZWRFcnJvcn1cbiAgICAgKi9cbiAgICBJTlZBTElEX0NVU1RPTUVSX0NPTlNFTlRFRCA9IDQwMDAwMzUsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgdmFsdWUgaW4gdGhlIGRlbGl2ZXJ5IHN0YXR1cyBmaWVsZCBpcyBpbnZhbGlkLlxuICAgICAqIFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9pbnZhbGlkZGVsaXZlcnlzdGF0dXNlcnJvciBJbnZhbGlkRGVsaXZlcnlTdGF0dXNFcnJvcn1cbiAgICAgKi9cbiAgICBJTlZBTElEX0RFTElWRVJZX1NUQVRVUyA9IDQwMDAwMzYsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgdmFsdWUgaW4gdGhlIGxpZmV0aW1lIGRvbGxhcnMgcHVyY2hhc2VkIGZpZWxkIGlzIGludmFsaWQuXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2ludmFsaWRsaWZldGltZWRvbGxhcnNwdXJjaGFzZWRlcnJvciBJbnZhbGlkTGlmZXRpbWVEb2xsYXJzUHVyY2hhc2VkRXJyb3J9XG4gICAgICovXG4gICAgSU5WQUxJRF9MSUZFVElNRV9ET0xMQVJTX1BVUkNIQVNFRCA9IDQwMDAwMzcsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgdmFsdWUgaW4gdGhlIGxpZmV0aW1lIGRvbGxhcnMgcmVmdW5kZWQgZmllbGQgaXMgaW52YWxpZC5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvaW52YWxpZGxpZmV0aW1lZG9sbGFyc3JlZnVuZGVkZXJyb3IgSW52YWxpZExpZmV0aW1lRG9sbGFyc1JlZnVuZGVkRXJyb3J9XG4gICAgICovXG4gICAgSU5WQUxJRF9MSUZFVElNRV9ET0xMQVJTX1JFRlVOREVEID0gNDAwMDAzOCxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIHRoZSB2YWx1ZSBpbiB0aGUgcGxhdGZvcm0gZmllbGQgaXMgaW52YWxpZC5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvaW52YWxpZHBsYXRmb3JtZXJyb3IgSW52YWxpZFBsYXRmb3JtRXJyb3J9XG4gICAgICovXG4gICAgSU5WQUxJRF9QTEFURk9STSA9IDQwMDAwMzksXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgdmFsdWUgaW4gdGhlIHBsYXl0aW1lIGZpZWxkIGlzIGludmFsaWQuXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2ludmFsaWRwbGF5dGltZWVycm9yIEludmFsaWRQbGF5VGltZUVycm9yfVxuICAgICAqL1xuICAgIElOVkFMSURfUExBWV9USU1FID0gNDAwMDA0MCxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIHRoZSB2YWx1ZSBpbiB0aGUgc2FtcGxlIGNvbnRlbnQgcHJvdmlkZWQgZmllbGQgaXMgaW52YWxpZC5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvaW52YWxpZHNhbXBsZWNvbnRlbnRwcm92aWRlZGVycm9yIEludmFsaWRTYW1wbGVDb250ZW50UHJvdmlkZWRFcnJvcn1cbiAgICAgKi9cbiAgICBJTlZBTElEX1NBTVBMRV9DT05URU5UX1BST1ZJREVEID0gNDAwMDA0MSxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIHRoZSB2YWx1ZSBpbiB0aGUgdXNlciBzdGF0dXMgZmllbGQgaXMgaW52YWxpZC5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvaW52YWxpZHVzZXJzdGF0dXNlcnJvciBJbnZhbGlkVXNlclN0YXR1c0Vycm9yfVxuICAgICAqL1xuICAgIElOVkFMSURfVVNFUl9TVEFUVVMgPSA0MDAwMDQyLFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgdGhlIHRyYW5zYWN0aW9uIGlkZW50aWZpZXIgZG9lc27igJl0IHJlcHJlc2VudCBhIGNvbnN1bWFibGUgaW4tYXBwIHB1cmNoYXNlLlxuICAgICAqIFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9pbnZhbGlkdHJhbnNhY3Rpb25ub3Rjb25zdW1hYmxlZXJyb3IgSW52YWxpZFRyYW5zYWN0aW9uTm90Q29uc3VtYWJsZUVycm9yfVxuICAgICAqIFxuICAgICAqIEBkZXByZWNhdGVkXG4gICAgICovXG4gICAgSU5WQUxJRF9UUkFOU0FDVElPTl9OT1RfQ09OU1VNQUJMRSA9IDQwMDAwNDMsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgdHJhbnNhY3Rpb24gaWRlbnRpZmllciByZXByZXNlbnRzIGFuIHVuc3VwcG9ydGVkIGluLWFwcCBwdXJjaGFzZSB0eXBlLlxuICAgICAqIFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9pbnZhbGlkdHJhbnNhY3Rpb250eXBlbm90c3VwcG9ydGVkZXJyb3IgSW52YWxpZFRyYW5zYWN0aW9uVHlwZU5vdFN1cHBvcnRlZEVycm9yfVxuICAgICAqL1xuICAgIElOVkFMSURfVFJBTlNBQ1RJT05fVFlQRV9OT1RfU1VQUE9SVEVEID0gNDAwMDA0NyxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIHRoZSBlbmRwb2ludCBkb2Vzbid0IHN1cHBvcnQgYW4gYXBwIHRyYW5zYWN0aW9uIElELlxuICAgICAqIFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9hcHB0cmFuc2FjdGlvbmlkbm90c3VwcG9ydGVkZXJyb3IgQXBwVHJhbnNhY3Rpb25JZE5vdFN1cHBvcnRlZEVycm9yfVxuICAgICAqL1xuICAgIEFQUF9UUkFOU0FDVElPTl9JRF9OT1RfU1VQUE9SVEVEX0VSUk9SID0gNDAwMDA0OCxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIHRoZSBpbWFnZSB0aGF0J3MgdXBsb2FkaW5nIGlzIGludmFsaWQuXG4gICAgICpcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL2ludmFsaWRpbWFnZWVycm9yIEludmFsaWRJbWFnZUVycm9yfVxuICAgICAqL1xuICAgIElOVkFMSURfSU1BR0UgPSA0MDAwMTYxLFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgdGhlIGhlYWRlciB0ZXh0IGlzIHRvbyBsb25nLlxuICAgICAqXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL3JldGVudGlvbm1lc3NhZ2luZy9oZWFkZXJ0b29sb25nZXJyb3IgSGVhZGVyVG9vTG9uZ0Vycm9yfVxuICAgICAqL1xuICAgIEhFQURFUl9UT09fTE9ORyA9IDQwMDAxNjIsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgYm9keSB0ZXh0IGlzIHRvbyBsb25nLlxuICAgICAqXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL3JldGVudGlvbm1lc3NhZ2luZy9ib2R5dG9vbG9uZ2Vycm9yIEJvZHlUb29Mb25nRXJyb3J9XG4gICAgICovXG4gICAgQk9EWV9UT09fTE9ORyA9IDQwMDAxNjMsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgbG9jYWxlIGlzIGludmFsaWQuXG4gICAgICpcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL2ludmFsaWRsb2NhbGVlcnJvciBJbnZhbGlkTG9jYWxlRXJyb3J9XG4gICAgICovXG4gICAgSU5WQUxJRF9MT0NBTEUgPSA0MDAwMTY0LFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgdGhlIGFsdGVybmF0aXZlIHRleHQgZm9yIGFuIGltYWdlIGlzIHRvbyBsb25nLlxuICAgICAqXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL3JldGVudGlvbm1lc3NhZ2luZy9hbHR0ZXh0dG9vbG9uZ2Vycm9yIEFsdFRleHRUb29Mb25nRXJyb3J9XG4gICAgICovXG4gICAgQUxUX1RFWFRfVE9PX0xPTkcgPSA0MDAwMTc1LFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgdGhlIGFwcCBhY2NvdW50IHRva2VuIHZhbHVlIGlzIG5vdCBhIHZhbGlkIFVVSUQuXG4gICAgICpcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvaW52YWxpZGFwcGFjY291bnR0b2tlbnV1aWRlcnJvciBJbnZhbGlkQXBwQWNjb3VudFRva2VuVVVJREVycm9yfVxuICAgICAqL1xuICAgIElOVkFMSURfQVBQX0FDQ09VTlRfVE9LRU5fVVVJRF9FUlJPUiA9IDQwMDAxODMsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgdHJhbnNhY3Rpb24gaXMgZm9yIGEgcHJvZHVjdCB0aGUgY3VzdG9tZXIgb2J0YWlucyB0aHJvdWdoIEZhbWlseSBTaGFyaW5nLCB3aGljaCB0aGUgZW5kcG9pbnQgZG9lc27igJl0IHN1cHBvcnQuXG4gICAgICpcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvZmFtaWx5dHJhbnNhY3Rpb25ub3RzdXBwb3J0ZWRlcnJvciBGYW1pbHlUcmFuc2FjdGlvbk5vdFN1cHBvcnRlZEVycm9yfVxuICAgICAqL1xuICAgIEZBTUlMWV9UUkFOU0FDVElPTl9OT1RfU1VQUE9SVEVEX0VSUk9SID0gNDAwMDE4NSxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIHRoZSBlbmRwb2ludCBleHBlY3RzIGFuIG9yaWdpbmFsIHRyYW5zYWN0aW9uIGlkZW50aWZpZXIuXG4gICAgICpcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvdHJhbnNhY3Rpb25pZGlzbm90b3JpZ2luYWx0cmFuc2FjdGlvbmlkZXJyb3IgVHJhbnNhY3Rpb25JZElzTm90T3JpZ2luYWxUcmFuc2FjdGlvbklkRXJyb3J9XG4gICAgICovXG4gICAgVFJBTlNBQ1RJT05fSURfSVNfTk9UX09SSUdJTkFMX1RSQU5TQUNUSU9OX0lEX0VSUk9SID0gNDAwMDE4NyxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoZSBBUEkgcmV0dXJucyB0aGF0IGluZGljYXRlcyB0aGUgcGVyZm9ybWFuY2UgdGVzdCByZXF1ZXN0IGlzIGludmFsaWQuXG4gICAgICpcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL2ludmFsaWRwZXJmb3JtYW5jZXRlc3RyZXF1ZXN0ZXJyb3IgSW52YWxpZFBlcmZvcm1hbmNlVGVzdFJlcXVlc3RFcnJvcn1cbiAgICAgKi9cbiAgICBJTlZBTElEX1BFUkZPUk1BTkNFX1RFU1RfUkVRVUVTVCA9IDQwMDAyMTEsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgcmVxdWVzdCBJRCBpcyBpbnZhbGlkLlxuICAgICAqXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL3JldGVudGlvbm1lc3NhZ2luZy9pbnZhbGlkcmVxdWVzdGlkZXJyb3IgSW52YWxpZFJlcXVlc3RJZEVycm9yfVxuICAgICAqL1xuICAgIElOVkFMSURfUkVRVUVTVF9JRCA9IDQwMDAyMTIsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyBhbiBlcnJvciB3aXRoIGFuIGV4aXN0aW5nIHRlc3QuXG4gICAgICpcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL2V4aXN0aW5ncGVyZm9ybWFuY2V0ZXN0cnVuZXJyb3IgRXhpc3RpbmdQZXJmb3JtYW5jZVRlc3RSdW5FcnJvcn1cbiAgICAgKi9cbiAgICBFWElTVElOR19QRVJGT1JNQU5DRV9URVNUX1JVTiA9IDQwMDAyMTMsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgVVJMIGlzIGludmFsaWQuXG4gICAgICpcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL2JhZHJlcXVlc3RyZWFhbHRpbWV1cmxlcnJvciBCYWRSZXF1ZXN0UmVhbHRpbWVVcmxFcnJvcn1cbiAgICAgKi9cbiAgICBCQURfUkVRVUVTVF9SRUFMVElNRV9VUkwgPSA0MDAwMjE1LFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgdGhlIGltYWdlIHNpemUgcHJvdmlkZWQgaXMgaW52YWxpZC5cbiAgICAgKlxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9yZXRlbnRpb25tZXNzYWdpbmcvYmFkcmVxdWVzdGltYWdlc2l6ZWVycm9yIEJhZFJlcXVlc3RJbWFnZVNpemVFcnJvcn1cbiAgICAgKi9cbiAgICBCQURfUkVRVUVTVF9JTUFHRV9TSVpFID0gNDAwMDIxNixcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIHRoZXJlIGFyZSB0b28gbWFueSBidWxsZXQgcG9pbnRzLlxuICAgICAqXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL3JldGVudGlvbm1lc3NhZ2luZy9iYWRyZXF1ZXN0dG9vbWFueWJ1bGxldHBvaW50c2Vycm9yIEJhZFJlcXVlc3RUb29NYW55QnVsbGV0UG9pbnRzRXJyb3J9XG4gICAgICovXG4gICAgQkFEX1JFUVVFU1RfVE9PX01BTllfQlVMTEVUX1BPSU5UUyA9IDQwMDAyMTgsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgdGV4dCBmb3IgYSBidWxsZXQgcG9pbnQgaXMgdG9vIGxvbmcuXG4gICAgICpcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL2JhZHJlcXVlc3RidWxsZXRwb2ludHRleHR0b29sb25nZXJyb3IgQmFkUmVxdWVzdEJ1bGxldFBvaW50VGV4dFRvb0xvbmdFcnJvcn1cbiAgICAgKi9cbiAgICBCQURfUkVRVUVTVF9CVUxMRVRfUE9JTlRfVEVYVF9UT09fTE9ORyA9IDQwMDAyMTksXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGF0IG5vIGltYWdlIG9iamVjdCBpcyBpbmNsdWRlZCwgYnV0IHRoZSByZXF1ZXN0IGluZGljYXRlcyB0aGF0IHRoZSBoZWFkZXIgc2hvdWxkIGJlIHBsYWNlZCBhYm92ZSB0aGUgaW1hZ2UuXG4gICAgICpcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL2JhZHJlcXVlc3RhYm92ZWltYWdlZXJlcXVpcmVzYW5pbWFnZWVycm9yIEJhZFJlcXVlc3RBYm92ZUltYWdlUmVxdWlyZXNBbkltYWdlRXJyb3J9XG4gICAgICovXG4gICAgQkFEX1JFUVVFU1RfQUJPVkVfSU1BR0VfUkVRVUlSRVNfQU5fSU1BR0UgPSA0MDAwMjI0LFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgdGhlIHN1YnNjcmlwdGlvbiBkb2Vzbid0IHF1YWxpZnkgZm9yIGEgcmVuZXdhbC1kYXRlIGV4dGVuc2lvbiBkdWUgdG8gaXRzIHN1YnNjcmlwdGlvbiBzdGF0ZS5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvc3Vic2NyaXB0aW9uZXh0ZW5zaW9uaW5lbGlnaWJsZWVycm9yIFN1YnNjcmlwdGlvbkV4dGVuc2lvbkluZWxpZ2libGVFcnJvcn1cbiAgICAgKi9cbiAgICBTVUJTQ1JJUFRJT05fRVhURU5TSU9OX0lORUxJR0lCTEUgPSA0MDMwMDA0LFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgdGhlIHN1YnNjcmlwdGlvbiBkb2VzbuKAmXQgcXVhbGlmeSBmb3IgYSByZW5ld2FsLWRhdGUgZXh0ZW5zaW9uIGJlY2F1c2UgaXQgaGFzIGFscmVhZHkgcmVjZWl2ZWQgdGhlIG1heGltdW0gZXh0ZW5zaW9ucy5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvc3Vic2NyaXB0aW9ubWF4ZXh0ZW5zaW9uZXJyb3IgU3Vic2NyaXB0aW9uTWF4RXh0ZW5zaW9uRXJyb3J9XG4gICAgICovXG4gICAgU1VCU0NSSVBUSU9OX01BWF9FWFRFTlNJT04gPSA0MDMwMDA1LFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgYSBzdWJzY3JpcHRpb24gaXNuJ3QgZGlyZWN0bHkgZWxpZ2libGUgZm9yIGEgcmVuZXdhbCBkYXRlIGV4dGVuc2lvbiBiZWNhdXNlIHRoZSB1c2VyIG9idGFpbmVkIGl0IHRocm91Z2ggRmFtaWx5IFNoYXJpbmcuXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2ZhbWlseXNoYXJlZHN1YnNjcmlwdGlvbmV4dGVuc2lvbmluZWxpZ2libGVlcnJvciBGYW1pbHlTaGFyZWRTdWJzY3JpcHRpb25FeHRlbnNpb25JbmVsaWdpYmxlRXJyb3J9XG4gICAgICovXG4gICAgRkFNSUxZX1NIQVJFRF9TVUJTQ1JJUFRJT05fRVhURU5TSU9OX0lORUxJR0lCTEUgPSA0MDMwMDA3LFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgd2hlbiB5b3UgcmVhY2ggdGhlIG1heGltdW0gbnVtYmVyIG9mIHVwbG9hZGVkIGltYWdlcy5cbiAgICAgKlxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9yZXRlbnRpb25tZXNzYWdpbmcvbWF4aW11bW51bWJlcm9maW1hZ2VzcmVhY2hlZGVycm9yIE1heGltdW1OdW1iZXJPZkltYWdlc1JlYWNoZWRFcnJvcn1cbiAgICAgKi9cbiAgICBNQVhJTVVNX05VTUJFUl9PRl9JTUFHRVNfUkVBQ0hFRCA9IDQwMzAwMTQsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB3aGVuIHlvdSByZWFjaCB0aGUgbWF4aW11bSBudW1iZXIgb2YgdXBsb2FkZWQgbWVzc2FnZXMuXG4gICAgICpcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL21heGltdW1udW1iZXJvZm1lc3NhZ2VzcmVhY2hlZGVycm9yIE1heGltdW1OdW1iZXJPZk1lc3NhZ2VzUmVhY2hlZEVycm9yfVxuICAgICAqL1xuICAgIE1BWElNVU1fTlVNQkVSX09GX01FU1NBR0VTX1JFQUNIRUQgPSA0MDMwMDE2LFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgdGhlIG1lc3NhZ2UgaXNuJ3QgaW4gdGhlIGFwcHJvdmVkIHN0YXRlLCBzbyB5b3UgY2FuJ3QgY29uZmlndXJlIGl0IGFzIGEgZGVmYXVsdCBtZXNzYWdlLlxuICAgICAqXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL3JldGVudGlvbm1lc3NhZ2luZy9tZXNzYWdlbm90YXBwcm92ZWRlcnJvciBNZXNzYWdlTm90QXBwcm92ZWRFcnJvcn1cbiAgICAgKi9cbiAgICBNRVNTQUdFX05PVF9BUFBST1ZFRCA9IDQwMzAwMTcsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgaW1hZ2UgaXNuJ3QgaW4gdGhlIGFwcHJvdmVkIHN0YXRlLCBzbyB5b3UgY2FuJ3QgY29uZmlndXJlIGl0IGFzIHBhcnQgb2YgYSBkZWZhdWx0IG1lc3NhZ2UuXG4gICAgICpcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL2ltYWdlbm90YXBwcm92ZWRlcnJvciBJbWFnZU5vdEFwcHJvdmVkRXJyb3J9XG4gICAgICovXG4gICAgSU1BR0VfTk9UX0FQUFJPVkVEID0gNDAzMDAxOCxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIHRoZSBpbWFnZSBpcyBjdXJyZW50bHkgaW4gdXNlIGFzIHBhcnQgb2YgYSBtZXNzYWdlLCBzbyB5b3UgY2FuJ3QgZGVsZXRlIGl0LlxuICAgICAqXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL3JldGVudGlvbm1lc3NhZ2luZy9pbWFnZWludXNlZXJyb3IgSW1hZ2VJblVzZUVycm9yfVxuICAgICAqL1xuICAgIElNQUdFX0lOX1VTRSA9IDQwMzAwMTksXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGF0IHBhc3NpbmcgYSBwZXJmb3JtYW5jZSB0ZXN0IGlzIHJlcXVpcmVkIGJlZm9yZSB5b3UgY2FuIHNldCBhIFVSTCBmb3IgdGhlIHByb2R1Y3Rpb24gZW52aXJvbm1lbnQuXG4gICAgICpcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL2ZvcmJpZGRlbm5vcGFzc2luZ3Rlc3RlcnJvciBGb3JiaWRkZW5Ob1Bhc3NpbmdUZXN0RXJyb3J9XG4gICAgICovXG4gICAgRk9SQklEREVOX05PX1BBU1NJTkdfVEVTVCA9IDQwMzAwMjYsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgQXBwIFN0b3JlIGFjY291bnQgd2Fzbid0IGZvdW5kLlxuICAgICAqXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2FjY291bnRub3Rmb3VuZGVycm9yIEFjY291bnROb3RGb3VuZEVycm9yfVxuICAgICAqL1xuICAgIEFDQ09VTlRfTk9UX0ZPVU5EID0gNDA0MDAwMSxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHJlc3BvbnNlIHRoYXQgaW5kaWNhdGVzIHRoZSBBcHAgU3RvcmUgYWNjb3VudCB3YXNu4oCZdCBmb3VuZCwgYnV0IHlvdSBjYW4gdHJ5IGFnYWluLlxuICAgICAqIFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9hY2NvdW50bm90Zm91bmRyZXRyeWFibGVlcnJvciBBY2NvdW50Tm90Rm91bmRSZXRyeWFibGVFcnJvcn1cbiAgICAgKi9cbiAgICBBQ0NPVU5UX05PVF9GT1VORF9SRVRSWUFCTEUgPSA0MDQwMDAyLFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgdGhlIGFwcCB3YXNu4oCZdCBmb3VuZC5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvYXBwbm90Zm91bmRlcnJvciBBcHBOb3RGb3VuZEVycm9yfVxuICAgICAqL1xuICAgIEFQUF9OT1RfRk9VTkQgPSA0MDQwMDAzLFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgcmVzcG9uc2UgdGhhdCBpbmRpY2F0ZXMgdGhlIGFwcCB3YXNu4oCZdCBmb3VuZCwgYnV0IHlvdSBjYW4gdHJ5IGFnYWluLlxuICAgICAqIFxuICAgICAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS9hcHBub3Rmb3VuZHJldHJ5YWJsZWVycm9yIEFwcE5vdEZvdW5kUmV0cnlhYmxlRXJyb3J9XG4gICAgICovXG4gICAgQVBQX05PVF9GT1VORF9SRVRSWUFCTEUgPSA0MDQwMDA0LFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgYW4gb3JpZ2luYWwgdHJhbnNhY3Rpb24gaWRlbnRpZmllciB3YXNuJ3QgZm91bmQuXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL29yaWdpbmFsdHJhbnNhY3Rpb25pZG5vdGZvdW5kZXJyb3IgT3JpZ2luYWxUcmFuc2FjdGlvbklkTm90Rm91bmRFcnJvcn1cbiAgICAgKi9cbiAgICBPUklHSU5BTF9UUkFOU0FDVElPTl9JRF9OT1RfRk9VTkQgPSA0MDQwMDA1LFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgcmVzcG9uc2UgdGhhdCBpbmRpY2F0ZXMgdGhlIG9yaWdpbmFsIHRyYW5zYWN0aW9uIGlkZW50aWZpZXIgd2FzbuKAmXQgZm91bmQsIGJ1dCB5b3UgY2FuIHRyeSBhZ2Fpbi5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvb3JpZ2luYWx0cmFuc2FjdGlvbmlkbm90Zm91bmRyZXRyeWFibGVlcnJvciBPcmlnaW5hbFRyYW5zYWN0aW9uSWROb3RGb3VuZFJldHJ5YWJsZUVycm9yfVxuICAgICAqL1xuICAgIE9SSUdJTkFMX1RSQU5TQUNUSU9OX0lEX05PVF9GT1VORF9SRVRSWUFCTEUgPSA0MDQwMDA2LFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgdGhhdCB0aGUgQXBwIFN0b3JlIHNlcnZlciBjb3VsZG7igJl0IGZpbmQgYSBub3RpZmljYXRpb25zIFVSTCBmb3IgeW91ciBhcHAgaW4gdGhpcyBlbnZpcm9ubWVudC5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvc2VydmVybm90aWZpY2F0aW9udXJsbm90Zm91bmRlcnJvciBTZXJ2ZXJOb3RpZmljYXRpb25VcmxOb3RGb3VuZEVycm9yfVxuICAgICAqL1xuICAgIFNFUlZFUl9OT1RJRklDQVRJT05fVVJMX05PVF9GT1VORCA9IDQwNDAwMDcsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGF0IHRoZSB0ZXN0IG5vdGlmaWNhdGlvbiB0b2tlbiBpcyBleHBpcmVkIG9yIHRoZSB0ZXN0IG5vdGlmaWNhdGlvbiBzdGF0dXMgaXNu4oCZdCBhdmFpbGFibGUuXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL3Rlc3Rub3RpZmljYXRpb25ub3Rmb3VuZGVycm9yIFRlc3ROb3RpZmljYXRpb25Ob3RGb3VuZEVycm9yfVxuICAgICAqL1xuICAgIFRFU1RfTk9USUZJQ0FUSU9OX05PVF9GT1VORCA9IDQwNDAwMDgsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgc2VydmVyIGRpZG4ndCBmaW5kIGEgc3Vic2NyaXB0aW9uLXJlbmV3YWwtZGF0ZSBleHRlbnNpb24gcmVxdWVzdCBmb3IgdGhlIHJlcXVlc3QgaWRlbnRpZmllciBhbmQgcHJvZHVjdCBpZGVudGlmaWVyIHlvdSBwcm92aWRlZC5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvc3RhdHVzcmVxdWVzdG5vdGZvdW5kZXJyb3IgU3RhdHVzUmVxdWVzdE5vdEZvdW5kRXJyb3J9XG4gICAgICovXG4gICAgU1RBVFVTX1JFUVVFU1RfTk9UX0ZPVU5EID0gNDA0MDAwOSxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIGEgdHJhbnNhY3Rpb24gaWRlbnRpZmllciB3YXNuJ3QgZm91bmQuXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL3RyYW5zYWN0aW9uaWRub3Rmb3VuZGVycm9yIFRyYW5zYWN0aW9uSWROb3RGb3VuZEVycm9yfVxuICAgICAqL1xuICAgIFRSQU5TQUNUSU9OX0lEX05PVF9GT1VORCA9IDQwNDAwMTAsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGUgc3lzdGVtIGNhbid0IGZpbmQgdGhlIGltYWdlIGlkZW50aWZpZXIuXG4gICAgICpcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL2ltYWdlbm90Zm91bmRlcnJvciBJbWFnZU5vdEZvdW5kRXJyb3J9XG4gICAgICovXG4gICAgSU1BR0VfTk9UX0ZPVU5EID0gNDA0MDAxNCxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIHRoZSBzeXN0ZW0gY2FuJ3QgZmluZCB0aGUgbWVzc2FnZSBpZGVudGlmaWVyLlxuICAgICAqXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL3JldGVudGlvbm1lc3NhZ2luZy9tZXNzYWdlbm90Zm91bmRlcnJvciBNZXNzYWdlTm90Rm91bmRFcnJvcn1cbiAgICAgKi9cbiAgICBNRVNTQUdFX05PVF9GT1VORCA9IDQwNDAwMTUsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGUgQVBJIHJldHVybnMgaWYgdGhlIHNlcnZpY2UgY2Fu4oCZdCBmaW5kIHRoZSBzcGVjaWZpZWQgdGVzdCBydW4uXG4gICAgICpcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL3BlcmZvcm1hbmNldGVzdHJ1bm5vdGZvdW5kZXJyb3IgUGVyZm9ybWFuY2VUZXN0UnVuTm90Rm91bmRFcnJvcn1cbiAgICAgKi9cbiAgICBQRVJGT1JNQU5DRV9URVNUX1JVTl9OT1RfRk9VTkQgPSA0MDQwMDE4LFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgcmVzcG9uc2UgdGhhdCBpbmRpY2F0ZXMgYW4gYXBwIHRyYW5zYWN0aW9uIGRvZXNu4oCZdCBleGlzdCBmb3IgdGhlIHNwZWNpZmllZCBjdXN0b21lci5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvYXBwdHJhbnNhY3Rpb25kb2Vzbm90ZXhpc3RlcnJvciBBcHBUcmFuc2FjdGlvbkRvZXNOb3RFeGlzdEVycm9yfVxuICAgICAqL1xuICAgIEFQUF9UUkFOU0FDVElPTl9ET0VTX05PVF9FWElTVF9FUlJPUiA9IDQwNDAwMTksXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyBhIGRlZmF1bHQgbWVzc2FnZSBpc27igJl0IGNvbmZpZ3VyZWQuXG4gICAgICpcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL2RlZmF1bHRtZXNzYWdlbm90Zm91bmRlcnJvciBEZWZhdWx0TWVzc2FnZU5vdEZvdW5kRXJyb3J9XG4gICAgICovXG4gICAgREVGQVVMVF9NRVNTQUdFX05PVF9GT1VORCA9IDQwNDAwMjAsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciB0aGF0IGluZGljYXRlcyB0aGF0IHRoZSBVUkwgZm9yIHlvdXIgZW5kcG9pbnQgaXNu4oCZdCBjb25maWd1cmVkLlxuICAgICAqXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL3JldGVudGlvbm1lc3NhZ2luZy9yZWFsdGltZXVybG5vdGZvdW5kZXJyb3IgUmVhbHRpbWVVcmxOb3RGb3VuZEVycm9yfVxuICAgICAqL1xuICAgIFJFQUxUSU1FX1VSTF9OT1RfRk9VTkQgPSA0MDQwMDIxLFxuXG4gICAgLyoqXG4gICAgICogQW4gZXJyb3IgdGhhdCBpbmRpY2F0ZXMgdGhlIGltYWdlIGlkZW50aWZpZXIgYWxyZWFkeSBleGlzdHMuXG4gICAgICpcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL2ltYWdlYWxyZWFkeWV4aXN0c2Vycm9yIEltYWdlQWxyZWFkeUV4aXN0c0Vycm9yfVxuICAgICAqL1xuICAgIElNQUdFX0FMUkVBRFlfRVhJU1RTID0gNDA5MDAwMCxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIHRoZSBtZXNzYWdlIGlkZW50aWZpZXIgYWxyZWFkeSBleGlzdHMuXG4gICAgICpcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL21lc3NhZ2VhbHJlYWR5ZXhpc3RzZXJyb3IgTWVzc2FnZUFscmVhZHlFeGlzdHNFcnJvcn1cbiAgICAgKi9cbiAgICBNRVNTQUdFX0FMUkVBRFlfRVhJU1RTID0gNDA5MDAwMSxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIHRoYXQgdGhlIHJlcXVlc3QgZXhjZWVkZWQgdGhlIHJhdGUgbGltaXQuXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL3JhdGVsaW1pdGV4Y2VlZGVkZXJyb3IgUmF0ZUxpbWl0RXhjZWVkZWRFcnJvcn1cbiAgICAgKi9cbiAgICBSQVRFX0xJTUlUX0VYQ0VFREVEID0gNDI5MDAwMCxcblxuICAgIC8qKlxuICAgICAqIEFuIGVycm9yIHRoYXQgaW5kaWNhdGVzIGEgZ2VuZXJhbCBpbnRlcm5hbCBlcnJvci5cbiAgICAgKiBcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYXBwc3RvcmVzZXJ2ZXJhcGkvZ2VuZXJhbGludGVybmFsZXJyb3IgR2VuZXJhbEludGVybmFsRXJyb3J9XG4gICAgICovXG4gICAgR0VORVJBTF9JTlRFUk5BTCA9IDUwMDAwMDAsXG5cbiAgICAvKipcbiAgICAgKiBBbiBlcnJvciByZXNwb25zZSB0aGF0IGluZGljYXRlcyBhbiB1bmtub3duIGVycm9yIG9jY3VycmVkLCBidXQgeW91IGNhbiB0cnkgYWdhaW4uXG4gICAgICogXG4gICAgICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL2FwcHN0b3Jlc2VydmVyYXBpL2dlbmVyYWxpbnRlcm5hbHJldHJ5YWJsZWVycm9yIEdlbmVyYWxJbnRlcm5hbFJldHJ5YWJsZUVycm9yfVxuICAgICAqL1xuICAgIEdFTkVSQUxfSU5URVJOQUxfUkVUUllBQkxFID0gNTAwMDAwMSxcbn1cblxuZXhwb3J0IGVudW0gR2V0VHJhbnNhY3Rpb25IaXN0b3J5VmVyc2lvbiB7XG4gICAgLyoqXG4gICAgICogQGRlcHJlY2F0ZWRcbiAgICAgKi9cbiAgICBWMSA9IFwidjFcIixcbiAgICBWMiA9IFwidjJcIixcbn1cbiJdfQ==