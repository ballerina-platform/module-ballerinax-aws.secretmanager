// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.com).
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

import ballerina/jballerina.java;

# AWS Secret Manger client.
public isolated client class Client {

    # Initialize the Ballerina AWS Secret Manger client.
    # ```ballerina
    # secretmanager:Client secretmanager = check new(region = secretmanager:US_EAST_1, auth = {
    #   accessKeyId: "<aws-access-key>",
    #   secretAccessKey: "<aws-secret-key>"
    # });
    # ```
    #
    # + configs - The AWS Secret Manager client configurations
    # + return - The `secretmanager:Client` or an `secretmanager:Error` if the initialization failed
    public isolated function init(*ConnectionConfig configs) returns Error? {
        return self.externInit(configs);
    }

    isolated function externInit(ConnectionConfig configs) returns Error? =
    @java:Method {
        name: "init",
        'class: "io.ballerina.lib.aws.secretmanager.NativeClientAdaptor"
    } external;

    # Closes the AWS Secret Manager client resources.
    # ```ballerina
    # check secretmanager->close();
    # ```
    # 
    # + return - A `secretmanager:Error` if there is an error while closing the client resources or else nil
    remote function close() returns Error? =
    @java:Method {
        'class: "io.ballerina.lib.aws.secretmanager.NativeClientAdaptor"
    } external;
}
