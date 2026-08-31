"use strict";
// Copyright (c) 2023 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.TypeValidator = exports.Type = void 0;
const Validator_1 = require("./Validator");
/**
 * The type of in-app purchase products you can offer in your app.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/type type}
 */
var Type;
(function (Type) {
    Type["AUTO_RENEWABLE_SUBSCRIPTION"] = "Auto-Renewable Subscription";
    Type["NON_CONSUMABLE"] = "Non-Consumable";
    Type["CONSUMABLE"] = "Consumable";
    Type["NON_RENEWING_SUBSCRIPTION"] = "Non-Renewing Subscription";
})(Type || (exports.Type = Type = {}));
class TypeValidator extends Validator_1.StringValidator {
}
exports.TypeValidator = TypeValidator;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiVHlwZS5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uL21vZGVscy9UeXBlLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiI7QUFBQSw0REFBNEQ7OztBQUU1RCwyQ0FBOEM7QUFFOUM7Ozs7R0FJRztBQUNILElBQVksSUFLWDtBQUxELFdBQVksSUFBSTtJQUNaLG1FQUEyRCxDQUFBO0lBQzNELHlDQUFpQyxDQUFBO0lBQ2pDLGlDQUF5QixDQUFBO0lBQ3pCLCtEQUFzRCxDQUFBO0FBQzFELENBQUMsRUFMVyxJQUFJLG9CQUFKLElBQUksUUFLZjtBQUVELE1BQWEsYUFBYyxTQUFRLDJCQUFlO0NBQUc7QUFBckQsc0NBQXFEIiwic291cmNlc0NvbnRlbnQiOlsiLy8gQ29weXJpZ2h0IChjKSAyMDIzIEFwcGxlIEluYy4gTGljZW5zZWQgdW5kZXIgTUlUIExpY2Vuc2UuXG5cbmltcG9ydCB7IFN0cmluZ1ZhbGlkYXRvciB9IGZyb20gXCIuL1ZhbGlkYXRvclwiO1xuXG4vKipcbiAqIFRoZSB0eXBlIG9mIGluLWFwcCBwdXJjaGFzZSBwcm9kdWN0cyB5b3UgY2FuIG9mZmVyIGluIHlvdXIgYXBwLlxuICpcbiAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hcHBzdG9yZXNlcnZlcmFwaS90eXBlIHR5cGV9XG4gKi9cbmV4cG9ydCBlbnVtIFR5cGUge1xuICAgIEFVVE9fUkVORVdBQkxFX1NVQlNDUklQVElPTiA9IFwiQXV0by1SZW5ld2FibGUgU3Vic2NyaXB0aW9uXCIsXG4gICAgTk9OX0NPTlNVTUFCTEUgPSBcIk5vbi1Db25zdW1hYmxlXCIsXG4gICAgQ09OU1VNQUJMRSA9IFwiQ29uc3VtYWJsZVwiLFxuICAgIE5PTl9SRU5FV0lOR19TVUJTQ1JJUFRJT04gPVwiTm9uLVJlbmV3aW5nIFN1YnNjcmlwdGlvblwiLFxufVxuXG5leHBvcnQgY2xhc3MgVHlwZVZhbGlkYXRvciBleHRlbmRzIFN0cmluZ1ZhbGlkYXRvciB7fSJdfQ==