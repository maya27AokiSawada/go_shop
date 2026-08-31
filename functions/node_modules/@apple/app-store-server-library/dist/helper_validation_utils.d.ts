export declare class HelperValidationUtils {
    static readonly MAXIMUM_DESCRIPTION_LENGTH = 45;
    static readonly MAXIMUM_DISPLAY_NAME_LENGTH = 30;
    private static readonly MAXIMUM_SKU_LENGTH;
    private static readonly MIN_PERIOD;
    private static readonly MAX_PERIOD;
    /**
     * Validates description is a string and does not exceed maximum length.
     *
     * @param description The description to validate
     * @return Whether the description is valid
     */
    static validateDescription(description: any): boolean;
    /**
     * Validates display name is a string and does not exceed maximum length.
     *
     * @param displayName The display name to validate
     * @return Whether the display name is valid
     */
    static validateDisplayName(displayName: any): boolean;
    /**
     * Validates SKU is a string and does not exceed maximum length.
     *
     * @param sku The SKU to validate
     * @return Whether the SKU is valid
     */
    static validateSku(sku: any): boolean;
    /**
     * Validates periodCount is a number between MIN_PERIOD and MAX_PERIOD inclusive.
     *
     * @param periodCount The period count to validate
     * @return Whether the period count is valid
     */
    static validatePeriodCount(periodCount: any): boolean;
    /**
     * Validates a list of items is a non-empty array with no null elements.
     *
     * @param list The list of items to validate
     * @return Whether the items list is valid
     */
    static validateItems(list: any): boolean;
}
