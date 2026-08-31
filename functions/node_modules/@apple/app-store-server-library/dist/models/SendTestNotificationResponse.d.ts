import { Validator } from "./Validator";
/**
 * A response that contains the test notification token.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/sendtestnotificationresponse SendTestNotificationResponse}
 */
export interface SendTestNotificationResponse {
    /**
     * A unique identifier for a notification test that the App Store server sends to your server.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/testnotificationtoken testNotificationToken}
     **/
    testNotificationToken?: string;
}
export declare class SendTestNotificationResponseValidator implements Validator<SendTestNotificationResponse> {
    validate(obj: any): obj is SendTestNotificationResponse;
}
