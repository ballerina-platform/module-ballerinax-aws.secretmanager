// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
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

import ballerina/io;
import ballerina/time;
import ballerinax/aws.secretmanager;

configurable string accessKeyId = ?;
configurable string secretAccessKey = ?;
configurable string region = "us-east-1";

configurable string tagKey = ?;
configurable int rotationSlaDays = 90;

public function main() returns error? {
    secretmanager:Client secretManager = check new ({
        auth: {accessKeyId, secretAccessKey},
        region: region
    });

    string[] secretNames = check discoverSecretsByTagKey(secretManager, tagKey);
    if secretNames.length() == 0 {
        io:println(string `No secret in ${region} carries the tag key '${tagKey}'.`);
        return;
    }
    io:println(string `Auditing ${secretNames.length()} secret(s) tagged '${tagKey}'.`, "\n");

    int breaches = 0;
    foreach string name in secretNames {
        // `describeSecret` returns the metadata without the encrypted value, so the
        // audit reads the rotation configuration without decrypting anything.
        secretmanager:DescribeSecretResponse details = check secretManager->describeSecret(name);

        // Secrets Manager omits a field that has no value, so every date and the
        // rotation schedule are optional even when rotation is turned on.
        time:Utc? lastRotated = details.lastRotatedDate;
        time:Utc? lastChanged = details.lastChangedDate;
        int? ageInDays = lastRotated is time:Utc ? daysSince(lastRotated) : ();
        boolean overdue = ageInDays is int && ageInDays > rotationSlaDays;

        // A secret that has never rotated is as much of a finding as one that
        // rotated too long ago, so both count against the SLA.
        boolean withinSla = details.rotationEnabled && ageInDays is int && !overdue;
        if !withinSla {
            breaches += 1;
        }

        string rotation = details.rotationEnabled ? "enabled" : "not enabled";
        string rotated = lastRotated is time:Utc && ageInDays is int
            ? string `${time:utcToString(lastRotated)} (${ageInDays} days ago)`
            : "never";
        string changed = lastChanged is time:Utc ? time:utcToString(lastChanged) : "unknown";

        io:println(details.name);
        io:println(string `  rotation     : ${rotation}${describeSchedule(details.rotationRules)}`);
        io:println(string `  last rotated : ${rotated}`);
        io:println(string `  last changed : ${changed}`);
        io:println(string `  within SLA   : ${withinSla ? "yes" : "no"}`, "\n");
    }

    io:println(string `${breaches} of ${secretNames.length()} secret(s) are outside `
        + string `the ${rotationSlaDays}-day rotation SLA.`);
}

# Collects the names of every secret carrying the given tag key.
#
# The connector exposes no `listSecrets` operation, so a filtered
# `batchGetSecretValue` is what discovers a group of secrets. It decrypts the
# values as it goes — the caller therefore needs `secretsmanager:GetSecretValue`
# on each secret — and the values are dropped here, since the audit only needs
# the names.
#
# + secretManager - The Secrets Manager client
# + tagKey - The tag key every audited secret carries
# + return - The names of the matching secrets, or an error if a page could not be read
isolated function discoverSecretsByTagKey(secretmanager:Client secretManager, string tagKey) returns string[]|error {
    string[] names = [];
    // A page holds at most 20 secrets, and `nextToken` carries the position of the
    // next one. It can be returned even for a page that matched nothing, so the
    // loop follows the token rather than stopping at the first empty page.
    string? nextToken = ();
    boolean morePages = true;
    while morePages {
        secretmanager:BatchGetSecretValueRequest request = {
            filters: [{'key: "tag-key", values: [tagKey]}],
            maxResults: 20
        };
        if nextToken is string {
            request.nextToken = nextToken;
        }
        secretmanager:BatchGetSecretValueResponse page = check secretManager->batchGetSecretValue(request);

        // An individual secret can fail — a KMS key the caller cannot use, say —
        // while the rest of the page succeeds, so those failures are reported per
        // secret instead of failing the call.
        foreach secretmanager:ApiError apiError in page.errors ?: [] {
            string reason = apiError.message ?: apiError.errorCode ?: "unknown error";
            io:println(string `Skipping '${apiError.secretId ?: "<unknown>"}': ${reason}`);
        }
        foreach secretmanager:SecretValue secret in page.secretValues ?: [] {
            names.push(secret.name);
        }

        nextToken = page.nextToken;
        morePages = nextToken is string;
    }
    return names;
}

# Renders the rotation schedule as a parenthesised suffix, or an empty string when
# the secret has no schedule.
#
# + rules - The rotation rules of the secret, if any
# + return - The schedule description to append to the rotation status
isolated function describeSchedule(secretmanager:RotationRules? rules) returns string {
    if rules is () {
        return "";
    }
    int? afterDays = rules.automaticallyAfterDays;
    if afterDays is int {
        return string ` (every ${afterDays} days)`;
    }
    string? expression = rules.scheduleExpresssion;
    return expression is string ? string ` (${expression})` : "";
}

# Returns the whole number of days between the given instant and now.
#
# + instant - The instant to measure from
# + return - The number of whole days that have elapsed since the instant
isolated function daysSince(time:Utc instant) returns int {
    decimal seconds = time:utcDiffSeconds(time:utcNow(), instant);
    return <int>(seconds / 86400d).floor();
}
