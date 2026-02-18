// Copyright (c) 2025 WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/constraint;
import ballerina/jballerina.java;

# AWS Secret Manager client.
public isolated client class Client {

    # Initialize the Ballerina AWS Secret Manager client.
    # ```ballerina
    # secretmanager:Client secretmanager = check new(region = secretmanager:US_EAST_1, auth = {
    #   accessKeyId: "<aws-access-key>",
    #   secretAccessKey: "<aws-secret-key>"
    # });
    # ```
    # Or using the default credential provider chain (supports EC2, ECS/Fargate, env vars, etc.):
    # ```ballerina
    # secretmanager:Client secretmanager = check new(region = secretmanager:US_EAST_1,
    #   auth = secretmanager:DEFAULT_CREDENTIALS);
    # ```
    #
    # + configs - The AWS Secret Manager client configurations
    # + return - The `secretmanager:Client` or a `secretmanager:Error` if the initialization failed
    public isolated function init(*ConnectionConfig configs) returns Error? {
        return self.externInit(configs);
    }

    isolated function externInit(ConnectionConfig configs) returns Error? =
    @java:Method {
        name: "init",
        'class: "io.ballerina.lib.aws.secretmanager.NativeClientAdaptor"
    } external;

    # Retrieves the details of a secret. It does not include the encrypted secret value. 
    # Secrets Manager only returns fields that have a value in the response. 
    # ```ballerina
    # secretmanager:DescribeSecretResponse response = check secretmanager->describeSecret("<aws-secret-id>");
    # ```
    #
    # + secretId - The ARN or name of the secret
    # + return - An `secretmanager:DescribeSecretResponse` containing the details of the secret, 
    # or an `secretmanager:Error` if the request validation or the operation failed
    isolated remote function describeSecret(SecretId secretId) returns DescribeSecretResponse|Error {
        SecretId|constraint:Error validated = constraint:validate(secretId);
        if validated is constraint:Error {
            return error Error(string `Request validation failed: ${validated.message()}`);
        }
        return self.externDescribeSecret(validated);
    }

    isolated function externDescribeSecret(SecretId secretId) returns DescribeSecretResponse|Error =
    @java:Method {
        name: "describeSecret",
        'class: "io.ballerina.lib.aws.secretmanager.NativeClientAdaptor"
    } external;

    # Retrieves the contents of the encrypted fields from the specified version of a secret.
    # ```ballerina
    # secretmanager:SecretValue secret = check secretmanager->getSecretValue("<aws-secret-id>");
    # ```
    #
    # + secretId - The ARN or name of the secret
    # + versionSelector - Details for selecting a specific version of the secret
    # + return - An `secretmanager:SecretValue` containing the content of the secret, or an 
    # `secretmanager:Error` if the request validation or the operation failed
    isolated remote function getSecretValue(SecretId secretId, *SecretVersionSelector versionSelector) returns SecretValue|Error {
        SecretId|constraint:Error validatedSecretId = constraint:validate(secretId);
        if validatedSecretId is constraint:Error {
            return error Error(string `Request validation failed: ${validatedSecretId.message()}`);
        }
        SecretVersionSelector|constraint:Error validatedVersionSelector = constraint:validate(versionSelector);
        if validatedVersionSelector is constraint:Error {
            return error Error(string `Request validation failed: ${validatedVersionSelector.message()}`);
        }
        return self.externGetSecretValue(validatedSecretId, validatedVersionSelector);
    }

    isolated function externGetSecretValue(SecretId secretId, SecretVersionSelector versionSelector) returns SecretValue|Error =
    @java:Method {
        name: "getSecretValue",
        'class: "io.ballerina.lib.aws.secretmanager.NativeClientAdaptor"
    } external;

    # Retrieves the contents of the encrypted fields for up to 20 secrets.
    # ```ballerina
    # secretmanager:BatchGetSecretValueResponse secret = check secretmanager->batchGetSecretValue(
    #    secretIds = ["<aws-secret-id>"]);
    # ```
    #
    # + request - The filters or secret IDs used to identify the secrets to retrieve
    # + return - An `secretmanager:BatchGetSecretValueResponse` containing the contents of the secrets, or an 
    # `secretmanager:Error` if the request validation or the operation failed
    isolated remote function batchGetSecretValue(*BatchGetSecretValueRequest request) returns BatchGetSecretValueResponse|Error {
        BatchGetSecretValueRequest|constraint:Error validated = constraint:validate(request);
        if validated is constraint:Error {
            return error Error(string `Request validation failed: ${validated.message()}`);
        }
        if request.filters is () && request.secretIds is () {
            return error Error("Either `filters` or `secretIds` must be provided in the request");
        }
        if request.secretIds is SecretId[] && request.filters is SecretValueFilter[] {
            return error Error("The request cannot contain both `filters` and `secretIds` simultaneously");
        }
        return self.externBatchGetSecretValue(validated);
    }

    isolated function externBatchGetSecretValue(BatchGetSecretValueRequest request) returns BatchGetSecretValueResponse|Error =
    @java:Method {
        name: "batchGetSecretValue",
        'class: "io.ballerina.lib.aws.secretmanager.NativeClientAdaptor"
    } external;

    # Closes the AWS Secret Manager client resources.
    # ```ballerina
    # check secretmanager->close();
    # ```
    #
    # + return - A `secretmanager:Error` if there is an error while closing the client resources or else nil
    isolated remote function close() returns Error? =
    @java:Method {
        'class: "io.ballerina.lib.aws.secretmanager.NativeClientAdaptor"
    } external;
}
