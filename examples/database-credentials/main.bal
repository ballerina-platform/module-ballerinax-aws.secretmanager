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
    DatabaseSecret credentials = check rawValue.fromJsonStringWithType();

    // Everything the secret carries except the password is safe to log.
    DatabaseSecret redacted = credentials.clone();
    redacted.password = "<redacted>";
    io:println("Credentials: ", redacted);

    // Rotation replaces the credentials without the application restarting, so a
    // client that suddenly fails to authenticate with `AWSCURRENT` can retry with
    // the version the label `AWSPREVIOUS` still points at. That label is absent
    // until the secret has been rotated at least once, which is why the error is
    // reported rather than propagated.
    secretmanager:SecretValue|secretmanager:Error previous =
        secretManager->getSecretValue(secretId, versionStage = "AWSPREVIOUS");
    if previous is secretmanager:Error {
        io:println("No 'AWSPREVIOUS' version to fall back on: ", previous.message());
    } else {
        io:println(string `Previous version available for fallback: '${previous.versionId}'.`);
    }
}
