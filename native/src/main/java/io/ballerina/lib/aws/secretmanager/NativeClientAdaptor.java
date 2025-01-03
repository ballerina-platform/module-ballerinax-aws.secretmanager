/*
 * Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com)
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

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Future;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.AwsCredentials;
import software.amazon.awssdk.auth.credentials.AwsCredentialsProvider;
import software.amazon.awssdk.auth.credentials.AwsSessionCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.services.secretsmanager.SecretsManagerClient;
import software.amazon.awssdk.services.secretsmanager.model.BatchGetSecretValueRequest;
import software.amazon.awssdk.services.secretsmanager.model.BatchGetSecretValueResponse;
import software.amazon.awssdk.services.secretsmanager.model.DescribeSecretRequest;
import software.amazon.awssdk.services.secretsmanager.model.DescribeSecretResponse;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueRequest;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueResponse;

import java.util.Objects;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Representation of {@link software.amazon.awssdk.services.secretsmanager.SecretsManagerClient} with
 * utility methods to invoke as inter-op functions.
 */
public class NativeClientAdaptor {
    private static final ExecutorService EXECUTOR_SERVICE = Executors.newCachedThreadPool(
            new AwsSecretMngThreadFactory());

    private NativeClientAdaptor() {
    }

    /**
     * Creates an AWS Secret Manager native client with the provided configurations.
     *
     * @param bAwsSecretMngClient The Ballerina AWS Secret Manager client object.
     * @param configurations      AWS Secret Manager client connection configurations.
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
     * Retrieves the details of a secret. It does not include the encrypted secret value. Secrets Manager only returns
     * fields that have a value in the response.
     *
     * @param env                 The Ballerina runtime environment.
     * @param bAwsSecretMngClient The Ballerina AWS Secret Manager client object.
     * @param secretId            The ARN or name of the secret.
     * @return A Ballerina `secretmanager:Error` if there was an error while processing the request or else the AWS
     * Secret Manager `secretmanager:DescribeSecretResponse`.
     */
    public static Object describeSecret(Environment env, BObject bAwsSecretMngClient, BString secretId) {
        SecretsManagerClient nativeClient = (SecretsManagerClient) bAwsSecretMngClient
                .getNativeData(Constants.NATIVE_CLIENT);
        DescribeSecretRequest describeSecretRequest = DescribeSecretRequest.builder().secretId(secretId.getValue())
                .build();
        Future future = env.markAsync();
        EXECUTOR_SERVICE.execute(() -> {
            try {
                DescribeSecretResponse describeSecretResponse = nativeClient.describeSecret(describeSecretRequest);
                BMap<BString, Object> bResponse = CommonUtils.getDescribeSecretResponse(describeSecretResponse);
                future.complete(bResponse);
            } catch (Exception e) {
                String errorMsg = String.format("Error occurred while executing describe-secret request: %s",
                        e.getMessage());
                BError bError = CommonUtils.createError(errorMsg, e);
                future.complete(bError);
            }
        });
        return null;
    }

    /**
     * Retrieves the contents of the encrypted fields from the specified version of a secret.
     *
     * @param env                 The Ballerina runtime environment.
     * @param bAwsSecretMngClient The Ballerina AWS Secret Manager client object.
     * @param request             The Ballerina AWS Secret Manager `GetSecretValueRequest` request.
     * @return A Ballerina `secretmanager:Error` if there was an error while processing the request or else the AWS
     * Secret Manager `secretmanager:SecretValue`.
     */
    public static Object getSecretValue(Environment env, BObject bAwsSecretMngClient, BMap<BString, Object> request) {
        SecretsManagerClient nativeClient = (SecretsManagerClient) bAwsSecretMngClient
                .getNativeData(Constants.NATIVE_CLIENT);
        GetSecretValueRequest getSecretValueRequest = CommonUtils.toNativeGetSecretValueRequest(request);
        Future future = env.markAsync();
        EXECUTOR_SERVICE.execute(() -> {
            try {
                GetSecretValueResponse getSecretValueResponse = nativeClient.getSecretValue(getSecretValueRequest);
                BMap<BString, Object> bResponse = CommonUtils.getSecretValueResponse(getSecretValueResponse);
                future.complete(bResponse);
            } catch (Exception e) {
                String errorMsg = String.format("Error occurred while executing get-secret-value request: %s",
                        e.getMessage());
                BError bError = CommonUtils.createError(errorMsg, e);
                future.complete(bError);
            }
        });
        return null;
    }

    /**
     * Retrieves the contents of the encrypted fields for up to 20 secrets.
     *
     * @param env                 The Ballerina runtime environment.
     * @param bAwsSecretMngClient The Ballerina AWS Secret Manager client object.
     * @param request             The Ballerina AWS Secret Manager `BatchGetSecretValueRequest` request.
     * @return A Ballerina `secretmanager:Error` if there was an error while processing the request or else the AWS
     * Secret Manager `secretmanager:BatchGetSecretValueResponse`.
     */
    public static Object batchGetSecretValue(Environment env, BObject bAwsSecretMngClient,
                                             BMap<BString, Object> request) {
        SecretsManagerClient nativeClient = (SecretsManagerClient) bAwsSecretMngClient
                .getNativeData(Constants.NATIVE_CLIENT);
        BatchGetSecretValueRequest batchGetSecretValueRequest = CommonUtils.toNativeBatchGetSecretValueRequest(request);
        Future future = env.markAsync();
        EXECUTOR_SERVICE.execute(() -> {
            try {
                BatchGetSecretValueResponse getSecretValueResponse = nativeClient
                        .batchGetSecretValue(batchGetSecretValueRequest);
                BMap<BString, Object> bResponse = CommonUtils.getBatchGetSecretValueResponse(getSecretValueResponse);
                future.complete(bResponse);
            } catch (Exception e) {
                String errorMsg = String.format("Error occurred while executing batch-get-secret-value request: %s",
                        e.getMessage());
                BError bError = CommonUtils.createError(errorMsg, e);
                future.complete(bError);
            }
        });
        return null;
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
