"use strict";
// Copyright (c) 2025 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.ImageStateValidator = exports.ImageState = void 0;
const Validator_1 = require("./Validator");
/**
 * The approval state of an image.
 *
 * {@link https://developer.apple.com/documentation/retentionmessaging/imagestate imageState}
 */
var ImageState;
(function (ImageState) {
    ImageState["PENDING_REVIEW"] = "PENDING_REVIEW";
    ImageState["APPROVED"] = "APPROVED";
    ImageState["REJECTED"] = "REJECTED";
})(ImageState || (exports.ImageState = ImageState = {}));
class ImageStateValidator extends Validator_1.StringValidator {
}
exports.ImageStateValidator = ImageStateValidator;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiSW1hZ2VTdGF0ZS5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uL21vZGVscy9JbWFnZVN0YXRlLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiI7QUFBQSw0REFBNEQ7OztBQUU1RCwyQ0FBOEM7QUFFOUM7Ozs7R0FJRztBQUNILElBQVksVUFJWDtBQUpELFdBQVksVUFBVTtJQUNsQiwrQ0FBaUMsQ0FBQTtJQUNqQyxtQ0FBcUIsQ0FBQTtJQUNyQixtQ0FBcUIsQ0FBQTtBQUN6QixDQUFDLEVBSlcsVUFBVSwwQkFBVixVQUFVLFFBSXJCO0FBRUQsTUFBYSxtQkFBb0IsU0FBUSwyQkFBZTtDQUFHO0FBQTNELGtEQUEyRCIsInNvdXJjZXNDb250ZW50IjpbIi8vIENvcHlyaWdodCAoYykgMjAyNSBBcHBsZSBJbmMuIExpY2Vuc2VkIHVuZGVyIE1JVCBMaWNlbnNlLlxuXG5pbXBvcnQgeyBTdHJpbmdWYWxpZGF0b3IgfSBmcm9tIFwiLi9WYWxpZGF0b3JcIjtcblxuLyoqXG4gKiBUaGUgYXBwcm92YWwgc3RhdGUgb2YgYW4gaW1hZ2UuXG4gKlxuICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL3JldGVudGlvbm1lc3NhZ2luZy9pbWFnZXN0YXRlIGltYWdlU3RhdGV9XG4gKi9cbmV4cG9ydCBlbnVtIEltYWdlU3RhdGUge1xuICAgIFBFTkRJTkdfUkVWSUVXID0gXCJQRU5ESU5HX1JFVklFV1wiLFxuICAgIEFQUFJPVkVEID0gXCJBUFBST1ZFRFwiLFxuICAgIFJFSkVDVEVEID0gXCJSRUpFQ1RFRFwiLFxufVxuXG5leHBvcnQgY2xhc3MgSW1hZ2VTdGF0ZVZhbGlkYXRvciBleHRlbmRzIFN0cmluZ1ZhbGlkYXRvciB7fVxuIl19