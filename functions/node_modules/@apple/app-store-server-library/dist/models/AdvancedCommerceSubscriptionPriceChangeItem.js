"use strict";
// Copyright (c) 2026 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdvancedCommerceSubscriptionPriceChangeItemValidator = void 0;
const helper_validation_utils_1 = require("../helper_validation_utils");
class AdvancedCommerceSubscriptionPriceChangeItemValidator {
    validate(obj) {
        if (!(typeof obj['SKU'] === "string" || obj['SKU'] instanceof String)) {
            return false;
        }
        if (!helper_validation_utils_1.HelperValidationUtils.validateSku(obj['SKU'])) {
            return false;
        }
        if (!(typeof obj['price'] === "number")) {
            return false;
        }
        if (typeof obj['dependentSKUs'] !== 'undefined') {
            if (!helper_validation_utils_1.HelperValidationUtils.validateItems(obj['dependentSKUs'])) {
                return false;
            }
            for (const sku of obj['dependentSKUs']) {
                if (!(typeof sku === "string" || sku instanceof String)) {
                    return false;
                }
                if (!helper_validation_utils_1.HelperValidationUtils.validateSku(sku)) {
                    return false;
                }
            }
        }
        return true;
    }
}
exports.AdvancedCommerceSubscriptionPriceChangeItemValidator = AdvancedCommerceSubscriptionPriceChangeItemValidator;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvblByaWNlQ2hhbmdlSXRlbS5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uL21vZGVscy9BZHZhbmNlZENvbW1lcmNlU3Vic2NyaXB0aW9uUHJpY2VDaGFuZ2VJdGVtLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiI7QUFBQSw0REFBNEQ7OztBQUU1RCx3RUFBa0U7QUFxQmxFLE1BQWEsb0RBQW9EO0lBQzdELFFBQVEsQ0FBQyxHQUFRO1FBQ2IsSUFBSSxDQUFDLENBQUMsT0FBTyxHQUFHLENBQUMsS0FBSyxDQUFDLEtBQUssUUFBUSxJQUFJLEdBQUcsQ0FBQyxLQUFLLENBQUMsWUFBWSxNQUFNLENBQUMsRUFBRSxDQUFDO1lBQ3BFLE9BQU8sS0FBSyxDQUFBO1FBQ2hCLENBQUM7UUFDRCxJQUFJLENBQUMsK0NBQXFCLENBQUMsV0FBVyxDQUFDLEdBQUcsQ0FBQyxLQUFLLENBQUMsQ0FBQyxFQUFFLENBQUM7WUFDakQsT0FBTyxLQUFLLENBQUE7UUFDaEIsQ0FBQztRQUNELElBQUksQ0FBQyxDQUFDLE9BQU8sR0FBRyxDQUFDLE9BQU8sQ0FBQyxLQUFLLFFBQVEsQ0FBQyxFQUFFLENBQUM7WUFDdEMsT0FBTyxLQUFLLENBQUE7UUFDaEIsQ0FBQztRQUNELElBQUksT0FBTyxHQUFHLENBQUMsZUFBZSxDQUFDLEtBQUssV0FBVyxFQUFFLENBQUM7WUFDOUMsSUFBSSxDQUFDLCtDQUFxQixDQUFDLGFBQWEsQ0FBQyxHQUFHLENBQUMsZUFBZSxDQUFDLENBQUMsRUFBRSxDQUFDO2dCQUM3RCxPQUFPLEtBQUssQ0FBQTtZQUNoQixDQUFDO1lBQ0QsS0FBSyxNQUFNLEdBQUcsSUFBSSxHQUFHLENBQUMsZUFBZSxDQUFDLEVBQUUsQ0FBQztnQkFDckMsSUFBSSxDQUFDLENBQUMsT0FBTyxHQUFHLEtBQUssUUFBUSxJQUFJLEdBQUcsWUFBWSxNQUFNLENBQUMsRUFBRSxDQUFDO29CQUN0RCxPQUFPLEtBQUssQ0FBQTtnQkFDaEIsQ0FBQztnQkFDRCxJQUFJLENBQUMsK0NBQXFCLENBQUMsV0FBVyxDQUFDLEdBQUcsQ0FBQyxFQUFFLENBQUM7b0JBQzFDLE9BQU8sS0FBSyxDQUFBO2dCQUNoQixDQUFDO1lBQ0wsQ0FBQztRQUNMLENBQUM7UUFDRCxPQUFPLElBQUksQ0FBQTtJQUNmLENBQUM7Q0FDSjtBQTFCRCxvSEEwQkMiLCJzb3VyY2VzQ29udGVudCI6WyIvLyBDb3B5cmlnaHQgKGMpIDIwMjYgQXBwbGUgSW5jLiBMaWNlbnNlZCB1bmRlciBNSVQgTGljZW5zZS5cblxuaW1wb3J0IHsgSGVscGVyVmFsaWRhdGlvblV0aWxzIH0gZnJvbSAnLi4vaGVscGVyX3ZhbGlkYXRpb25fdXRpbHMnXG5pbXBvcnQgeyBBYnN0cmFjdEFkdmFuY2VkQ29tbWVyY2VCYXNlSXRlbSB9IGZyb20gJy4vQWJzdHJhY3RBZHZhbmNlZENvbW1lcmNlQmFzZUl0ZW0nXG5pbXBvcnQgeyBWYWxpZGF0b3IgfSBmcm9tICcuL1ZhbGlkYXRvcidcblxuLyoqXG4gKiBUaGUgZGF0YSB5b3VyIGFwcCBwcm92aWRlcyB0byBjaGFuZ2UgYSBzdWJzY3JpcHRpb24gcHJpY2UuXG4gKiBcbiAqIHtAbGluayBodHRwczovL2RldmVsb3Blci5hcHBsZS5jb20vZG9jdW1lbnRhdGlvbi9hZHZhbmNlZGNvbW1lcmNlYXBpL3N1YnNjcmlwdGlvbnByaWNlY2hhbmdlaXRlbSBTdWJzY3JpcHRpb25QcmljZUNoYW5nZUl0ZW19XG4gKi9cbmV4cG9ydCBpbnRlcmZhY2UgQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvblByaWNlQ2hhbmdlSXRlbSBleHRlbmRzIEFic3RyYWN0QWR2YW5jZWRDb21tZXJjZUJhc2VJdGVtIHtcbiAgICAvKipcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYWR2YW5jZWRjb21tZXJjZWFwaS9wcmljZSBwcmljZX1cbiAgICAgKi9cbiAgICBwcmljZTogbnVtYmVyXG5cbiAgICAvKipcbiAgICAgKiB7QGxpbmsgaHR0cHM6Ly9kZXZlbG9wZXIuYXBwbGUuY29tL2RvY3VtZW50YXRpb24vYWR2YW5jZWRjb21tZXJjZWFwaS9kZXBlbmRlbnRza3UgZGVwZW5kZW50U0tVfVxuICAgICAqL1xuICAgIGRlcGVuZGVudFNLVXM/OiBTdHJpbmdbXVxufVxuXG5leHBvcnQgY2xhc3MgQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvblByaWNlQ2hhbmdlSXRlbVZhbGlkYXRvciBpbXBsZW1lbnRzIFZhbGlkYXRvcjxBZHZhbmNlZENvbW1lcmNlU3Vic2NyaXB0aW9uUHJpY2VDaGFuZ2VJdGVtPiB7XG4gICAgdmFsaWRhdGUob2JqOiBhbnkpOiBvYmogaXMgQWR2YW5jZWRDb21tZXJjZVN1YnNjcmlwdGlvblByaWNlQ2hhbmdlSXRlbSB7XG4gICAgICAgIGlmICghKHR5cGVvZiBvYmpbJ1NLVSddID09PSBcInN0cmluZ1wiIHx8IG9ialsnU0tVJ10gaW5zdGFuY2VvZiBTdHJpbmcpKSB7XG4gICAgICAgICAgICByZXR1cm4gZmFsc2VcbiAgICAgICAgfVxuICAgICAgICBpZiAoIUhlbHBlclZhbGlkYXRpb25VdGlscy52YWxpZGF0ZVNrdShvYmpbJ1NLVSddKSkge1xuICAgICAgICAgICAgcmV0dXJuIGZhbHNlXG4gICAgICAgIH1cbiAgICAgICAgaWYgKCEodHlwZW9mIG9ialsncHJpY2UnXSA9PT0gXCJudW1iZXJcIikpIHtcbiAgICAgICAgICAgIHJldHVybiBmYWxzZVxuICAgICAgICB9XG4gICAgICAgIGlmICh0eXBlb2Ygb2JqWydkZXBlbmRlbnRTS1VzJ10gIT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgICAgICBpZiAoIUhlbHBlclZhbGlkYXRpb25VdGlscy52YWxpZGF0ZUl0ZW1zKG9ialsnZGVwZW5kZW50U0tVcyddKSkge1xuICAgICAgICAgICAgICAgIHJldHVybiBmYWxzZVxuICAgICAgICAgICAgfVxuICAgICAgICAgICAgZm9yIChjb25zdCBza3Ugb2Ygb2JqWydkZXBlbmRlbnRTS1VzJ10pIHtcbiAgICAgICAgICAgICAgICBpZiAoISh0eXBlb2Ygc2t1ID09PSBcInN0cmluZ1wiIHx8IHNrdSBpbnN0YW5jZW9mIFN0cmluZykpIHtcbiAgICAgICAgICAgICAgICAgICAgcmV0dXJuIGZhbHNlXG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIGlmICghSGVscGVyVmFsaWRhdGlvblV0aWxzLnZhbGlkYXRlU2t1KHNrdSkpIHtcbiAgICAgICAgICAgICAgICAgICAgcmV0dXJuIGZhbHNlXG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICAgIHJldHVybiB0cnVlXG4gICAgfVxufVxuIl19