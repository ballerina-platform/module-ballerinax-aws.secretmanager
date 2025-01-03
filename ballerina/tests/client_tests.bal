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

import ballerina/test;
import ballerina/os;

final boolean enableTests = os:getEnv("ENABLE_TESTS") is "true";
final string accessKeyId = os:getEnv("AWS_ACCESS_KEY_ID");
final string secretAccessKey = os:getEnv("AWS_SECRET_ACCESS_KEY");

final Client secretManager = check initClient();

isolated function initClient()returns Client|error {
    if enableTests {
        return new({
            region: US_EAST_1,
            auth: {accessKeyId, secretAccessKey}
        });
    }
    return test:mock(Client);
}

@test:Config {
    enable: enableTests
}
isolated function testDescribeSecretWithName() returns error? {
    string secretName = "prod/myapp/beta";
    DescribeSecretResponse response = check secretManager->describeSecret(secretName);
    test:assertEquals(response.name, secretName);
}

@test:Config {
    enable: enableTests
}
isolated function testDescribeSecretWithArn() returns error? {
    string secretArn = "arn:aws:secretsmanager:us-east-1:367134611783:secret:prod/mysql/beta-fzKVYO";
    DescribeSecretResponse response = check secretManager->describeSecret(secretArn);
    test:assertEquals(response.arn, secretArn);
}

@test:Config {
    enable: enableTests
}
isolated function testDescribeSecretWithInvalidId() returns error? {
    DescribeSecretResponse|Error response = secretManager->describeSecret("prod/invalidapp/beta");
    test:assertTrue(response is Error);
    if response is Error {
        ErrorDetails errDetails = response.detail();
        test:assertEquals(errDetails.httpStatusCode, 400, "Invalid status code received");
        test:assertEquals(errDetails.errorMessage, "Secrets Manager can't find the specified secret.", 
            "Invalid error message received");
    }
}

@test:Config {
    enable: enableTests
}
isolated function testDescribeSecretWithEmptyId() returns error? {
    DescribeSecretResponse|Error response = secretManager->describeSecret("");
    test:assertTrue(response is Error);
    if response is Error {
        test:assertTrue(
            response.message()
                .startsWith("Request validation failed: SecretId must contain at least 1 character")
            );
    }
}

@test:Config {
    enable: enableTests
}
isolated function testGetSecretWithName() returns error? {
    string secretName = "prod/myapp/beta";
    SecretValue secret = check secretManager->getSecretValue(secretId = secretName);
    test:assertEquals(secret.name, secretName);
}

@test:Config {
    enable: enableTests
}
isolated function testGetSecretWithArn() returns error? {
    string secretArn = "arn:aws:secretsmanager:us-east-1:367134611783:secret:prod/mysql/beta-fzKVYO";
    SecretValue secret = check secretManager->getSecretValue(secretId = secretArn);
    test:assertEquals(secret.arn, secretArn);
}

@test:Config {
    enable: enableTests
}
isolated function testGetSecretWithInvalidId() returns error? {
    SecretValue|Error secret = secretManager->getSecretValue(secretId = "prod/invalidapp/beta");
    test:assertTrue(secret is Error);
    if secret is Error {
        ErrorDetails errDetails = secret.detail();
        test:assertEquals(errDetails.httpStatusCode, 400, "Invalid status code received");
        test:assertEquals(errDetails.errorMessage, "Secrets Manager can't find the specified secret.", 
            "Invalid error message received");
    }
}

@test:Config {
    enable: enableTests
}
isolated function testGetSecretWithEmptyId() returns error? {
    SecretValue|Error secret = secretManager->getSecretValue(secretId = "");
    test:assertTrue(secret is Error);
    if secret is Error {
        test:assertTrue(
            secret.message()
                .startsWith("Request validation failed: SecretId must contain at least 1 character")
            );
    }
}

@test:Config {
    enable: enableTests
}
isolated function testBatchGetSecretWithIds() returns error? {
    BatchGetSecretValueResponse response = check secretManager->batchGetSecretValue(
        secretIds = ["prod/myapp/beta", "prod/mysql/beta"]);
    test:assertTrue(response.errors is (), "Got errors for valid batch get-secret request");
    test:assertTrue(response.secretValues !is (), "Could not get secret-values for a valid batch get-secret request");
    SecretValue[]? secretValues = response.secretValues;
    if secretValues is SecretValue[] {
        test:assertEquals(secretValues.length(), 2, "Invalid number of secret values received");
    }
}

@test:Config {
    enable: enableTests
}
isolated function testBatchGetSecretWithFilters() returns error? {
    BatchGetSecretValueResponse response = check secretManager->batchGetSecretValue(
        filters = [{'key: "tag-key", values: ["t1", "t2"]}]);
    test:assertTrue(response.errors is (), "Got errors for valid batch get-secret request");
    test:assertTrue(response.secretValues !is (), "Could not get secret-values for a valid batch get-secret request");
    SecretValue[]? secretValues = response.secretValues;
    if secretValues is SecretValue[] {
        test:assertEquals(secretValues.length(), 1, "Invalid number of secret values received");
    }
}

@test:Config {
    enable: enableTests
}
isolated function testBatchGetSecretWithoutFiltersAndSecrets() returns error? {
    BatchGetSecretValueResponse|Error response = secretManager->batchGetSecretValue();
    test:assertTrue(response is Error);
    if response is Error {
        test:assertEquals(
            response.message(), "Either `filters` or `secretIds` must be provided in the request");
    }
}

@test:Config {
    enable: enableTests
}
isolated function testBatchGetSecretWithFiltersAndSecrets() returns error? {
    BatchGetSecretValueResponse|Error response = secretManager->batchGetSecretValue(
        filters = [{'key: "tag-key", values: ["t1", "t2"]}],
        secretIds = ["prod/myapp/beta", "prod/mysql/beta"]
    );
    test:assertTrue(response is Error);
    if response is Error {
        test:assertEquals(
            response.message(), "The request cannot contain both `filters` and `secretIds` simultaneously");
    }
}
