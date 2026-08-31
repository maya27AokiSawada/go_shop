import { SendAttemptResult, SendAttemptResultValidator } from "./SendAttemptResult";
import { Validator } from "./Validator";
/**
 * The success or error information and the date the App Store server records when it attempts to send a server notification to your server.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/sendattemptitem sendAttemptItem}
 */
export interface SendAttemptItem {
    /**
     * The date the App Store server attempts to send a notification.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/attemptdate attemptDate}
     **/
    attemptDate?: number;
    /**
     * The success or error information the App Store server records when it attempts to send an App Store server notification to your server.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/sendattemptresult sendAttemptResult}
     **/
    sendAttemptResult?: SendAttemptResult | string;
}
export declare class SendAttemptItemValidator implements Validator<SendAttemptItem> {
    static readonly sendAttemptResultValidator: SendAttemptResultValidator;
    validate(obj: any): obj is SendAttemptItem;
}
