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

import ballerina/os;
import ballerina/test;
import ballerinax/aws;
import ballerinax/aws.auth;

// The same suite runs against the mock service by default and against AWS when `IS_LIVE_SERVER` is set. A live run
// needs credentials and the fixture secrets named below; the mock run needs nothing.
configurable boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";

configurable string accessKeyId = os:getEnv("BALLERINA_AWS_TEST_ACCESS_KEY_ID");
configurable string secretAccessKey = os:getEnv("BALLERINA_AWS_TEST_SECRET_ACCESS_KEY");
configurable string liveSecretName = os:getEnv("BALLERINA_AWS_SM_TEST_SECRET_NAME");
configurable string liveBinarySecretName = os:getEnv("BALLERINA_AWS_SM_TEST_BINARY_SECRET_NAME");

final readonly & aws:Region awsRegion = aws:US_EAST_1;

final readonly & auth:StaticAuthConfig liveAuth = {accessKeyId, secretAccessKey};

final readonly & auth:StaticAuthConfig mockAuth = {
    accessKeyId: MOCK_ACCESS_KEY_ID,
    secretAccessKey: MOCK_SECRET_ACCESS_KEY
};

// Credentials the mock does not recognise, so the request is rejected at the signature check.
final readonly & auth:StaticAuthConfig unexpectedAuth = {
    accessKeyId: "AKIAIOSFODNN7EXAMPLE",
    secretAccessKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
};

final readonly & ConnectionConfig connectionConfig = isLiveServer
    ? {region: awsRegion, auth: liveAuth}
    : {region: awsRegion, auth: mockAuth, endpoint: {customEndpoint: mockServerUrl}};

final string testSecretName = isLiveServer ? liveSecretName : MOCK_SECRET_NAME;
final string testBinarySecretName = isLiveServer ? liveBinarySecretName : MOCK_BINARY_SECRET_NAME;

final Client secretmanagerClient = check new (connectionConfig);

@test:BeforeSuite
function startMockService() returns error? {
    if isLiveServer {
        return;
    }
    check mockListener.attach(mockService, "/");
    check mockListener.'start();
}

@test:AfterSuite
function stopMockService() returns error? {
    check secretmanagerClient.close();
    if isLiveServer {
        return;
    }
    check mockListener.gracefulStop();
}

// A client of its own, for the tests that need one.
isolated function newTestClient(auth:AuthConfig authConfig = mockAuth) returns Client|Error {
    ConnectionConfig config = isLiveServer
        ? {region: awsRegion, auth: authConfig}
        : {region: awsRegion, auth: authConfig, endpoint: {customEndpoint: mockServerUrl}};
    return new (config);
}

@test:Config {groups: ["describeSecret"]}
function testDescribeSecretByName() returns error? {
    DescribeSecretResponse response = check secretmanagerClient->describeSecret(testSecretName);
    test:assertEquals(response.name, testSecretName);
    test:assertTrue(response.arn.startsWith("arn:aws:secretsmanager:"), response.arn);
    test:assertTrue(response.createdDate[0] > 0, "createdDate was not mapped");
}

// A name and an ARN are interchangeable as a `SecretId`, and both have to describe the same secret.
@test:Config {groups: ["describeSecret"]}
function testDescribeSecretByArn() returns error? {
    DescribeSecretResponse byName = check secretmanagerClient->describeSecret(testSecretName);
    DescribeSecretResponse byArn = check secretmanagerClient->describeSecret(byName.arn);
    test:assertEquals(byArn.name, testSecretName);
    test:assertEquals(byArn.arn, byName.arn);
}

// The metadata mapping: the tags, the staging labels naming both versions, and the optional fields the richer fixture
// reports. Asserted only against the mock, because a live secret's metadata is whatever the account happens to hold.
@test:Config {groups: ["describeSecret"], enable: !isLiveServer}
function testDescribeSecretMapsMetadata() returns error? {
    DescribeSecretResponse response = check secretmanagerClient->describeSecret(MOCK_SECRET_NAME);

    test:assertEquals(response.description, MOCK_SECRET_DESCRIPTION);
    test:assertEquals(response.owningService, MOCK_OWNING_SERVICE);
    test:assertEquals(response.primaryRegion, MOCK_REGION);
    test:assertTrue(response.rotationEnabled);
    test:assertEquals(response.kmsKeyId, MOCK_KMS_KEY_ID);
    test:assertEquals(response.rotationLambdaArn, MOCK_ROTATION_LAMBDA_ARN);

    Tag[]? tags = response.tags;
    if tags is () {
        test:assertFail("describeSecret reported no tags");
    }
    test:assertEquals(tags.length(), 2);

    // Both versions have to be named, each with its own staging label — this is the metadata the version selectors
    // depend on.
    map<StagingStatus[]>? versionToStages = response.versionToStages;
    if versionToStages is () {
        test:assertFail("describeSecret reported no versionToStages");
    }
    test:assertEquals(versionToStages[MOCK_CURRENT_VERSION_ID], [AWSCURRENT]);
    test:assertEquals(versionToStages[MOCK_PREVIOUS_VERSION_ID], [AWSPREVIOUS]);

    ReplicationStatus[]? replicationStatus = response.replicationStatus;
    if replicationStatus is () {
        test:assertFail("describeSecret reported no replicationStatus");
    }
    test:assertEquals(replicationStatus[0].region, "us-west-2");
    test:assertEquals(replicationStatus[0].status, "InSync");

    RotationRules? rotationRules = response.rotationRules;
    if rotationRules is () {
        test:assertFail("describeSecret reported no rotationRules");
    }
    test:assertEquals(rotationRules.automaticallyAfterDays, MOCK_ROTATION_AFTER_DAYS);
    test:assertEquals(rotationRules.scheduleExpresssion, MOCK_ROTATION_SCHEDULE);
}

// `Description`, `OwningService` and `PrimaryRegion` are all conditional: AWS omits `Description` when the secret has
// none, `OwningService` unless the secret is managed by another AWS service, and `PrimaryRegion` unless the secret is
// replicated. None of the three is returned for a plain, unreplicated, customer-owned secret — the commonest kind.
//
// All three are therefore optional fields, and an absent one has to be genuinely absent from the record rather than
// present-and-nil. `hasKey` is what separates the two: a nil stored under the key would still satisfy `field is ()`,
// which is exactly how the earlier required-field version of this record behaved.
@test:Config {groups: ["describeSecret"], enable: !isLiveServer}
function testDescribeSecretWithoutConditionalFields() returns error? {
    DescribeSecretResponse response = check secretmanagerClient->describeSecret(MOCK_MINIMAL_SECRET_NAME);
    test:assertEquals(response.name, MOCK_MINIMAL_SECRET_NAME);
    test:assertFalse(response.rotationEnabled);

    test:assertFalse(response.hasKey("description"), "an absent Description must not be stored as nil");
    test:assertFalse(response.hasKey("owningService"), "an absent OwningService must not be stored as nil");
    test:assertFalse(response.hasKey("primaryRegion"), "an absent PrimaryRegion must not be stored as nil");

    // Now that the fields are optional, reading one is a nilable access the compiler can check.
    test:assertTrue(response.description is ());
    test:assertTrue(response.owningService is ());
    test:assertTrue(response.primaryRegion is ());
}

// The counterpart: the richer fixture reports all three, so the mapping still carries them when AWS does send them.
@test:Config {groups: ["describeSecret"], enable: !isLiveServer}
function testDescribeSecretWithConditionalFields() returns error? {
    DescribeSecretResponse response = check secretmanagerClient->describeSecret(MOCK_SECRET_NAME);
    test:assertTrue(response.hasKey("description"));
    test:assertTrue(response.hasKey("owningService"));
    test:assertTrue(response.hasKey("primaryRegion"));
}

@test:Config {groups: ["getSecretValue"]}
function testGetSecretValueByName() returns error? {
    SecretValue secret = check secretmanagerClient->getSecretValue(testSecretName);
    test:assertEquals(secret.name, testSecretName);
    test:assertTrue(secret.versionStages.indexOf(AWSCURRENT) !is (), secret.versionStages.toString());
    if !isLiveServer {
        // The value has to survive the JSON protocol unchanged, quotes and multi-byte characters included.
        test:assertEquals(secret.value, MOCK_CURRENT_SECRET_STRING);
        test:assertEquals(secret.versionId, MOCK_CURRENT_VERSION_ID);
    }
}

@test:Config {groups: ["getSecretValue"]}
function testGetSecretValueByArn() returns error? {
    DescribeSecretResponse described = check secretmanagerClient->describeSecret(testSecretName);
    SecretValue secret = check secretmanagerClient->getSecretValue(described.arn);
    test:assertEquals(secret.name, testSecretName);
}

// `versionStage` has to reach past the current value to the one it displaced. Asserted on the *older* value, so a
// selector that never arrived cannot pass by returning the current one.
@test:Config {groups: ["getSecretValue"], enable: !isLiveServer}
function testGetSecretValueByVersionStage() returns error? {
    SecretValue secret = check secretmanagerClient->getSecretValue(MOCK_SECRET_NAME, versionStage = AWSPREVIOUS);
    test:assertEquals(secret.versionId, MOCK_PREVIOUS_VERSION_ID);
    test:assertEquals(secret.value, MOCK_PREVIOUS_SECRET_STRING);
}

// The other half of `SecretVersionSelector`: an exact version.
@test:Config {groups: ["getSecretValue"], enable: !isLiveServer}
function testGetSecretValueByVersionId() returns error? {
    SecretValue secret = check secretmanagerClient->getSecretValue(
            MOCK_SECRET_NAME, versionId = MOCK_PREVIOUS_VERSION_ID);
    test:assertEquals(secret.versionId, MOCK_PREVIOUS_VERSION_ID);
    test:assertEquals(secret.value, MOCK_PREVIOUS_SECRET_STRING);
}

// `SecretVersionSelector` lets both selectors be set at once, and the connector puts both on the request. The service
// accepts that as long as the two refer to the same version, so a consistent pair has to resolve rather than be
// rejected — and reaching the right version proves both selectors travelled, which neither single-selector test shows.
@test:Config {groups: ["getSecretValue"], enable: !isLiveServer}
function testGetSecretValueByMatchingVersionIdAndStage() returns error? {
    SecretValue secret = check secretmanagerClient->getSecretValue(
            MOCK_SECRET_NAME, versionId = MOCK_PREVIOUS_VERSION_ID, versionStage = AWSPREVIOUS);
    test:assertEquals(secret.versionId, MOCK_PREVIOUS_VERSION_ID);
    test:assertEquals(secret.value, MOCK_PREVIOUS_SECRET_STRING);
}

// The other half of the same rule: two selectors that name different versions are a contradiction the service
// rejects, rather than one of them silently winning.
@test:Config {groups: ["getSecretValue"], enable: !isLiveServer}
function testMismatchedVersionSelectorsAreRejected() returns error? {
    SecretValue|Error secret = secretmanagerClient->getSecretValue(
            MOCK_SECRET_NAME, versionId = MOCK_PREVIOUS_VERSION_ID, versionStage = AWSCURRENT);
    if secret !is Error {
        test:assertFail(string `a versionId naming the previous version with versionStage AWSCURRENT resolved to ` +
                secret.versionId);
    }
    aws:ErrorDetails details = secret.detail();
    test:assertEquals(details.httpStatusCode, 400);
    test:assertEquals(details.errorCode, INVALID_PARAMETER);
}

// `SecretValue.value` is `byte[]|string`. A value the service stored as `SecretBinary` is the only way to reach the
// `byte[]` arm — a connector that decoded everything as text would either corrupt these bytes or fail here.
@test:Config {groups: ["getSecretValue"]}
function testGetSecretValueReturnsBinary() returns error? {
    SecretValue secret = check secretmanagerClient->getSecretValue(testBinarySecretName);
    if secret.value !is byte[] {
        test:assertFail(string `a SecretBinary value came back as a string: ${secret.value.toString()}`);
    }
    if !isLiveServer {
        test:assertEquals(<byte[]>secret.value, MOCK_BINARY_SECRET_VALUE);
    }
}

@test:Config {groups: ["batchGetSecretValue"]}
function testBatchGetSecretValueBySecretIds() returns error? {
    BatchGetSecretValueResponse response = check secretmanagerClient->batchGetSecretValue(
            secretIds = [testSecretName, testBinarySecretName]);

    test:assertTrue(response.errors is (), string `a batch of valid secrets reported errors: ` +
            (response.errors ?: []).toString());
    SecretValue[]? secretValues = response.secretValues;
    if secretValues is () {
        test:assertFail("the batch returned no secretValues");
    }
    test:assertEquals(secretValues.length(), 2);

    string[] names = from SecretValue secret in secretValues
        select secret.name;
    test:assertTrue(names.indexOf(testSecretName) !is (), names.toString());
    test:assertTrue(names.indexOf(testBinarySecretName) !is (), names.toString());
}

// The binary value has to survive the batch path too, not just `getSecretValue`.
@test:Config {groups: ["batchGetSecretValue"], enable: !isLiveServer}
function testBatchGetSecretValueReturnsBinary() returns error? {
    BatchGetSecretValueResponse response = check secretmanagerClient->batchGetSecretValue(
            secretIds = [MOCK_BINARY_SECRET_NAME]);
    SecretValue[]? secretValues = response.secretValues;
    if secretValues is () {
        test:assertFail("the batch returned no secretValues");
    }
    test:assertEquals(secretValues.length(), 1);
    test:assertEquals(secretValues[0].value, MOCK_BINARY_SECRET_VALUE);
}

@test:Config {groups: ["batchGetSecretValue"], enable: !isLiveServer}
function testBatchGetSecretValueByFilters() returns error? {
    BatchGetSecretValueResponse response = check secretmanagerClient->batchGetSecretValue(
            filters = [{'key: "tag-key", values: [MOCK_TAG_KEY]}]);
    SecretValue[]? secretValues = response.secretValues;
    if secretValues is () {
        test:assertFail("the filtered batch returned no secretValues");
    }
    // The string and binary fixtures carry the tag; the minimal one does not.
    test:assertEquals(secretValues.length(), 2);
}

// `maxResults` forces a page, and the `nextToken` fed back has to return a *different* secret — a token the connector
// failed to carry would repeat the first page.
@test:Config {groups: ["batchGetSecretValue"], enable: !isLiveServer}
function testBatchGetSecretValuePaginates() returns error? {
    SecretValueFilter[] filters = [{'key: "tag-key", values: [MOCK_TAG_KEY]}];

    BatchGetSecretValueResponse first = check secretmanagerClient->batchGetSecretValue(
            filters = filters, maxResults = 1);
    SecretValue[]? firstPage = first.secretValues;
    if firstPage is () {
        test:assertFail("page 1 returned no secretValues");
    }
    test:assertEquals(firstPage.length(), 1);

    string? nextToken = first.nextToken;
    if nextToken is () {
        test:assertFail("maxResults = 1 over two matching secrets returned no nextToken");
    }

    BatchGetSecretValueResponse second = check secretmanagerClient->batchGetSecretValue(
            filters = filters, maxResults = 1, nextToken = nextToken);
    SecretValue[]? secondPage = second.secretValues;
    if secondPage is () {
        test:assertFail("page 2 returned no secretValues");
    }
    test:assertEquals(secondPage.length(), 1);
    test:assertNotEquals(secondPage[0].name, firstPage[0].name, "the nextToken was not honoured");
}

// A filter value is a prefix of the tag key, not the whole key. Both tagged fixtures carry `purpose`, so a prefix of
// it has to reach both — an exact-match filter would need the full key and would still pass, which is why the
// assertion is on a strict prefix rather than the key itself.
@test:Config {groups: ["batchGetSecretValue"], enable: !isLiveServer}
function testTagKeyFilterMatchesOnPrefix() returns error? {
    BatchGetSecretValueResponse response = check secretmanagerClient->batchGetSecretValue(
            filters = [{'key: "tag-key", values: ["purp"]}]);
    SecretValue[]? secretValues = response.secretValues;
    if secretValues is () {
        test:assertFail("a tag-key prefix matched nothing");
    }
    test:assertEquals(secretValues.length(), 2);

    // A key only the richer fixture carries, so the prefix has to discriminate rather than match everything.
    BatchGetSecretValueResponse narrowed = check secretmanagerClient->batchGetSecretValue(
            filters = [{'key: "tag-key", values: ["own"]}]);
    SecretValue[]? narrowedValues = narrowed.secretValues;
    if narrowedValues is () {
        test:assertFail("the tag-key prefix 'own' matched nothing");
    }
    test:assertEquals(narrowedValues.length(), 1);
    test:assertEquals(narrowedValues[0].name, MOCK_SECRET_NAME);
}

// The same rule on the tag's value.
@test:Config {groups: ["batchGetSecretValue"], enable: !isLiveServer}
function testTagValueFilterMatchesOnPrefix() returns error? {
    BatchGetSecretValueResponse response = check secretmanagerClient->batchGetSecretValue(
            filters = [{'key: "tag-value", values: ["unit"]}]);
    SecretValue[]? secretValues = response.secretValues;
    if secretValues is () {
        test:assertFail("a tag-value prefix matched nothing");
    }
    test:assertEquals(secretValues.length(), 2);

    BatchGetSecretValueResponse narrowed = check secretmanagerClient->batchGetSecretValue(
            filters = [{'key: "tag-value", values: ["baller"]}]);
    SecretValue[]? narrowedValues = narrowed.secretValues;
    if narrowedValues is () {
        test:assertFail("the tag-value prefix 'baller' matched nothing");
    }
    test:assertEquals(narrowedValues.length(), 1);
    test:assertEquals(narrowedValues[0].name, MOCK_SECRET_NAME);
}

// Prefix matching is not a licence to match loosely: the comparison stays case-sensitive, and a prefix of nothing in
// particular matches nothing. An empty `secretValues` is reported as an absent field rather than an empty array.
@test:Config {groups: ["batchGetSecretValue"], enable: !isLiveServer}
function testTagFiltersAreCaseSensitiveAndAnchored() returns error? {
    BatchGetSecretValueResponse wrongCase = check secretmanagerClient->batchGetSecretValue(
            filters = [{'key: "tag-key", values: ["PURPOSE"]}]);
    test:assertTrue(wrongCase.secretValues is (),
            string `an upper-case tag-key matched ${(wrongCase.secretValues ?: []).length()} secret(s)`);

    // A substring that is not a prefix — `urpose` occurs inside `purpose` but does not start it.
    BatchGetSecretValueResponse midWord = check secretmanagerClient->batchGetSecretValue(
            filters = [{'key: "tag-key", values: ["urpose"]}]);
    test:assertTrue(midWord.secretValues is (),
            string `a mid-word tag-key matched ${(midWord.secretValues ?: []).length()} secret(s)`);

    BatchGetSecretValueResponse wrongValueCase = check secretmanagerClient->batchGetSecretValue(
            filters = [{'key: "tag-value", values: ["Unit-Test"]}]);
    test:assertTrue(wrongValueCase.secretValues is (),
            string `a mixed-case tag-value matched ${(wrongValueCase.secretValues ?: []).length()} secret(s)`);
}

// `all` searches every filterable field, not just the name. Each value below is chosen to sit in exactly one field,
// so a match proves that field is reached — none of them would match under a name-only search.
@test:Config {groups: ["batchGetSecretValue"], enable: !isLiveServer}
function testAllFilterSearchesEveryField() returns error? {
    // Description: shared by both tagged fixtures, absent from the minimal one.
    check assertAllFilterMatches("aws.secretmanager tests", 2);
    // Owning service.
    check assertAllFilterMatches("owning-service", 2);
    // Primary region.
    check assertAllFilterMatches("us-east-1", 2);
    // A tag key only the richer fixture carries.
    check assertAllFilterMatches(MOCK_SECOND_TAG_KEY, 1);
    // A tag value only the richer fixture carries.
    check assertAllFilterMatches(MOCK_SECOND_TAG_VALUE, 1);
    // And the name, which is all the filter used to look at.
    check assertAllFilterMatches("binary", 1);
}

// The three field-specific keys that had no branch at all, so every request naming one matched nothing.
@test:Config {groups: ["batchGetSecretValue"], enable: !isLiveServer}
function testFieldSpecificFiltersForConditionalFields() returns error? {
    check assertFilterMatches("description", "Mock secret", 2);
    check assertFilterMatches("owning-service", "mock-owning", 2);
    check assertFilterMatches("primary-region", "us-east", 2);

    // Still prefix-anchored, unlike `all`: this substring sits mid-field.
    check assertFilterMatches("owning-service", "owning-service", 0);
}

// `all` matches anywhere in a field; the field-specific keys match only at the start. This is the one asymmetry
// between them, so it is worth pinning rather than leaving to the reader.
@test:Config {groups: ["batchGetSecretValue"], enable: !isLiveServer}
function testAllFilterMatchesMidFieldWhereNameDoesNot() returns error? {
    check assertAllFilterMatches("app/credentials", 1);
    check assertFilterMatches("name", "app/credentials", 0);
}

function assertAllFilterMatches(string value, int expected) returns error? {
    return assertFilterMatches("all", value, expected);
}

// Runs one filter and asserts how many secrets it returned. An empty result arrives as an absent `secretValues`
// rather than an empty array, so zero is checked against that.
function assertFilterMatches(FilterKey key, string value, int expected) returns error? {
    BatchGetSecretValueResponse response = check secretmanagerClient->batchGetSecretValue(
            filters = [{'key: key, values: [value]}]);
    SecretValue[] secretValues = response.secretValues ?: [];
    if secretValues.length() != expected {
        string names = (from SecretValue secret in secretValues
            select secret.name).toString();
        test:assertFail(string `filter ${key}='${value}' matched ${secretValues.length()} secret(s) ` +
                string `${names}, expected ${expected}`);
    }
}

// A token the service never issued has to be rejected, not quietly answered with the first page. The silent-fallback
// version of this made a mangled token indistinguishable from a token that paged to the wrong place.
@test:Config {groups: ["batchGetSecretValue"], enable: !isLiveServer}
function testInvalidNextTokenIsRejected() returns error? {
    BatchGetSecretValueResponse|Error response = secretmanagerClient->batchGetSecretValue(
            filters = [{'key: "tag-key", values: [MOCK_TAG_KEY]}], nextToken = "not-a-real-token");
    if response !is Error {
        test:assertFail(string `a fabricated nextToken returned ` +
                (response.secretValues ?: []).length().toString() + " secret value(s) instead of failing");
    }
    test:assertEquals(response.detail().httpStatusCode, 400);
}

// A token carrying the right prefix but an unusable offset is just as invalid — the prefix check alone let this
// through as offset 0.
@test:Config {groups: ["batchGetSecretValue"], enable: !isLiveServer}
function testMalformedNextTokenOffsetIsRejected() returns error? {
    BatchGetSecretValueResponse|Error response = secretmanagerClient->batchGetSecretValue(
            filters = [{'key: "tag-key", values: [MOCK_TAG_KEY]}], nextToken = MOCK_NEXT_TOKEN + "-not-a-number");
    if response !is Error {
        test:assertFail("a nextToken with a non-numeric offset was accepted");
    }
    test:assertEquals(response.detail().httpStatusCode, 400);
}

// One real ID and one missing one in the same request. The service answers 200 with the good value in `secretValues`
// and the bad one in `errors` — the only place a `secretmanager:ApiError` is produced.
@test:Config {groups: ["batchGetSecretValue"], enable: !isLiveServer}
function testBatchGetSecretValueReportsPerSecretErrors() returns error? {
    BatchGetSecretValueResponse response = check secretmanagerClient->batchGetSecretValue(
            secretIds = [MOCK_SECRET_NAME, MOCK_MISSING_SECRET_NAME]);

    SecretValue[]? secretValues = response.secretValues;
    if secretValues is () {
        test:assertFail("the good secret in a partly failing batch was not returned");
    }
    test:assertEquals(secretValues.length(), 1);
    test:assertEquals(secretValues[0].name, MOCK_SECRET_NAME);

    ApiError[]? errors = response.errors;
    if errors is () {
        test:assertFail("the missing secret in a partly failing batch was not reported");
    }
    test:assertEquals(errors.length(), 1);
    test:assertEquals(errors[0].secretId, MOCK_MISSING_SECRET_NAME);
    test:assertEquals(errors[0].errorCode, RESOURCE_NOT_FOUND);
}

// A service failure has to reach Ballerina as a `secretmanager:Error` carrying `aws:ErrorDetails` — the shared detail
// record every AWS connector was moved onto.
@test:Config {groups: ["errors"]}
function testMissingSecretIsReported() returns error? {
    DescribeSecretResponse|Error response = secretmanagerClient->describeSecret(MOCK_MISSING_SECRET_NAME);
    if response !is Error {
        test:assertFail("describing a secret that does not exist succeeded");
    }
    aws:ErrorDetails details = response.detail();
    test:assertEquals(details.httpStatusCode, 400);
    test:assertEquals(details.errorCode, RESOURCE_NOT_FOUND);
    test:assertTrue(details.requestId is string, "a service error must carry a request id");
}

// The secret exists but the version does not, so the service reports it separately — which confirms the version
// selector reached it rather than being dropped on the way.
@test:Config {groups: ["errors"], enable: !isLiveServer}
function testUnknownVersionIsReported() returns error? {
    SecretValue|Error secret = secretmanagerClient->getSecretValue(
            MOCK_SECRET_NAME, versionId = "99999999-9999-9999-9999-999999999999");
    if secret !is Error {
        test:assertFail("getSecretValue with an unknown versionId succeeded");
    }
    test:assertEquals(secret.detail().httpStatusCode, 400);
}

// Credentials the mock does not recognise, to see the signature rejected rather than the request.
@test:Config {groups: ["errors"], enable: !isLiveServer}
function testUnexpectedCredentialsAreRejected() returns error? {
    Client badClient = check newTestClient(unexpectedAuth);
    SecretValue|Error secret = badClient->getSecretValue(MOCK_SECRET_NAME);
    check badClient.close();
    if secret !is Error {
        test:assertFail("a request signed with unexpected credentials succeeded");
    }
    test:assertEquals(secret.detail().httpStatusCode, 403);
}
