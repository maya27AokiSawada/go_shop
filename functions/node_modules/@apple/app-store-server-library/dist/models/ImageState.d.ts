import { StringValidator } from "./Validator";
/**
 * The approval state of an image.
 *
 * {@link https://developer.apple.com/documentation/retentionmessaging/imagestate imageState}
 */
export declare enum ImageState {
    PENDING_REVIEW = "PENDING_REVIEW",
    APPROVED = "APPROVED",
    REJECTED = "REJECTED"
}
export declare class ImageStateValidator extends StringValidator {
}
