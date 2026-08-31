import { PerformanceTestConfig, PerformanceTestConfigValidator } from "./PerformanceTestConfig";
import { Validator } from "./Validator";
/**
 * The performance test response object.
 *
 * {@link https://developer.apple.com/documentation/retentionmessaging/performancetestresponse PerformanceTestResponse}
 */
export interface PerformanceTestResponse {
    /**
     * The performance test configuration object.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/performancetestconfig config}
     **/
    config: PerformanceTestConfig;
    /**
     * The performance test request identifier.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/requestid requestId}
     **/
    requestId: string;
}
export declare class PerformanceTestResponseValidator implements Validator<PerformanceTestResponse> {
    static readonly performanceTestConfigValidator: PerformanceTestConfigValidator;
    validate(obj: any): obj is PerformanceTestResponse;
}
