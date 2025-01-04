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

import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueResponse;
import software.amazon.awssdk.services.secretsmanager.model.SecretValueEntry;

import java.time.Instant;
import java.util.List;
import java.util.Objects;

/**
 * {@code ConnectionConfig} contains a common java representation for AWS Secret Manager SecretValue.
 *
 * @param arn           The ARN of the secret.
 * @param createdDate   The date and time that this version of the secret was created.
 * @param name          The friendly name of the secret.
 * @param binaryValue   The decrypted secret value in Binary format.
 * @param strValue      The decrypted secret value in String format.
 * @param versionId     The unique identifier of this version of the secret.
 * @param versionStages A list of all the staging labels currently attached to this version of the secret.
 */
public record SecretValue(String arn, Instant createdDate, String name, byte[] binaryValue, String strValue,
                          String versionId, List<String> versionStages) {

    public SecretValue(SecretValueEntry nativeEntry) {
        this(
                nativeEntry.arn(),
                nativeEntry.createdDate(),
                nativeEntry.name(),
                Objects.nonNull(nativeEntry.secretBinary()) ? nativeEntry.secretBinary().asByteArray() : null,
                nativeEntry.secretString(),
                nativeEntry.versionId(),
                nativeEntry.versionStages()
        );
    }

    public SecretValue(GetSecretValueResponse nativeResponse) {
        this(
                nativeResponse.arn(),
                nativeResponse.createdDate(),
                nativeResponse.name(),
                Objects.nonNull(nativeResponse.secretBinary()) ? nativeResponse.secretBinary().asByteArray() : null,
                nativeResponse.secretString(),
                nativeResponse.versionId(),
                nativeResponse.versionStages()
        );
    }
}
