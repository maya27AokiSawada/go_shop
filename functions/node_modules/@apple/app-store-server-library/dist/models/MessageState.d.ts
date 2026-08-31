import { StringValidator } from "./Validator";
/**
 * The approval state of a message.
 *
 * {@link https://developer.apple.com/documentation/retentionmessaging/messagestate messageState}
 */
export declare enum MessageState {
    PENDING_REVIEW = "PENDING_REVIEW",
    APPROVED = "APPROVED",
    REJECTED = "REJECTED"
}
export declare class MessageStateValidator extends StringValidator {
}
