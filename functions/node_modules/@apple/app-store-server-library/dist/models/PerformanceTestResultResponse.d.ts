import { PerformanceTestConfig, PerformanceTestConfigValidator } from "./PerformanceTestConfig";
import { PerformanceTestResponseTimes, PerformanceTestResponseTimesValidator } from "./PerformanceTestResponseTimes";
import { PerformanceTestStatus, PerformanceTestStatusValidator } from "./PerformanceTestStatus";
import { SendAttemptResult } from "./SendAttemptResult";
import { Validator } from "./Validator";
/**
 * An object the API returns that describes the performance test results.
 *
 * {@link https://developer.apple.com/documentation/retentionmessaging/performancetestresultresponse PerformanceTestResultResponse}
 */
export interface PerformanceTestResultResponse {
    /**
     * A PerformanceTestConfig object that enumerates the test parameters.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/performancetestconfig config}
     **/
    config: PerformanceTestConfig;
    /**
     * The target URL for the performance test.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/target target}
     **/
    target: string;
    /**
     * A PerformanceTestStatus object that describes the overall result of the test.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/performanceteststatus result}
     **/
    result: PerformanceTestStatus | string;
    /**
     * An integer that describes he success rate percentage of the performance test.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/successrate successRate}
     **/
    successRate: number;
    /**
     * An integer that describes the number of pending requests in the performance test.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/numpending numPending}
     **/
    numPending: number;
    /**
     * A PerformanceTestResponseTimes object that enumerates the response times measured during the test.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/performancetestresponsetimes responseTimes}
     **/
    responseTimes: PerformanceTestResponseTimes;
    /**
     * A map of server-to-server notification failure reasons and counts that represent the number of failures during a performance test.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/failures failures}
     **/
    failures: {
        [key in SendAttemptResult | string]: number;
    };
}
export declare class PerformanceTestResultResponseValidator implements Validator<PerformanceTestResultResponse> {
    static readonly performanceTestConfigValidator: PerformanceTestConfigValidator;
    static readonly performanceTestStatusValidator: PerformanceTestStatusValidator;
    static readonly performanceTestResponseTimesValidator: PerformanceTestResponseTimesValidator;
    validate(obj: any): obj is PerformanceTestResultResponse;
}
