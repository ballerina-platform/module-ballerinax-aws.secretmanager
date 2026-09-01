// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com).
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
import ballerinax/aws;
import ballerinax/aws.auth;

// `region` accepts an `aws:Region` member or a plain string, so a region newer than the enum can still be used.
@test:Config {groups: ["config"]}
function testInitWithRegionString() returns error? {
    Client secretmanager = check new ({
        region: "us-east-1",
        auth: mockAuth,
        endpoint: {customEndpoint: mockServerUrl}
    });
    check secretmanager.close();
}

@test:Config {groups: ["config"]}
function testInitWithRegionEnum() returns error? {
    Client secretmanager = check new ({
        region: aws:US_EAST_1,
        auth: mockAuth,
        endpoint: {customEndpoint: mockServerUrl}
    });
    check secretmanager.close();
}

// The default credential provider chain resolves lazily, so building a client succeeds even with no credentials
// configured — the failure, if any, surfaces on the first request.
@test:Config {groups: ["config"]}
function testInitWithDefaultCredentials() returns error? {
    Client secretmanager = check new ({
        region: aws:US_EAST_1,
        auth: auth:DEFAULT_CREDENTIALS,
        endpoint: {customEndpoint: mockServerUrl}
    });
    check secretmanager.close();
}

// A profile that does not exist is resolved eagerly, so this is the one credential source that fails at init. The
// failure has to arrive as the module's own error type, with the underlying cause kept.
@test:Config {groups: ["config"]}
function testInitWithMissingProfileFails() {
    Client|Error secretmanager = new ({
        region: aws:US_EAST_1,
        auth: {profileName: "no-such-profile", credentialsFilePath: "/tmp/no-such-credentials-file"}
    });
    if secretmanager !is Error {
        test:assertFail("a client built on a nonexistent profile should not initialize");
    }
    test:assertTrue(secretmanager.message().startsWith(
            "Error occurred while initializing the AWS secret manager client:"), secretmanager.message());
    test:assertTrue(secretmanager.cause() is error, "the underlying cause was dropped");
    // The failure never reached a service, so it carries no service error details.
    test:assertTrue(secretmanager.detail().httpStatusCode is (), "an init failure must not carry an HTTP status");
}

@test:Config {groups: ["config"]}
function testEndpointResolution() {
    test:assertEquals(aws:resolveEndpointHost("secretsmanager", aws:US_EAST_1),
            "secretsmanager.us-east-1.amazonaws.com");
    test:assertEquals(aws:resolveEndpoint("secretsmanager", aws:EU_WEST_1),
            "https://secretsmanager.eu-west-1.amazonaws.com");
    // A custom endpoint overrides the resolution entirely.
    test:assertEquals(aws:resolveEndpoint("secretsmanager", aws:US_EAST_1,
            {customEndpoint: mockServerUrl}), mockServerUrl);
}

// `close` is a regular method rather than a remote one, because it releases local resources instead of calling the
// service. Two things follow: calling it twice is not an error, and a closed client cannot still be used.
@test:Config {groups: ["close"]}
function testCloseIsIdempotent() returns error? {
    Client secretmanager = check newTestClient();
    check secretmanager.close();
    check secretmanager.close();
}

@test:Config {groups: ["close"]}
function testRequestAfterCloseFails() returns error? {
    Client secretmanager = check newTestClient();
    check secretmanager.close();
    DescribeSecretResponse|Error response = secretmanager->describeSecret(MOCK_SECRET_NAME);
    if response !is Error {
        test:assertFail("a request on a closed client succeeded");
    }
}

@test:Config {groups: ["validation"]}
function testEmptySecretIdIsRejected() returns error? {
    DescribeSecretResponse|Error response = secretmanagerClient->describeSecret("");
    assertRejectedLocally(response, "SecretId must contain at least 1 character");
}

@test:Config {groups: ["validation"]}
function testOversizedSecretIdIsRejected() returns error? {
    // One character past the documented 2048-character ceiling.
    string oversized = "";
    foreach int _ in 1 ... 2049 {
        oversized += "x";
    }
    DescribeSecretResponse|Error response = secretmanagerClient->describeSecret(oversized);
    assertRejectedLocally(response, "SecretId cannot exceed 2048 characters");
}

@test:Config {groups: ["validation"]}
function testShortVersionIdIsRejected() returns error? {
    SecretValue|Error secret = secretmanagerClient->getSecretValue(MOCK_SECRET_NAME, versionId = "too-short");
    assertRejectedLocally(secret, "VersionId must be at least 32 characters long");
}

@test:Config {groups: ["validation"]}
function testEmptyVersionStageIsRejected() returns error? {
    SecretValue|Error secret = secretmanagerClient->getSecretValue(MOCK_SECRET_NAME, versionStage = "");
    assertRejectedLocally(secret, "VersionStage must contain at least 1 character");
}

@test:Config {groups: ["validation"]}
function testTooManySecretIdsAreRejected() returns error? {
    SecretId[] secretIds = from int i in 1 ... 21
        select string `secret-${i}`;
    BatchGetSecretValueResponse|Error response = secretmanagerClient->batchGetSecretValue(secretIds = secretIds);
    assertRejectedLocally(response, "Can only have maximum 20 secretIds per request");
}

@test:Config {groups: ["validation"]}
function testEmptySecretIdListIsRejected() returns error? {
    BatchGetSecretValueResponse|Error response = secretmanagerClient->batchGetSecretValue(secretIds = []);
    assertRejectedLocally(response, "Should have atleast 1 secretId per request");
}

@test:Config {groups: ["validation"]}
function testTooManyFiltersAreRejected() returns error? {
    SecretValueFilter[] filters = from int i in 1 ... 11
        select {'key: "name", values: [string `value-${i}`]};
    BatchGetSecretValueResponse|Error response = secretmanagerClient->batchGetSecretValue(filters = filters);
    assertRejectedLocally(response, "Can only have maximum 10 filters per request");
}

@test:Config {groups: ["validation"]}
function testMaxResultsOutOfRangeIsRejected() returns error? {
    BatchGetSecretValueResponse|Error response = secretmanagerClient->batchGetSecretValue(
            filters = [{'key: "tag-key", values: [MOCK_TAG_KEY]}], maxResults = 21);
    assertRejectedLocally(response, "MaxResults cannot exceed 20");
}

@test:Config {groups: ["validation"]}
function testMalformedFilterValueIsRejected() returns error? {
    // The pattern excludes `#`, so this value cannot reach the service.
    BatchGetSecretValueResponse|Error response = secretmanagerClient->batchGetSecretValue(
            filters = [{'key: "name", values: ["bad#value"]}]);
    assertRejectedLocally(response, "Invalid filter value format");
}

// The two mutual-exclusion rules the connector enforces itself, each with its own message rather than a constraint
// report.
@test:Config {groups: ["validation"]}
function testNeitherFiltersNorSecretIdsIsRejected() returns error? {
    BatchGetSecretValueResponse|Error response = secretmanagerClient->batchGetSecretValue();
    if response !is Error {
        test:assertFail("a batch request naming neither filters nor secretIds succeeded");
    }
    test:assertEquals(response.message(), "Either `filters` or `secretIds` must be provided in the request");
}

@test:Config {groups: ["validation"]}
function testBothFiltersAndSecretIdsIsRejected() returns error? {
    BatchGetSecretValueResponse|Error response = secretmanagerClient->batchGetSecretValue(
            filters = [{'key: "tag-key", values: [MOCK_TAG_KEY]}], secretIds = [MOCK_SECRET_NAME]);
    if response !is Error {
        test:assertFail("a batch request naming both filters and secretIds succeeded");
    }
    test:assertEquals(response.message(),
            "The request cannot contain both `filters` and `secretIds` simultaneously");
}

// A constraint failure is reported as the connector's own validation error, and never carries service error details.
isolated function assertRejectedLocally(anydata|Error result, string expectedInMessage) {
    if result !is Error {
        test:assertFail(string `expected '${expectedInMessage}' to be rejected, got a result`);
    }
    test:assertTrue(result.message().startsWith("Request validation failed:"), result.message());
    test:assertTrue(result.message().includes(expectedInMessage), result.message());
    test:assertTrue(result.detail().httpStatusCode is (),
            "a locally rejected request must not carry an HTTP status");
}
