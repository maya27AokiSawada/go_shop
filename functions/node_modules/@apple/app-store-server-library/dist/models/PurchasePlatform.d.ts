import { StringValidator } from "./Validator";
/**
 * Values that represent Apple platforms.
 *
 * {@link https://developer.apple.com/documentation/storekit/appstore/platform AppStore.Platform}
 */
export declare enum PurchasePlatform {
    IOS = "iOS",
    MAC_OS = "macOS",
    TV_OS = "tvOS",
    VISION_OS = "visionOS"
}
export declare class PurchasePlatformValidator extends StringValidator {
}
