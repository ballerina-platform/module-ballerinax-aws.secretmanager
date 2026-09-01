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

import ballerina/data.jsondata;
import ballerina/io;
import ballerinax/aws.secretmanager;

configurable string accessKeyId = ?;
configurable string secretAccessKey = ?;
configurable string region = "us-east-1";

configurable string secretId = ?;

// The JSON document that Secrets Manager stores for a database secret. Only
// `username` and `password` are always present; the connection details are filled
// in when the secret is attached to a database instance.
type DatabaseSecret record {|
    string username;
    string password;
    string engine?;
    string host?;
    int port?;
    string dbname?;
|};

public function main() returns error? {
    secretmanager:Client secretManager = check new ({
        auth: {accessKeyId, secretAccessKey},
        region: region
    });

    // `AWSCURRENT` is the staging label an application should read. It is also the
    // default, but naming it makes the intent explicit: while a rotation is in
    // flight the incoming value sits under `AWSPENDING`, and reading that would
    // hand the application credentials the database has not accepted yet.
    secretmanager:SecretValue secret = check secretManager->getSecretValue(secretId, versionStage = "AWSCURRENT");
    io:println(string `Read version '${secret.versionId}' of '${secret.name}'.`);

    // The value is a `byte[]` only for a secret stored as binary; a secret created
    // as a key/value pair or as a string arrives as a `string`.
    string|byte[] rawValue = secret.value;
    if rawValue !is string {
        return error(string `The secret '${secret.name}' holds binary data, not a JSON credential document.`);
    }
    // `jsondata:parseString` projects the document onto the record: a field the
    // record does not declare is dropped, where a direct conversion would instead
    // fail on it.
    DatabaseSecret credentials = check jsondata:parseString(rawValue);

    // Everything the secret carries except the password is safe to log.
    DatabaseSecret redacted = credentials.clone();
    redacted.password = "<redacted>";
    io:println("Credentials: ", redacted);

    // Rotation replaces the credentials without the application restarting, so a
    // client that suddenly fails to authenticate with `AWSCURRENT` can retry with
    // the version the label `AWSPREVIOUS` still points at. That label is absent
    // until the secret has been rotated at least once.
    secretmanager:SecretValue|secretmanager:Error previous =
        secretManager->getSecretValue(secretId, versionStage = "AWSPREVIOUS");
    if previous is secretmanager:SecretValue {
        io:println(string `Previous version available for fallback: '${previous.versionId}'.`);
    } else if previous.detail().errorCode == "ResourceNotFoundException" {
        // Secrets Manager reports a staging label that no version carries as a
        // missing resource, which here means the secret has yet to be rotated.
        io:println("No 'AWSPREVIOUS' version to fall back on.");
    } else {
        // Any other failure — access denied, throttling, or one that happened
        // before a response was received, leaving `errorCode` unset — says nothing
        // about whether the label exists, so it is not reported as its absence.
        return previous;
    }
}
