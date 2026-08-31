import { MessageState, MessageStateValidator } from "./MessageState";
import { Validator } from "./Validator";
/**
 * A message identifier and status information for a message.
 *
 * {@link https://developer.apple.com/documentation/retentionmessaging/getmessagelistresponseitem GetMessageListResponseItem}
 */
export interface GetMessageListResponseItem {
    /**
     * The identifier of the message.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/messageidentifier messageIdentifier}
     **/
    messageIdentifier?: string;
    /**
     * The current state of the message.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/messagestate messageState}
     **/
    messageState?: MessageState | string;
}
export declare class GetMessageListResponseItemValidator implements Validator<GetMessageListResponseItem> {
    static readonly messageStateValidator: MessageStateValidator;
    validate(obj: any): obj is GetMessageListResponseItem;
}
