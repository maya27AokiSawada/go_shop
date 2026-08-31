import { StringValidator } from "./Validator";
/**
 * The status of the performance test.
 *
 * {@link https://developer.apple.com/documentation/retentionmessaging/performanceteststatus PerformanceTestStatus}
 */
export declare enum PerformanceTestStatus {
    PENDING = "PENDING",
    PASS = "PASS",
    FAIL = "FAIL"
}
export declare class PerformanceTestStatusValidator extends StringValidator {
}
