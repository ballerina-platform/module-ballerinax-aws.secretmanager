/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com)
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.lib.aws.secretmanager;

import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.AwsCredentials;
import software.amazon.awssdk.auth.credentials.AwsCredentialsProvider;
import software.amazon.awssdk.auth.credentials.AwsSessionCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.services.secretsmanager.SecretsManagerClient;

import java.util.Objects;

/**
 * Representation of {@link software.amazon.awssdk.services.secretsmanager.SecretsManagerClient} with
 * utility methods to invoke as inter-op functions.
 */
public class NativeClientAdaptor {
//    private static final ExecutorService EXECUTOR_SERVICE = Executors.newCachedThreadPool(new AwsMpeThreadFactory());

    private NativeClientAdaptor() {
    }

    /**
     * Creates an AWS Secret Manager native client with the provided configurations.
     *
     * @param bAwsSecretMngClient The Ballerina AWS Secret Manager client object.
     * @param configurations AWS Secret Manager client connection configurations.
     * @return A Ballerina `secretmanager:Error` if failed to initialize the native client with the provided
     * configurations.
     */
    public static Object init(BObject bAwsSecretMngClient, BMap<BString, Object> configurations) {
        try {
            ConnectionConfig connectionConfig = new ConnectionConfig(configurations);
            AwsCredentials credentials = getCredentials(connectionConfig);
            AwsCredentialsProvider credentialsProvider = StaticCredentialsProvider.create(credentials);
            SecretsManagerClient nativeClient = SecretsManagerClient.builder()
                    .credentialsProvider(credentialsProvider)
                    .region(connectionConfig.region()).build();
            bAwsSecretMngClient.addNativeData(Constants.NATIVE_CLIENT, nativeClient);
        } catch (Exception e) {
            String errorMsg = String.format("Error occurred while initializing the AWS secret manager client: %s",
                    e.getMessage());
            return CommonUtils.createError(errorMsg, e);
        }
        return null;
    }

    private static AwsCredentials getCredentials(ConnectionConfig connectionConfig) {
        if (Objects.nonNull(connectionConfig.sessionToken())) {
            return AwsSessionCredentials.create(connectionConfig.accessKeyId(), connectionConfig.secretAccessKey(),
                    connectionConfig.sessionToken());
        } else {
            return AwsBasicCredentials.create(connectionConfig.accessKeyId(), connectionConfig.secretAccessKey());
        }
    }

    /**
     * Closes the AWS Secret Manager client native resources.
     *
     * @param bAwsSecretMngClient The Ballerina AWS Secret Manager client object.
     * @return A Ballerina `secretmanager:Error` if failed to close the underlying resources.
     */
    public static Object close(BObject bAwsSecretMngClient) {
        SecretsManagerClient nativeClient = (SecretsManagerClient) bAwsSecretMngClient
                .getNativeData(Constants.NATIVE_CLIENT);
        try {
            nativeClient.close();
        } catch (Exception e) {
            String errorMsg = String.format("Error occurred while closing the AWS secret manager client: %s",
                    e.getMessage());
            return CommonUtils.createError(errorMsg, e);
        }
        return null;
    }
}
