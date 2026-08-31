import { StringValidator } from "./Validator";
/**
 * The type of in-app purchase products you can offer in your app.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/type type}
 */
export declare enum Type {
    AUTO_RENEWABLE_SUBSCRIPTION = "Auto-Renewable Subscription",
    NON_CONSUMABLE = "Non-Consumable",
    CONSUMABLE = "Consumable",
    NON_RENEWING_SUBSCRIPTION = "Non-Renewing Subscription"
}
export declare class TypeValidator extends StringValidator {
}
