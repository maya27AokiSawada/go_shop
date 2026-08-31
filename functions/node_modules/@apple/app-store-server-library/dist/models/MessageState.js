"use strict";
// Copyright (c) 2025 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.MessageStateValidator = exports.MessageState = void 0;
const Validator_1 = require("./Validator");
/**
 * The approval state of a message.
 *
 * {@link https://developer.apple.com/documentation/retentionmessaging/messagestate messageState}
 */
var MessageState;
(function (MessageState) {
    MessageState["PENDING_REVIEW"] = "PENDING_REVIEW";
    MessageState["APPROVED"] = "APPROVED";
    MessageState["REJECTED"] = "REJECTED";
})(MessageState || (exports.MessageState = MessageState = {}));
class MessageStateValidator extends Validator_1.StringValidator {
}
exports.MessageStateValidator = MessageStateValidator;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiTWVzc2FnZVN0YXRlLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vbW9kZWxzL01lc3NhZ2VTdGF0ZS50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiO0FBQUEsNERBQTREOzs7QUFFNUQsMkNBQThDO0FBRTlDOzs7O0dBSUc7QUFDSCxJQUFZLFlBSVg7QUFKRCxXQUFZLFlBQVk7SUFDcEIsaURBQWlDLENBQUE7SUFDakMscUNBQXFCLENBQUE7SUFDckIscUNBQXFCLENBQUE7QUFDekIsQ0FBQyxFQUpXLFlBQVksNEJBQVosWUFBWSxRQUl2QjtBQUVELE1BQWEscUJBQXNCLFNBQVEsMkJBQWU7Q0FBRztBQUE3RCxzREFBNkQiLCJzb3VyY2VzQ29udGVudCI6WyIvLyBDb3B5cmlnaHQgKGMpIDIwMjUgQXBwbGUgSW5jLiBMaWNlbnNlZCB1bmRlciBNSVQgTGljZW5zZS5cblxuaW1wb3J0IHsgU3RyaW5nVmFsaWRhdG9yIH0gZnJvbSBcIi4vVmFsaWRhdG9yXCI7XG5cbi8qKlxuICogVGhlIGFwcHJvdmFsIHN0YXRlIG9mIGEgbWVzc2FnZS5cbiAqXG4gKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vcmV0ZW50aW9ubWVzc2FnaW5nL21lc3NhZ2VzdGF0ZSBtZXNzYWdlU3RhdGV9XG4gKi9cbmV4cG9ydCBlbnVtIE1lc3NhZ2VTdGF0ZSB7XG4gICAgUEVORElOR19SRVZJRVcgPSBcIlBFTkRJTkdfUkVWSUVXXCIsXG4gICAgQVBQUk9WRUQgPSBcIkFQUFJPVkVEXCIsXG4gICAgUkVKRUNURUQgPSBcIlJFSkVDVEVEXCIsXG59XG5cbmV4cG9ydCBjbGFzcyBNZXNzYWdlU3RhdGVWYWxpZGF0b3IgZXh0ZW5kcyBTdHJpbmdWYWxpZGF0b3Ige31cbiJdfQ==