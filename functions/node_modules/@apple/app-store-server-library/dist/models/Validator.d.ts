export interface Validator<T> {
    validate(obj: any): obj is T;
}
export declare class NumberValidator implements Validator<number> {
    validate(obj: any): obj is number;
}
export declare class StringValidator implements Validator<string> {
    validate(obj: any): obj is string;
}
