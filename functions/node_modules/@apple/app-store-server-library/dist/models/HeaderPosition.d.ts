import { StringValidator } from "./Validator";
/**
 * The position where the header text appears in a message.
 *
 * {@link https://developer.apple.com/documentation/retentionmessaging/headerposition headerPosition}
 */
export declare enum HeaderPosition {
    ABOVE_BODY = "ABOVE_BODY",
    ABOVE_IMAGE = "ABOVE_IMAGE"
}
export declare class HeaderPositionValidator extends StringValidator {
}
