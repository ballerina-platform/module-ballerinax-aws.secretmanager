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

import ballerina/http;

// Secrets Manager speaks AWS JSON 1.1, so the mock is a single POST resource that dispatches on `X-Amz-Target` —
// the same shape the real service presents. The client reaches it through `endpoint.customEndpoint`, which means the
// AWS SDK still builds, signs and unmarshals every request: only the host changes.
import ballerina/lang.array;

const int MOCK_SERVER_PORT = 9532;
final string mockServerUrl = string `http://localhost:${MOCK_SERVER_PORT}`;

const string AWS_JSON_CONTENT_TYPE = "application/x-amz-json-1.1";
const string TARGET_PREFIX = "secretsmanager.";
const string DESCRIBE_SECRET_TARGET = TARGET_PREFIX + "DescribeSecret";
const string GET_SECRET_VALUE_TARGET = TARGET_PREFIX + "GetSecretValue";
const string BATCH_GET_SECRET_VALUE_TARGET = TARGET_PREFIX + "BatchGetSecretValue";

const string MOCK_ACCESS_KEY_ID = "mock-access-key-id";
const string MOCK_SECRET_ACCESS_KEY = "mock-secret-access-key";
const string SIGV4_ALGORITHM = "AWS4-HMAC-SHA256";

const string MOCK_REQUEST_ID = "mock-request-id";
const string MOCK_REGION = "us-east-1";
const string MOCK_ACCOUNT = "000000000000";

// The string secret, which carries two versions so the version selectors have something to distinguish.
const string MOCK_SECRET_NAME = "mock/app/credentials";
const string MOCK_SECRET_DESCRIPTION = "Mock secret for the aws.secretmanager tests";
const string MOCK_OWNING_SERVICE = "mock-owning-service";
const string MOCK_CURRENT_VERSION_ID = "11111111-1111-1111-1111-111111111111";
const string MOCK_PREVIOUS_VERSION_ID = "22222222-2222-2222-2222-222222222222";
// The value carries quotes, a multi-byte character and the characters most likely to be mangled by an encoding fault,
// so a value that did not survive the JSON protocol unchanged shows up as an inequality rather than as a crash.
const string MOCK_CURRENT_SECRET_STRING = "{\"username\":\"admin\",\"password\":\"p@ss w+rd/=héllo 日本\"}";
const string MOCK_PREVIOUS_SECRET_STRING = "{\"username\":\"admin\",\"password\":\"first-value\"}";

// The binary secret. These bytes are deliberately not valid UTF-8, which is what makes the real service store the
// value under `SecretBinary` — the only way to reach the `byte[]` arm of `SecretValue.value`.
const string MOCK_BINARY_SECRET_NAME = "mock/app/binary";
final readonly & byte[] MOCK_BINARY_SECRET_VALUE = [0x00, 0x01, 0xFF, 0xFE, 0x7F, 0x80, 0x41, 0x42];
const string MOCK_BINARY_VERSION_ID = "33333333-3333-3333-3333-333333333333";

// A secret whose `DescribeSecret` response omits every field the API documents as conditional — `Description`,
// `OwningService` and `PrimaryRegion` are only returned when they apply. The connector declares all three as
// *required* fields of `DescribeSecretResponse`, so this fixture is what shows whether a plain, unreplicated,
// customer-owned secret can be described at all.
const string MOCK_MINIMAL_SECRET_NAME = "mock/app/minimal";
const string MOCK_MINIMAL_VERSION_ID = "44444444-4444-4444-4444-444444444444";
const string MOCK_MINIMAL_SECRET_STRING = "minimal";

// A name no fixture answers to, for the error-mapping tests.
const string MOCK_MISSING_SECRET_NAME = "mock/app/no-such-secret";

const string RESOURCE_NOT_FOUND = "ResourceNotFoundException";
const string INVALID_PARAMETER = "InvalidParameterException";
const string INVALID_REQUEST = "InvalidRequestException";

// 2026-01-01T00:00:00Z and 2026-01-02T00:00:00Z as the epoch seconds the AWS JSON protocol uses for timestamps.
const int MOCK_CREATED_EPOCH = 1767225600;
const int MOCK_CHANGED_EPOCH = 1767312000;

const string MOCK_TAG_KEY = "purpose";
const string MOCK_TAG_VALUE = "unit-test";
const string MOCK_SECOND_TAG_KEY = "owner";
const string MOCK_SECOND_TAG_VALUE = "ballerina";

const string MOCK_KMS_KEY_ID = "arn:aws:kms:us-east-1:000000000000:key/mock-key";
const string MOCK_ROTATION_LAMBDA_ARN = "arn:aws:lambda:us-east-1:000000000000:function:mock-rotator";
const string MOCK_ROTATION_SCHEDULE = "rate(30 days)";
const int MOCK_ROTATION_AFTER_DAYS = 30;

// The token handed out for the first page of a filtered batch read, and expected back on the second.
const string MOCK_NEXT_TOKEN = "mock-next-token";

// One version of one secret, as the mock holds it.
type MockSecretVersion record {|
    string versionId;
    string[] versionStages;
    // Exactly one of the two is set, mirroring the service.
    string? secretString = ();
    byte[]? secretBinary = ();
|};

type MockSecret record {|
    string name;
    // Set only when the fixture reports them, so a `()` means the field is absent from the response rather than empty.
    string? description = ();
    string? owningService = ();
    string? primaryRegion = ();
    boolean rotationEnabled = false;
    map<string> tags = {};
    // Extra metadata the richer fixture reports, to exercise the optional-field mapping.
    boolean includeOptionalMetadata = false;
    MockSecretVersion[] versions;
|};

final readonly & map<MockSecret> mockSecrets = {
    [MOCK_SECRET_NAME]: {
        name: MOCK_SECRET_NAME,
        description: MOCK_SECRET_DESCRIPTION,
        owningService: MOCK_OWNING_SERVICE,
        primaryRegion: MOCK_REGION,
        rotationEnabled: true,
        tags: {[MOCK_TAG_KEY]: MOCK_TAG_VALUE, [MOCK_SECOND_TAG_KEY]: MOCK_SECOND_TAG_VALUE},
        includeOptionalMetadata: true,
        versions: [
            {
                versionId: MOCK_CURRENT_VERSION_ID,
                versionStages: ["AWSCURRENT"],
                secretString: MOCK_CURRENT_SECRET_STRING
            },
            {
                versionId: MOCK_PREVIOUS_VERSION_ID,
                versionStages: ["AWSPREVIOUS"],
                secretString: MOCK_PREVIOUS_SECRET_STRING
            }
        ]
    },
    [MOCK_BINARY_SECRET_NAME]: {
        name: MOCK_BINARY_SECRET_NAME,
        description: MOCK_SECRET_DESCRIPTION,
        owningService: MOCK_OWNING_SERVICE,
        primaryRegion: MOCK_REGION,
        tags: {[MOCK_TAG_KEY]: MOCK_TAG_VALUE},
        versions: [
            {
                versionId: MOCK_BINARY_VERSION_ID,
                versionStages: ["AWSCURRENT"],
                secretBinary: MOCK_BINARY_SECRET_VALUE
            }
        ]
    },
    [MOCK_MINIMAL_SECRET_NAME]: {
        name: MOCK_MINIMAL_SECRET_NAME,
        versions: [
            {
                versionId: MOCK_MINIMAL_VERSION_ID,
                versionStages: ["AWSCURRENT"],
                secretString: MOCK_MINIMAL_SECRET_STRING
            }
        ]
    }
};

final http:Listener mockListener = check new (MOCK_SERVER_PORT);

final http:Service mockService = service object {

    isolated resource function post .(http:Request request) returns http:Response|error {
        http:Response? authFailure = validateSigV4Credential(request);
        if authFailure is http:Response {
            return authFailure;
        }
        string target = check request.getHeader("X-Amz-Target");
        byte[] rawPayload = check request.getBinaryPayload();
        json payload = check (check string:fromBytes(rawPayload)).fromJsonString();

        match target {
            DESCRIBE_SECRET_TARGET => {
                return describeSecretResponse(payload);
            }
            GET_SECRET_VALUE_TARGET => {
                return getSecretValueResponse(payload);
            }
            BATCH_GET_SECRET_VALUE_TARGET => {
                return batchGetSecretValueResponse(payload);
            }
        }
        return awsErrorResponse(400, "UnknownOperationException", string `unsupported target: ${target}`);
    }
};

// The SDK signs every request, so an `Authorization` header naming the expected access key is proof that credential
// resolution and SigV4 signing both ran. The signature itself is not recomputed — that is the SDK's own well-tested
// code, and re-deriving it here would test the test.
isolated function validateSigV4Credential(http:Request request) returns http:Response? {
    string|error authorization = request.getHeader("Authorization");
    if authorization is error {
        return awsErrorResponse(403, "MissingAuthenticationTokenException",
                "Request is missing Authentication Token");
    }
    if !authorization.startsWith(SIGV4_ALGORITHM + " ")
            || !authorization.includes(string `Credential=${MOCK_ACCESS_KEY_ID}/`) {
        return awsErrorResponse(403, "InvalidSignatureException",
                "The request signature we calculated does not match the signature you provided");
    }
    return ();
}

isolated function describeSecretResponse(json payload) returns http:Response {
    string|error secretId = payload.SecretId.ensureType();
    if secretId is error {
        return awsErrorResponse(400, INVALID_PARAMETER, "SecretId is required");
    }
    MockSecret|http:Response secret = lookupSecret(secretId);
    if secret is http:Response {
        return secret;
    }

    map<json> response = {
        "ARN": secretArn(secret.name),
        "Name": secret.name,
        "CreatedDate": MOCK_CREATED_EPOCH,
        "RotationEnabled": secret.rotationEnabled,
        "VersionIdsToStages": versionIdsToStages(secret)
    };
    // The conditional fields. Each is present only when the fixture has it, which is how the `minimal` fixture
    // reproduces the shape of a plain, unreplicated, customer-owned secret.
    string? description = secret.description;
    if description is string {
        response["Description"] = description;
    }
    string? owningService = secret.owningService;
    if owningService is string {
        response["OwningService"] = owningService;
    }
    string? primaryRegion = secret.primaryRegion;
    if primaryRegion is string {
        response["PrimaryRegion"] = primaryRegion;
    }
    if secret.tags.length() > 0 {
        json[] tags = [];
        foreach [string, string] [key, value] in secret.tags.entries() {
            tags.push({"Key": key, "Value": value});
        }
        response["Tags"] = tags;
    }
    if secret.includeOptionalMetadata {
        response["KmsKeyId"] = MOCK_KMS_KEY_ID;
        response["LastChangedDate"] = MOCK_CHANGED_EPOCH;
        response["LastAccessedDate"] = MOCK_CHANGED_EPOCH;
        response["LastRotatedDate"] = MOCK_CHANGED_EPOCH;
        response["NextRotationDate"] = MOCK_CHANGED_EPOCH;
        response["RotationLambdaARN"] = MOCK_ROTATION_LAMBDA_ARN;
        response["RotationRules"] = {
            "AutomaticallyAfterDays": MOCK_ROTATION_AFTER_DAYS,
            "Duration": "2h",
            "ScheduleExpression": MOCK_ROTATION_SCHEDULE
        };
        response["ReplicationStatus"] = [
            {
                "KmsKeyId": MOCK_KMS_KEY_ID,
                "LastAccessedDate": MOCK_CHANGED_EPOCH,
                "Region": "us-west-2",
                "Status": "InSync",
                "StatusMessage": "Replication succeeded"
            }
        ];
    }
    return awsJsonResponse(response);
}

isolated function getSecretValueResponse(json payload) returns http:Response {
    string|error secretId = payload.SecretId.ensureType();
    if secretId is error {
        return awsErrorResponse(400, INVALID_PARAMETER, "SecretId is required");
    }
    MockSecret|http:Response secret = lookupSecret(secretId);
    if secret is http:Response {
        return secret;
    }

    string? requestedVersionId = optionalString(payload, "VersionId");
    string? requestedVersionStage = optionalString(payload, "VersionStage");

    // Both selectors together are accepted as long as they name the same version — the service requires that they
    // "refer to the same secret version" rather than rejecting the pair outright. `selectVersion` resolves by ID when
    // one is given, so the stage is checked against the version that ID resolved to.
    MockSecretVersion? version = selectVersion(secret, requestedVersionId, requestedVersionStage);
    if version is () {
        // The secret exists but the requested version does not — the service's own distinction, and the only way to
        // tell a version selector that arrived from one that was dropped.
        string requested = requestedVersionId ?: (requestedVersionStage ?: "AWSCURRENT");
        return awsErrorResponse(400, RESOURCE_NOT_FOUND,
                string `Secrets Manager can't find the specified secret version '${requested}'.`);
    }
    if requestedVersionId is string && requestedVersionStage is string
            && version.versionStages.indexOf(requestedVersionStage) is () {
        return awsErrorResponse(400, INVALID_PARAMETER,
                "VersionId and VersionStage must refer to the same secret version");
    }
    return awsJsonResponse(secretValuePayload(secret, version));
}

isolated function batchGetSecretValueResponse(json payload) returns http:Response {
    json|error secretIdList = payload.SecretIdList;
    json|error filters = payload.Filters;
    if secretIdList is json[] && filters is json[] {
        return awsErrorResponse(400, INVALID_PARAMETER,
                "Either 'SecretIdList' or 'Filters' must be provided, but not both.");
    }

    int? maxResults = optionalInt(payload, "MaxResults");
    if maxResults is int && secretIdList is json[] {
        // The service only accepts `MaxResults` alongside `Filters`, which is what the connector's docs say.
        return awsErrorResponse(400, INVALID_PARAMETER, "MaxResults is only supported with Filters.");
    }

    if secretIdList is json[] {
        return batchByIds(secretIdList);
    }
    if filters is json[] {
        return batchByFilters(filters, maxResults, optionalString(payload, "NextToken"));
    }
    return awsErrorResponse(400, INVALID_PARAMETER, "Either 'SecretIdList' or 'Filters' must be provided.");
}

// Addressing by ID: every ID that resolves contributes to `SecretValues`, and every one that does not contributes to
// `Errors`. A batch that mixes the two answers 200 with both populated rather than failing, which is the only way a
// per-secret `ApiError` is ever produced.
isolated function batchByIds(json[] secretIdList) returns http:Response {
    json[] secretValues = [];
    json[] errors = [];
    foreach json id in secretIdList {
        string secretId = id.toString();
        MockSecret? secret = resolveSecret(secretId);
        if secret is () {
            errors.push({
                "ErrorCode": RESOURCE_NOT_FOUND,
                "Message": "Secrets Manager can't find the specified secret.",
                "SecretId": secretId
            });
            continue;
        }
        MockSecretVersion? current = selectVersion(secret, (), ());
        if current is MockSecretVersion {
            secretValues.push(secretValuePayload(secret, current));
        }
    }
    map<json> response = {"SecretValues": secretValues};
    if errors.length() > 0 {
        response["Errors"] = errors;
    }
    return awsJsonResponse(response);
}

// Addressing by filter. Every key in the connector's `FilterKey` union is implemented: the field-specific ones as
// case-sensitive prefix matches on their own field, and `all` as a search across all of them.
isolated function batchByFilters(json[] filters, int? maxResults, string? nextToken) returns http:Response {
    MockSecret[] matched = [];
    foreach MockSecret secret in mockSecrets {
        if matchesAllFilters(secret, filters) {
            matched.push(secret);
        }
    }
    // A stable order, so paging is deterministic.
    MockSecret[] ordered = matched.sort("ascending", secret => secret.name);

    // The token is the number of entries already served, so feeding it back has to skip them. A token this mock never
    // issued is rejected rather than quietly serving the first page: the real service reports a bad token, and a
    // silent fallback would make a connector that mangled the token look like one that merely paged wrong.
    int offset = 0;
    if nextToken is string {
        int? parsed = tokenOffset(nextToken);
        if parsed is () || parsed > ordered.length() {
            return awsErrorResponse(400, INVALID_REQUEST, "The NextToken is invalid.");
        }
        offset = parsed;
    }
    MockSecret[] page = ordered.slice(offset);
    int pageSize = maxResults ?: page.length();
    boolean truncated = page.length() > pageSize;
    if truncated {
        page = page.slice(0, pageSize);
    }

    json[] secretValues = [];
    foreach MockSecret secret in page {
        MockSecretVersion? current = selectVersion(secret, (), ());
        if current is MockSecretVersion {
            secretValues.push(secretValuePayload(secret, current));
        }
    }
    map<json> response = {"SecretValues": secretValues};
    if truncated {
        response["NextToken"] = string `${MOCK_NEXT_TOKEN}-${offset + page.length()}`;
    }
    return awsJsonResponse(response);
}

isolated function matchesAllFilters(MockSecret secret, json[] filters) returns boolean {
    foreach json filter in filters {
        if filter !is map<json> {
            return false;
        }
        string key = (filter["Key"] ?: "").toString();
        json values = filter["Values"] ?: [];
        if values !is json[] {
            return false;
        }
        boolean matched = false;
        foreach json value in values {
            if filterMatches(secret, key, value.toString()) {
                matched = true;
                break;
            }
        }
        if !matched {
            return false;
        }
    }
    return true;
}

// A filter value is a case-sensitive prefix of the field it is compared against, whichever field that is — so
// `tag-key` and `tag-value` match the same way `name` does, against any one of the secret's tags. `startsWith` is
// case-sensitive already, so the case rule needs nothing beyond using it.
isolated function filterMatches(MockSecret secret, string key, string value) returns boolean {
    match key {
        "tag-key" => {
            foreach string tagKey in secret.tags.keys() {
                if tagKey.startsWith(value) {
                    return true;
                }
            }
            return false;
        }
        "tag-value" => {
            foreach string tagValue in secret.tags {
                if tagValue.startsWith(value) {
                    return true;
                }
            }
            return false;
        }
        "name" => {
            return secret.name.startsWith(value);
        }
        "description" => {
            return startsWithOrFalse(secret.description, value);
        }
        "owning-service" => {
            return startsWithOrFalse(secret.owningService, value);
        }
        "primary-region" => {
            return startsWithOrFalse(secret.primaryRegion, value);
        }
        "all" => {
            // `all` searches every filterable field rather than only the name, so a secret that matches any
            // field-specific key matches `all` too. It is the one key that matches anywhere in a field rather than at
            // the start, which is what makes it a catch-all.
            foreach string 'field in searchableFields(secret) {
                if 'field.includes(value) {
                    return true;
                }
            }
            return false;
        }
    }
    return false;
}

// An absent optional field matches nothing, rather than matching an empty prefix.
isolated function startsWithOrFalse(string? candidate, string value) returns boolean =>
    candidate is string && candidate.startsWith(value);

// Every field the `all` key searches: the ones each field-specific key addresses. Absent optional fields contribute
// nothing.
isolated function searchableFields(MockSecret secret) returns string[] {
    string[] fields = [secret.name];
    foreach string? optionalField in [secret.description, secret.owningService, secret.primaryRegion] {
        if optionalField is string {
            fields.push(optionalField);
        }
    }
    foreach [string, string] [tagKey, tagValue] in secret.tags.entries() {
        fields.push(tagKey);
        fields.push(tagValue);
    }
    return fields;
}

// The offset a token encodes, or `()` when the token is not one this mock handed out — a wrong prefix, no `-N` suffix,
// a suffix that is not a number, or a negative one.
isolated function tokenOffset(string nextToken) returns int? {
    if !nextToken.startsWith(MOCK_NEXT_TOKEN + "-") {
        return ();
    }
    int|error offset = int:fromString(nextToken.substring((MOCK_NEXT_TOKEN + "-").length()));
    if offset is error || offset < 0 {
        return ();
    }
    return offset;
}

// `GetSecretValue` and `BatchGetSecretValue` return the same entry shape, so both go through this.
isolated function secretValuePayload(MockSecret secret, MockSecretVersion version) returns map<json> {
    map<json> payload = {
        "ARN": secretArn(secret.name),
        "Name": secret.name,
        "CreatedDate": MOCK_CREATED_EPOCH,
        "VersionId": version.versionId,
        "VersionStages": version.versionStages
    };
    string? secretString = version.secretString;
    byte[]? secretBinary = version.secretBinary;
    if secretString is string {
        payload["SecretString"] = secretString;
    } else if secretBinary is byte[] {
        // A blob travels base64-encoded in AWS JSON.
        payload["SecretBinary"] = array:toBase64(secretBinary);
    }
    return payload;
}

// Accepts a name or a full ARN, which is what the API means by `SecretId`.
isolated function resolveSecret(string secretId) returns MockSecret? {
    if mockSecrets.hasKey(secretId) {
        return mockSecrets[secretId];
    }
    foreach MockSecret secret in mockSecrets {
        if secretArn(secret.name) == secretId {
            return secret;
        }
    }
    return ();
}

isolated function lookupSecret(string secretId) returns MockSecret|http:Response {
    MockSecret? secret = resolveSecret(secretId);
    if secret is () {
        return awsErrorResponse(400, RESOURCE_NOT_FOUND, "Secrets Manager can't find the specified secret.");
    }
    return secret;
}

// `()` for both selectors means `AWSCURRENT`, which is the service's default.
isolated function selectVersion(MockSecret secret, string? versionId, string? versionStage)
        returns MockSecretVersion? {
    foreach MockSecretVersion version in secret.versions {
        if versionId is string {
            if version.versionId == versionId {
                return version;
            }
            continue;
        }
        string wanted = versionStage ?: "AWSCURRENT";
        if version.versionStages.indexOf(wanted) !is () {
            return version;
        }
    }
    return ();
}

isolated function versionIdsToStages(MockSecret secret) returns map<json> {
    map<json> stages = {};
    foreach MockSecretVersion version in secret.versions {
        stages[version.versionId] = version.versionStages;
    }
    return stages;
}

isolated function secretArn(string name) returns string =>
    string `arn:aws:secretsmanager:${MOCK_REGION}:${MOCK_ACCOUNT}:secret:${name}-AbCdEf`;

isolated function optionalString(json payload, string key) returns string? {
    if payload !is map<json> {
        return ();
    }
    json? value = payload[key];
    return value is string ? value : ();
}

isolated function optionalInt(json payload, string key) returns int? {
    if payload !is map<json> {
        return ();
    }
    json? value = payload[key];
    return value is int ? value : ();
}

isolated function awsJsonResponse(json payload) returns http:Response {
    http:Response response = new;
    response.statusCode = http:STATUS_OK;
    response.setHeader("x-amzn-RequestId", MOCK_REQUEST_ID);
    response.setJsonPayload(payload, AWS_JSON_CONTENT_TYPE);
    return response;
}

isolated function awsErrorResponse(int statusCode, string errorType, string message) returns http:Response {
    http:Response response = new;
    response.statusCode = statusCode;
    response.setHeader("x-amzn-RequestId", MOCK_REQUEST_ID);
    response.setHeader("x-amzn-ErrorType", errorType);
    response.setJsonPayload({"__type": errorType, "message": message}, AWS_JSON_CONTENT_TYPE);
    return response;
}
