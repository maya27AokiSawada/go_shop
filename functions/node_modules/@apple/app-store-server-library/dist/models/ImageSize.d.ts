import { StringValidator } from "./Validator";
/**
 * The size of an image.
 *
 * {@link https://developer.apple.com/documentation/retentionmessaging/imagesize imageSize}
 */
export declare enum ImageSize {
    FULL_SIZE = "FULL_SIZE",
    BULLET_POINT = "BULLET_POINT"
}
export declare class ImageSizeValidator extends StringValidator {
}
