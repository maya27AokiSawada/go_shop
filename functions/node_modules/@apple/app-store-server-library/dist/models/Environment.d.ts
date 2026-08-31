import { StringValidator } from "./Validator";
/**
 * The server environment, either sandbox or production.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/environment environment}
 */
export declare enum Environment {
    SANDBOX = "Sandbox",
    PRODUCTION = "Production",
    XCODE = "Xcode",
    LOCAL_TESTING = "LocalTesting"
}
export declare class EnvironmentValidator extends StringValidator {
}
