import { GetImageListResponseItem, GetImageListResponseItemValidator } from "./GetImageListResponseItem";
import { Validator } from "./Validator";
/**
 * A response that contains status information for all images.
 *
 * {@link https://developer.apple.com/documentation/retentionmessaging/getimagelistresponse GetImageListResponse}
 */
export interface GetImageListResponse {
    /**
     * An array of all image identifiers and their image state.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/getimagelistresponseitem GetImageListResponseItem}
     **/
    imageIdentifiers?: GetImageListResponseItem[];
}
export declare class GetImageListResponseValidator implements Validator<GetImageListResponse> {
    static readonly getImageListResponseItemValidator: GetImageListResponseItemValidator;
    validate(obj: any): obj is GetImageListResponse;
}
