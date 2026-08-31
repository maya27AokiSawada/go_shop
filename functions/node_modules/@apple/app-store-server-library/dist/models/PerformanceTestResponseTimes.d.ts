import { Validator } from "./Validator";
/**
 * An object that describes test response times.
 *
 * {@link https://developer.apple.com/documentation/retentionmessaging/performancetestresponsetimes PerformanceTestResponseTimes}
 */
export interface PerformanceTestResponseTimes {
    /**
     * Average response time in milliseconds.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/average average}
     **/
    average: number;
    /**
     * The 50th percentile response time in milliseconds.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/p50 p50}
     **/
    p50: number;
    /**
     * The 90th percentile response time in milliseconds.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/p90 p90}
     **/
    p90: number;
    /**
     * The 95th percentile response time in milliseconds.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/p95 p95}
     **/
    p95: number;
    /**
     * The 99th percentile response time in milliseconds.
     *
     * {@link https://developer.apple.com/documentation/retentionmessaging/p99 p99}
     **/
    p99: number;
}
export declare class PerformanceTestResponseTimesValidator implements Validator<PerformanceTestResponseTimes> {
    validate(obj: any): obj is PerformanceTestResponseTimes;
}
