import { NotificationHistoryResponseItem } from "./NotificationHistoryResponseItem";
import { Validator } from "./Validator";
/**
 * A response that contains the App Store Server Notifications history for your app.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/notificationhistoryresponse NotificationHistoryResponse}
 */
export interface NotificationHistoryResponse {
    /**
     * A pagination token that you return to the endpoint on a subsequent call to receive the next set of results.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/paginationtoken paginationToken}
     **/
    paginationToken?: string;
    /**
     * A Boolean value indicating whether the App Store has more transaction data.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/hasmore hasMore}
     **/
    hasMore?: boolean;
    /**
     * An array of App Store server notification history records.
     *
     * {@link https://developer.apple.com/documentation/appstoreserverapi/notificationhistoryresponseitem notificationHistoryResponseItem}
     **/
    notificationHistory?: NotificationHistoryResponseItem[];
}
export declare class NotificationHistoryResponseValidator implements Validator<NotificationHistoryResponse> {
    static readonly notificationHistoryResponseItemValidator: NotificationHistoryResponseValidator;
    validate(obj: any): obj is NotificationHistoryResponse;
}
