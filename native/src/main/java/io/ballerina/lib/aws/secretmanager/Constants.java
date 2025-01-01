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

import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BString;

/**
 * Represents the constants related to Ballerina AWS Secret Manager connector.
 */
public interface Constants {
    // Constants related to native data
    String NATIVE_CLIENT = "nativeClient";

    // Constants related to AWS Secret Manager Error
    String SECRET_MNG_ERROR = "Error";
    String SECRET_MNG_ERROR_DETAILS = "ErrorDetails";
    BString SECRET_MNG_ERROR_DETAILS_HTTP_STATUS_CODE = StringUtils.fromString("httpStatusCode");
    BString SECRET_MNG_ERROR_DETAILS_HTTP_STATUS_TXT = StringUtils.fromString("httpStatusText");
    BString SECRET_MNG_ERROR_DETAILS_ERR_CODE = StringUtils.fromString("errorCode");
    BString SECRET_MNG_ERROR_DETAILS_ERR_MSG = StringUtils.fromString("errorMessage");

    // Constants related to Secret Manager `DescribeSecretResponse`
    String SECRET_MNG_DESC_SECRET_RECORD = "DescribeSecretResponse";
    BString SECRET_MNG_DESC_SECRET_ARN = StringUtils.fromString("arn");
    BString SECRET_MNG_DESC_SECRET_CREATED = StringUtils.fromString("createdDate");
    BString SECRET_MNG_DESC_SECRET_DELETED = StringUtils.fromString("deletedDate");
    BString SECRET_MNG_DESC_SECRET_DESCRIPTION = StringUtils.fromString("description");
    BString SECRET_MNG_DESC_SECRET_KMS_KEY_ID = StringUtils.fromString("kmsKeyId");
    BString SECRET_MNG_DESC_SECRET_LAST_ACCESSED = StringUtils.fromString("lastAccessedDate");
    BString SECRET_MNG_DESC_SECRET_LAST_CHANGED = StringUtils.fromString("lastChangedDate");
    BString SECRET_MNG_DESC_SECRET_LAST_ROTATED = StringUtils.fromString("lastRotatedDate");
    BString SECRET_MNG_DESC_SECRET_NAME = StringUtils.fromString("name");
    BString SECRET_MNG_DESC_SECRET_NXT_ROTATION = StringUtils.fromString("nextRotationDate");
    BString SECRET_MNG_DESC_SECRET_OWNING_SVC = StringUtils.fromString("owningService");
    BString SECRET_MNG_DESC_SECRET_PRIMARY_RGN = StringUtils.fromString("primaryRegion");
    BString SECRET_MNG_DESC_SECRET_REPLICATION_STATUS = StringUtils.fromString("replicationStatus");
    BString SECRET_MNG_DESC_SECRET_ROTATION_ENABLED = StringUtils.fromString("rotationEnabled");
    BString SECRET_MNG_DESC_SECRET_ROTATION_LAMBDA_ARN = StringUtils.fromString("rotationLambdaArn");
    BString SECRET_MNG_DESC_SECRET_ROTATION_RULES = StringUtils.fromString("rotationRules");
    BString SECRET_MNG_DESC_SECRET_TAGS = StringUtils.fromString("tags");
    BString SECRET_MNG_DESC_SECRET_VERSION_TO_STAGES = StringUtils.fromString("versionToStages");

    // Constants related to Secret Manager `ReplicationStatus`
    String SECRET_MNG_REPLICATION_STATUS_RECORD = "ReplicationStatus";
    BString SECRET_MNG_REPLICATION_STATUS_KMS_KEY_ID = StringUtils.fromString("kmsKeyId");
    BString SECRET_MNG_REPLICATION_STATUS_LAST_ACCESSED = StringUtils.fromString("lastAccessedDate");
    BString SECRET_MNG_REPLICATION_STATUS_RGN = StringUtils.fromString("region");
    BString SECRET_MNG_REPLICATION_STATUS_STATUS = StringUtils.fromString("status");
    BString SECRET_MNG_REPLICATION_STATUS_STATUS_MSG = StringUtils.fromString("statusMessage");

    // Constants related to Secret Manager `RotationRules`
    String SECRET_MNG_ROTATION_RULES_RECORD = "RotationRules";
    BString SECRET_MNG_ROTATION_RULES_AUTOMATICALLY_AFTER_DAYS = StringUtils.fromString("automaticallyAfterDays");
    BString SECRET_MNG_ROTATION_RULES_DURATION = StringUtils.fromString("duration");
    BString SECRET_MNG_ROTATION_RULES_SCHEDULE_EXPR = StringUtils.fromString("scheduleExpresssion");

    // Constants related to Secret Manager `Tag`
    String SECRET_MNG_TAG_RECORD = "Tag";
    BString SECRET_MNG_TAG_KEY = StringUtils.fromString("key");
    BString SECRET_MNG_TAG_VALUE = StringUtils.fromString("value");

    // Constants related to Secret Manager `GetSecretValueRequest`
    BString SECRET_MNG_GET_SECRET_VALUE_SECRET_ID = StringUtils.fromString("secretId");
    BString SECRET_MNG_GET_SECRET_VALUE_VERSION_ID = StringUtils.fromString("versionId");
    BString SECRET_MNG_GET_SECRET_VALUE_VERSION_STAGE = StringUtils.fromString("versionStage");

    // Constants related to Secret Manager `SecretValue`
    String SECRET_MNG_SECRET_VALUE_RECORD = "SecretValue";
    BString SECRET_MNG_SECRET_VALUE_ARN = StringUtils.fromString("arn");
    BString SECRET_MNG_SECRET_VALUE_CREATED = StringUtils.fromString("createdDate");
    BString SECRET_MNG_SECRET_VALUE_NAME = StringUtils.fromString("name");
    BString SECRET_MNG_SECRET_VALUE_VALUE = StringUtils.fromString("value");
    BString SECRET_MNG_SECRET_VALUE_VERSION_ID = StringUtils.fromString("versionId");
    BString SECRET_MNG_SECRET_VALUE_VERSION_STAGES = StringUtils.fromString("versionStages");
}
