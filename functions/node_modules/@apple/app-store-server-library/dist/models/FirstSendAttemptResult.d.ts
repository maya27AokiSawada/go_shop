import { StringValidator } from "./Validator";
/**
 * An error or result that the App Store server receives when attempting to send an App Store server notification to your server.
 *
 * {@link https://developer.apple.com/documentation/appstoreserverapi/firstsendattemptresult firstSendAttemptResult}
 */
export declare enum FirstSendAttemptResult {
    SUCCESS = "SUCCESS",
    TIMED_OUT = "TIMED_OUT",
    TLS_ISSUE = "TLS_ISSUE",
    CIRCULAR_REDIRECT = "CIRCULAR_REDIRECT",
    NO_RESPONSE = "NO_RESPONSE",
    SOCKET_ISSUE = "SOCKET_ISSUE",
    UNSUPPORTED_CHARSET = "UNSUPPORTED_CHARSET",
    INVALID_RESPONSE = "INVALID_RESPONSE",
    PREMATURE_CLOSE = "PREMATURE_CLOSE",
    UNSUCCESSFUL_HTTP_RESPONSE_CODE = "UNSUCCESSFUL_HTTP_RESPONSE_CODE",
    OTHER = "OTHER"
}
export declare class FirstSendAttemptResultValidator extends StringValidator {
}
