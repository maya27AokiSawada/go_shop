import { SendAttemptItem, SendAttemptItemValidator } from "./SendAttemptItem";
import { Validator } from "./Validator";
/**
 * The App Store server notification history record, including the signed notification payload and the result of the server’s first send attempt.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/notificationhistoryresponseitem notificationHistoryResponseItem}
 */
export interface NotificationHistoryResponseItem {
    /**
     * A cryptographically signed payload, in JSON Web Signature (JWS) format, containing the response body for a version 2 notification.
     *
     * {@link https://developer.apple.com/documentation/appstoreservernotifications/signedpayload signedPayload}
     **/
    signedPayload?: string;
    /**
     * An array of information the App Store server records for its attempts to send a notification to your server. The maximum number of entries in the array is six.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/sendattemptitem sendAttemptItem}
     **/
    sendAttempts?: SendAttemptItem[];
}
export declare class NotificationHistoryResponseItemValidator implements Validator<NotificationHistoryResponseItem> {
    static readonly sendAttemptItemValidator: SendAttemptItemValidator;
    validate(obj: any): obj is NotificationHistoryResponseItem;
}
