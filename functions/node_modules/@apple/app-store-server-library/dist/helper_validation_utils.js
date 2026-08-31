"use strict";
// Copyright (c) 2026 Apple Inc. Licensed under MIT License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.HelperValidationUtils = void 0;
class HelperValidationUtils {
    /**
     * Validates description is a string and does not exceed maximum length.
     *
     * @param description The description to validate
     * @return Whether the description is valid
     */
    static validateDescription(description) {
        return (typeof description === 'string' || description instanceof String) && description.length <= HelperValidationUtils.MAXIMUM_DESCRIPTION_LENGTH;
    }
    /**
     * Validates display name is a string and does not exceed maximum length.
     *
     * @param displayName The display name to validate
     * @return Whether the display name is valid
     */
    static validateDisplayName(displayName) {
        return (typeof displayName === 'string' || displayName instanceof String) && displayName.length <= HelperValidationUtils.MAXIMUM_DISPLAY_NAME_LENGTH;
    }
    /**
     * Validates SKU is a string and does not exceed maximum length.
     *
     * @param sku The SKU to validate
     * @return Whether the SKU is valid
     */
    static validateSku(sku) {
        return (typeof sku === 'string' || sku instanceof String) && sku.length <= HelperValidationUtils.MAXIMUM_SKU_LENGTH;
    }
    /**
     * Validates periodCount is a number between MIN_PERIOD and MAX_PERIOD inclusive.
     *
     * @param periodCount The period count to validate
     * @return Whether the period count is valid
     */
    static validatePeriodCount(periodCount) {
        return typeof periodCount === 'number' &&
            periodCount >= HelperValidationUtils.MIN_PERIOD &&
            periodCount <= HelperValidationUtils.MAX_PERIOD;
    }
    /**
     * Validates a list of items is a non-empty array with no null elements.
     *
     * @param list The list of items to validate
     * @return Whether the items list is valid
     */
    static validateItems(list) {
        return Array.isArray(list) && list.length > 0 && list.every((item) => item != null);
    }
}
exports.HelperValidationUtils = HelperValidationUtils;
HelperValidationUtils.MAXIMUM_DESCRIPTION_LENGTH = 45;
HelperValidationUtils.MAXIMUM_DISPLAY_NAME_LENGTH = 30;
HelperValidationUtils.MAXIMUM_SKU_LENGTH = 128;
HelperValidationUtils.MIN_PERIOD = 1;
HelperValidationUtils.MAX_PERIOD = 12;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiaGVscGVyX3ZhbGlkYXRpb25fdXRpbHMuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi9oZWxwZXJfdmFsaWRhdGlvbl91dGlscy50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiO0FBQUEsNERBQTREOzs7QUFFNUQsTUFBYSxxQkFBcUI7SUFROUI7Ozs7O09BS0c7SUFDSSxNQUFNLENBQUMsbUJBQW1CLENBQUMsV0FBZ0I7UUFDOUMsT0FBTyxDQUFDLE9BQU8sV0FBVyxLQUFLLFFBQVEsSUFBSSxXQUFXLFlBQVksTUFBTSxDQUFDLElBQUksV0FBVyxDQUFDLE1BQU0sSUFBSSxxQkFBcUIsQ0FBQywwQkFBMEIsQ0FBQTtJQUN2SixDQUFDO0lBRUQ7Ozs7O09BS0c7SUFDSSxNQUFNLENBQUMsbUJBQW1CLENBQUMsV0FBZ0I7UUFDOUMsT0FBTyxDQUFDLE9BQU8sV0FBVyxLQUFLLFFBQVEsSUFBSSxXQUFXLFlBQVksTUFBTSxDQUFDLElBQUksV0FBVyxDQUFDLE1BQU0sSUFBSSxxQkFBcUIsQ0FBQywyQkFBMkIsQ0FBQTtJQUN4SixDQUFDO0lBRUQ7Ozs7O09BS0c7SUFDSSxNQUFNLENBQUMsV0FBVyxDQUFDLEdBQVE7UUFDOUIsT0FBTyxDQUFDLE9BQU8sR0FBRyxLQUFLLFFBQVEsSUFBSSxHQUFHLFlBQVksTUFBTSxDQUFDLElBQUksR0FBRyxDQUFDLE1BQU0sSUFBSSxxQkFBcUIsQ0FBQyxrQkFBa0IsQ0FBQTtJQUN2SCxDQUFDO0lBRUQ7Ozs7O09BS0c7SUFDSSxNQUFNLENBQUMsbUJBQW1CLENBQUMsV0FBZ0I7UUFDOUMsT0FBTyxPQUFPLFdBQVcsS0FBSyxRQUFRO1lBQ2xDLFdBQVcsSUFBSSxxQkFBcUIsQ0FBQyxVQUFVO1lBQy9DLFdBQVcsSUFBSSxxQkFBcUIsQ0FBQyxVQUFVLENBQUE7SUFDdkQsQ0FBQztJQUVEOzs7OztPQUtHO0lBQ0ksTUFBTSxDQUFDLGFBQWEsQ0FBQyxJQUFTO1FBQ2pDLE9BQU8sS0FBSyxDQUFDLE9BQU8sQ0FBQyxJQUFJLENBQUMsSUFBSSxJQUFJLENBQUMsTUFBTSxHQUFHLENBQUMsSUFBSSxJQUFJLENBQUMsS0FBSyxDQUFDLENBQUMsSUFBUyxFQUFFLEVBQUUsQ0FBQyxJQUFJLElBQUksSUFBSSxDQUFDLENBQUE7SUFDNUYsQ0FBQzs7QUExREwsc0RBMkRDO0FBekQwQixnREFBMEIsR0FBRyxFQUFFLENBQUE7QUFDL0IsaURBQTJCLEdBQUcsRUFBRSxDQUFBO0FBQy9CLHdDQUFrQixHQUFHLEdBQUcsQ0FBQTtBQUN4QixnQ0FBVSxHQUFHLENBQUMsQ0FBQTtBQUNkLGdDQUFVLEdBQUcsRUFBRSxDQUFBIiwic291cmNlc0NvbnRlbnQiOlsiLy8gQ29weXJpZ2h0IChjKSAyMDI2IEFwcGxlIEluYy4gTGljZW5zZWQgdW5kZXIgTUlUIExpY2Vuc2UuXG5cbmV4cG9ydCBjbGFzcyBIZWxwZXJWYWxpZGF0aW9uVXRpbHMge1xuXG4gICAgcHVibGljIHN0YXRpYyByZWFkb25seSBNQVhJTVVNX0RFU0NSSVBUSU9OX0xFTkdUSCA9IDQ1XG4gICAgcHVibGljIHN0YXRpYyByZWFkb25seSBNQVhJTVVNX0RJU1BMQVlfTkFNRV9MRU5HVEggPSAzMFxuICAgIHByaXZhdGUgc3RhdGljIHJlYWRvbmx5IE1BWElNVU1fU0tVX0xFTkdUSCA9IDEyOFxuICAgIHByaXZhdGUgc3RhdGljIHJlYWRvbmx5IE1JTl9QRVJJT0QgPSAxXG4gICAgcHJpdmF0ZSBzdGF0aWMgcmVhZG9ubHkgTUFYX1BFUklPRCA9IDEyXG5cbiAgICAvKipcbiAgICAgKiBWYWxpZGF0ZXMgZGVzY3JpcHRpb24gaXMgYSBzdHJpbmcgYW5kIGRvZXMgbm90IGV4Y2VlZCBtYXhpbXVtIGxlbmd0aC5cbiAgICAgKlxuICAgICAqIEBwYXJhbSBkZXNjcmlwdGlvbiBUaGUgZGVzY3JpcHRpb24gdG8gdmFsaWRhdGVcbiAgICAgKiBAcmV0dXJuIFdoZXRoZXIgdGhlIGRlc2NyaXB0aW9uIGlzIHZhbGlkXG4gICAgICovXG4gICAgcHVibGljIHN0YXRpYyB2YWxpZGF0ZURlc2NyaXB0aW9uKGRlc2NyaXB0aW9uOiBhbnkpOiBib29sZWFuIHtcbiAgICAgICAgcmV0dXJuICh0eXBlb2YgZGVzY3JpcHRpb24gPT09ICdzdHJpbmcnIHx8IGRlc2NyaXB0aW9uIGluc3RhbmNlb2YgU3RyaW5nKSAmJiBkZXNjcmlwdGlvbi5sZW5ndGggPD0gSGVscGVyVmFsaWRhdGlvblV0aWxzLk1BWElNVU1fREVTQ1JJUFRJT05fTEVOR1RIXG4gICAgfVxuXG4gICAgLyoqXG4gICAgICogVmFsaWRhdGVzIGRpc3BsYXkgbmFtZSBpcyBhIHN0cmluZyBhbmQgZG9lcyBub3QgZXhjZWVkIG1heGltdW0gbGVuZ3RoLlxuICAgICAqXG4gICAgICogQHBhcmFtIGRpc3BsYXlOYW1lIFRoZSBkaXNwbGF5IG5hbWUgdG8gdmFsaWRhdGVcbiAgICAgKiBAcmV0dXJuIFdoZXRoZXIgdGhlIGRpc3BsYXkgbmFtZSBpcyB2YWxpZFxuICAgICAqL1xuICAgIHB1YmxpYyBzdGF0aWMgdmFsaWRhdGVEaXNwbGF5TmFtZShkaXNwbGF5TmFtZTogYW55KTogYm9vbGVhbiB7XG4gICAgICAgIHJldHVybiAodHlwZW9mIGRpc3BsYXlOYW1lID09PSAnc3RyaW5nJyB8fCBkaXNwbGF5TmFtZSBpbnN0YW5jZW9mIFN0cmluZykgJiYgZGlzcGxheU5hbWUubGVuZ3RoIDw9IEhlbHBlclZhbGlkYXRpb25VdGlscy5NQVhJTVVNX0RJU1BMQVlfTkFNRV9MRU5HVEhcbiAgICB9XG5cbiAgICAvKipcbiAgICAgKiBWYWxpZGF0ZXMgU0tVIGlzIGEgc3RyaW5nIGFuZCBkb2VzIG5vdCBleGNlZWQgbWF4aW11bSBsZW5ndGguXG4gICAgICpcbiAgICAgKiBAcGFyYW0gc2t1IFRoZSBTS1UgdG8gdmFsaWRhdGVcbiAgICAgKiBAcmV0dXJuIFdoZXRoZXIgdGhlIFNLVSBpcyB2YWxpZFxuICAgICAqL1xuICAgIHB1YmxpYyBzdGF0aWMgdmFsaWRhdGVTa3Uoc2t1OiBhbnkpOiBib29sZWFuIHtcbiAgICAgICAgcmV0dXJuICh0eXBlb2Ygc2t1ID09PSAnc3RyaW5nJyB8fCBza3UgaW5zdGFuY2VvZiBTdHJpbmcpICYmIHNrdS5sZW5ndGggPD0gSGVscGVyVmFsaWRhdGlvblV0aWxzLk1BWElNVU1fU0tVX0xFTkdUSFxuICAgIH1cblxuICAgIC8qKlxuICAgICAqIFZhbGlkYXRlcyBwZXJpb2RDb3VudCBpcyBhIG51bWJlciBiZXR3ZWVuIE1JTl9QRVJJT0QgYW5kIE1BWF9QRVJJT0QgaW5jbHVzaXZlLlxuICAgICAqXG4gICAgICogQHBhcmFtIHBlcmlvZENvdW50IFRoZSBwZXJpb2QgY291bnQgdG8gdmFsaWRhdGVcbiAgICAgKiBAcmV0dXJuIFdoZXRoZXIgdGhlIHBlcmlvZCBjb3VudCBpcyB2YWxpZFxuICAgICAqL1xuICAgIHB1YmxpYyBzdGF0aWMgdmFsaWRhdGVQZXJpb2RDb3VudChwZXJpb2RDb3VudDogYW55KTogYm9vbGVhbiB7XG4gICAgICAgIHJldHVybiB0eXBlb2YgcGVyaW9kQ291bnQgPT09ICdudW1iZXInICYmXG4gICAgICAgICAgICBwZXJpb2RDb3VudCA+PSBIZWxwZXJWYWxpZGF0aW9uVXRpbHMuTUlOX1BFUklPRCAmJlxuICAgICAgICAgICAgcGVyaW9kQ291bnQgPD0gSGVscGVyVmFsaWRhdGlvblV0aWxzLk1BWF9QRVJJT0RcbiAgICB9XG5cbiAgICAvKipcbiAgICAgKiBWYWxpZGF0ZXMgYSBsaXN0IG9mIGl0ZW1zIGlzIGEgbm9uLWVtcHR5IGFycmF5IHdpdGggbm8gbnVsbCBlbGVtZW50cy5cbiAgICAgKlxuICAgICAqIEBwYXJhbSBsaXN0IFRoZSBsaXN0IG9mIGl0ZW1zIHRvIHZhbGlkYXRlXG4gICAgICogQHJldHVybiBXaGV0aGVyIHRoZSBpdGVtcyBsaXN0IGlzIHZhbGlkXG4gICAgICovXG4gICAgcHVibGljIHN0YXRpYyB2YWxpZGF0ZUl0ZW1zKGxpc3Q6IGFueSk6IGJvb2xlYW4ge1xuICAgICAgICByZXR1cm4gQXJyYXkuaXNBcnJheShsaXN0KSAmJiBsaXN0Lmxlbmd0aCA+IDAgJiYgbGlzdC5ldmVyeSgoaXRlbTogYW55KSA9PiBpdGVtICE9IG51bGwpXG4gICAgfVxufVxuIl19