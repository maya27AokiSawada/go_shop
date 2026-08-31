"use strict";
// Copyright (c) 2026 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.ImageSizeValidator = exports.ImageSize = void 0;
const Validator_1 = require("./Validator");
/**
 * The size of an image.
 *
 * {@link https://developer.apple.com/documentation/retentionmessaging/imagesize imageSize}
 */
var ImageSize;
(function (ImageSize) {
    ImageSize["FULL_SIZE"] = "FULL_SIZE";
    ImageSize["BULLET_POINT"] = "BULLET_POINT";
})(ImageSize || (exports.ImageSize = ImageSize = {}));
class ImageSizeValidator extends Validator_1.StringValidator {
}
exports.ImageSizeValidator = ImageSizeValidator;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiSW1hZ2VTaXplLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vbW9kZWxzL0ltYWdlU2l6ZS50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiO0FBQUEsNERBQTREOzs7QUFFNUQsMkNBQThDO0FBRTlDOzs7O0dBSUc7QUFDSCxJQUFZLFNBR1g7QUFIRCxXQUFZLFNBQVM7SUFDakIsb0NBQXVCLENBQUE7SUFDdkIsMENBQTZCLENBQUE7QUFDakMsQ0FBQyxFQUhXLFNBQVMseUJBQVQsU0FBUyxRQUdwQjtBQUVELE1BQWEsa0JBQW1CLFNBQVEsMkJBQWU7Q0FBRztBQUExRCxnREFBMEQiLCJzb3VyY2VzQ29udGVudCI6WyIvLyBDb3B5cmlnaHQgKGMpIDIwMjYgQXBwbGUgSW5jLiBMaWNlbnNlZCB1bmRlciBNSVQgTGljZW5zZS5cblxuaW1wb3J0IHsgU3RyaW5nVmFsaWRhdG9yIH0gZnJvbSBcIi4vVmFsaWRhdG9yXCI7XG5cbi8qKlxuICogVGhlIHNpemUgb2YgYW4gaW1hZ2UuXG4gKlxuICoge0BsaW5rIGh0dHBzOi8vZGV2ZWxvcGVyLmFwcGxlLmNvbS9kb2N1bWVudGF0aW9uL3JldGVudGlvbm1lc3NhZ2luZy9pbWFnZXNpemUgaW1hZ2VTaXplfVxuICovXG5leHBvcnQgZW51bSBJbWFnZVNpemUge1xuICAgIEZVTExfU0laRSA9IFwiRlVMTF9TSVpFXCIsXG4gICAgQlVMTEVUX1BPSU5UID0gXCJCVUxMRVRfUE9JTlRcIixcbn1cblxuZXhwb3J0IGNsYXNzIEltYWdlU2l6ZVZhbGlkYXRvciBleHRlbmRzIFN0cmluZ1ZhbGlkYXRvciB7fVxuIl19