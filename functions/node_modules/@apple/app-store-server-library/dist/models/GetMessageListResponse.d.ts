import { GetMessageListResponseItem, GetMessageListResponseItemValidator } from "./GetMessageListResponseItem";
import { Validator } from "./Validator";
/**
 * A response that contains status information for all messages.
 *
 * {@link https://developer.apple.com/documentation/retentionmessaging/getmessagelistresponse GetMessageListResponse}
 */
export interface GetMessageListResponse {
    /**
     * An array of all message identifiers and their message state.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/getmessagelistresponseitem messageIdentifiers}
     **/
    messageIdentifiers?: GetMessageListResponseItem[];
}
export declare class GetMessageListResponseValidator implements Validator<GetMessageListResponse> {
    static readonly getMessageListResponseItemValidator: GetMessageListResponseItemValidator;
    validate(obj: any): obj is GetMessageListResponse;
}
