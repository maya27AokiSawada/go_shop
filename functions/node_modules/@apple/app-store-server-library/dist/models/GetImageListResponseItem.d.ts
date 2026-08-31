import { ImageSize, ImageSizeValidator } from "./ImageSize";
import { ImageState, ImageStateValidator } from "./ImageState";
import { Validator } from "./Validator";
/**
 * An image identifier and state information for an image.
 *
 * {@link https://developer.apple.com/documentation/retentionmessaging/getimagelistresponseitem GetImageListResponseItem}
 */
export interface GetImageListResponseItem {
    /**
     * The identifier of the image.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/imageidentifier imageIdentifier}
     **/
    imageIdentifier?: string;
    /**
     * The current state of the image.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/imagestate imageState}
     **/
    imageState?: ImageState | string;
    /**
     * The size of the image.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/imagesize imageSize}
     **/
    imageSize?: ImageSize | string;
}
export declare class GetImageListResponseItemValidator implements Validator<GetImageListResponseItem> {
    static readonly imageStateValidator: ImageStateValidator;
    static readonly imageSizeValidator: ImageSizeValidator;
    validate(obj: any): obj is GetImageListResponseItem;
}
