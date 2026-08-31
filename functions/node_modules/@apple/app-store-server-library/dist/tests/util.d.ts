import { Environment } from '../models/Environment';
import { SignedDataVerifier } from '../jws_verification';
export declare function readFile(path: string): string;
export declare function readBytes(path: string): Buffer;
export declare function getSignedPayloadVerifier(environment: Environment, bundleId: string, appAppleId: number): SignedDataVerifier;
export declare function getSignedPayloadVerifierWithDefaultAppAppleId(environment: Environment, bundleId: string): SignedDataVerifier;
export declare function getDefaultSignedPayloadVerifier(): SignedDataVerifier;
export declare function createSignedDataFromJson(path: string): string;
