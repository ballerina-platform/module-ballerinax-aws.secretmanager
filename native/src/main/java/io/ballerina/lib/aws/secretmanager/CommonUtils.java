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

import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.flags.SymbolFlags;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.time.nativeimpl.Utc;
import software.amazon.awssdk.awscore.exception.AwsErrorDetails;
import software.amazon.awssdk.awscore.exception.AwsServiceException;
import software.amazon.awssdk.http.SdkHttpResponse;
import software.amazon.awssdk.services.secretsmanager.model.APIErrorType;
import software.amazon.awssdk.services.secretsmanager.model.BatchGetSecretValueRequest;
import software.amazon.awssdk.services.secretsmanager.model.BatchGetSecretValueResponse;
import software.amazon.awssdk.services.secretsmanager.model.DescribeSecretResponse;
import software.amazon.awssdk.services.secretsmanager.model.Filter;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueRequest;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueResponse;
import software.amazon.awssdk.services.secretsmanager.model.ReplicationStatusType;
import software.amazon.awssdk.services.secretsmanager.model.RotationRulesType;
import software.amazon.awssdk.services.secretsmanager.model.SecretValueEntry;
import software.amazon.awssdk.services.secretsmanager.model.Tag;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * {@code CommonUtils} contains the common utility functions for the Ballerina AWS Secret Manager connector.
 */
public final class CommonUtils {
    private static final RecordType REPLICATION_STATUS_REC_TYPE = TypeCreator.createRecordType(
            Constants.SECRET_MNG_REPLICATION_STATUS_RECORD, ModuleUtils.getModule(), SymbolFlags.PUBLIC, true,
            0);
    private static final ArrayType REPLICATION_STATUS_ARR_TYPE = TypeCreator.createArrayType(
            REPLICATION_STATUS_REC_TYPE);
    private static final RecordType TAG_REC_TYPE = TypeCreator.createRecordType(
            Constants.SECRET_MNG_TAG_RECORD, ModuleUtils.getModule(), SymbolFlags.PUBLIC, true, 0);
    private static final ArrayType TAG_ARR_TYPE = TypeCreator.createArrayType(TAG_REC_TYPE);
    private static final RecordType API_ERR_REC_TYPE = TypeCreator.createRecordType(
            Constants.SECRET_MNG_API_ERR_RECORD, ModuleUtils.getModule(), SymbolFlags.PUBLIC, true, 0);
    private static final ArrayType API_ERR_ARR_TYPE = TypeCreator.createArrayType(API_ERR_REC_TYPE);
    private static final RecordType SECRET_VALUE_REC_TYPE = TypeCreator.createRecordType(
            Constants.SECRET_MNG_SECRET_VALUE_RECORD, ModuleUtils.getModule(), SymbolFlags.PUBLIC, true, 0);
    private static final ArrayType SECRET_VALUE_ARR_TYPE = TypeCreator.createArrayType(API_ERR_REC_TYPE);

    private CommonUtils() {
    }

    public static BError createError(String message, Throwable exception) {
        BError cause = ErrorCreator.createError(exception);
        BMap<BString, Object> errorDetails = ValueCreator.createRecordValue(
                ModuleUtils.getModule(), Constants.SECRET_MNG_ERROR_DETAILS);
        if (exception instanceof AwsServiceException awsSvcExp && Objects.nonNull(awsSvcExp.awsErrorDetails())) {
            AwsErrorDetails awsErrorDetails = awsSvcExp.awsErrorDetails();
            SdkHttpResponse sdkResponse = awsErrorDetails.sdkHttpResponse();
            if (Objects.nonNull(sdkResponse)) {
                errorDetails.put(
                        Constants.SECRET_MNG_ERROR_DETAILS_HTTP_STATUS_CODE, sdkResponse.statusCode());
                sdkResponse.statusText().ifPresent(httpStatusTxt -> errorDetails.put(
                        Constants.SECRET_MNG_ERROR_DETAILS_HTTP_STATUS_TXT, StringUtils.fromString(httpStatusTxt)));
            }
            errorDetails.put(
                    Constants.SECRET_MNG_ERROR_DETAILS_ERR_CODE, StringUtils.fromString(awsErrorDetails.errorCode()));
            errorDetails.put(
                    Constants.SECRET_MNG_ERROR_DETAILS_ERR_MSG, StringUtils.fromString(awsErrorDetails.errorMessage()));
        }
        return ErrorCreator.createError(
                ModuleUtils.getModule(), Constants.SECRET_MNG_ERROR, StringUtils.fromString(message), cause,
                errorDetails);
    }

    public static BMap<BString, Object> getDescribeSecretResponse(DescribeSecretResponse nativeResponse) {
        BMap<BString, Object> describeSecretResp = ValueCreator.createRecordValue(
                ModuleUtils.getModule(), Constants.SECRET_MNG_DESC_SECRET_RECORD);
        describeSecretResp.put(
                Constants.SECRET_MNG_DESC_SECRET_ARN, StringUtils.fromString(nativeResponse.arn()));
        describeSecretResp.put(
                Constants.SECRET_MNG_DESC_SECRET_CREATED, new Utc(nativeResponse.createdDate()).build());

        Instant deletedDate = nativeResponse.deletedDate();
        if (Objects.nonNull(deletedDate)) {
            describeSecretResp.put(
                    Constants.SECRET_MNG_DESC_SECRET_DELETED, new Utc(deletedDate).build());
        }

        describeSecretResp.put(Constants.SECRET_MNG_DESC_SECRET_DESCRIPTION,
                StringUtils.fromString(nativeResponse.description()));

        String kmsKeyId = nativeResponse.kmsKeyId();
        if (Objects.nonNull(kmsKeyId)) {
            describeSecretResp.put(
                    Constants.SECRET_MNG_DESC_SECRET_KMS_KEY_ID, StringUtils.fromString(kmsKeyId));
        }

        Instant lastAccessed = nativeResponse.lastAccessedDate();
        if (Objects.nonNull(lastAccessed)) {
            describeSecretResp.put(Constants.SECRET_MNG_DESC_SECRET_LAST_ACCESSED, new Utc(lastAccessed).build());
        }

        Instant lastChanged = nativeResponse.lastChangedDate();
        if (Objects.nonNull(lastChanged)) {
            describeSecretResp.put(Constants.SECRET_MNG_DESC_SECRET_LAST_CHANGED, new Utc(lastChanged).build());
        }

        Instant lastRotated = nativeResponse.lastRotatedDate();
        if (Objects.nonNull(lastRotated)) {
            describeSecretResp.put(Constants.SECRET_MNG_DESC_SECRET_LAST_ROTATED, new Utc(lastRotated).build());
        }

        describeSecretResp.put(
                Constants.SECRET_MNG_DESC_SECRET_NAME, StringUtils.fromString(nativeResponse.name()));

        Instant nextRotation = nativeResponse.nextRotationDate();
        if (Objects.nonNull(nextRotation)) {
            describeSecretResp.put(Constants.SECRET_MNG_DESC_SECRET_NXT_ROTATION, new Utc(nextRotation).build());
        }

        describeSecretResp.put(
                Constants.SECRET_MNG_DESC_SECRET_OWNING_SVC, StringUtils.fromString(nativeResponse.owningService()));
        describeSecretResp.put(
                Constants.SECRET_MNG_DESC_SECRET_PRIMARY_RGN, StringUtils.fromString(nativeResponse.primaryRegion()));

        if (nativeResponse.hasReplicationStatus() && !nativeResponse.replicationStatus().isEmpty()) {
            List<ReplicationStatusType> nativeReplicationStatus = nativeResponse.replicationStatus();
            BArray replicationStatus = ValueCreator.createArrayValue(REPLICATION_STATUS_ARR_TYPE);
            nativeReplicationStatus.forEach(rs -> {
                BMap<BString, Object> replicationStatusRec = constructBReplicationStatus(rs);
                replicationStatus.append(replicationStatusRec);
            });
            describeSecretResp.put(Constants.SECRET_MNG_DESC_SECRET_REPLICATION_STATUS, replicationStatus);
        }

        boolean rotationEnabled = Objects.nonNull(nativeResponse.rotationEnabled()) && nativeResponse.rotationEnabled();
        describeSecretResp.put(Constants.SECRET_MNG_DESC_SECRET_ROTATION_ENABLED, rotationEnabled);

        String rotationLambdaArn = nativeResponse.rotationLambdaARN();
        if (Objects.nonNull(rotationLambdaArn)) {
            describeSecretResp.put(
                    Constants.SECRET_MNG_DESC_SECRET_ROTATION_LAMBDA_ARN, StringUtils.fromString(rotationLambdaArn));
        }

        RotationRulesType nativeRotationRules = nativeResponse.rotationRules();
        if (Objects.nonNull(nativeRotationRules)) {
            BMap<BString, Object> rotationRules = constructBRotationRules(nativeRotationRules);
            describeSecretResp.put(Constants.SECRET_MNG_DESC_SECRET_ROTATION_RULES, rotationRules);
        }

        if (nativeResponse.hasTags() && !nativeResponse.tags().isEmpty()) {
            List<Tag> nativeTags = nativeResponse.tags();
            BArray tags = ValueCreator.createArrayValue(TAG_ARR_TYPE);
            nativeTags.forEach(t -> {
                BMap<BString, Object> tag = constructBTag(t);
                tags.append(tag);
            });
            describeSecretResp.put(Constants.SECRET_MNG_DESC_SECRET_TAGS, tags);
        }

        if (nativeResponse.hasVersionIdsToStages() && !nativeResponse.versionIdsToStages().isEmpty()) {
            BMap<BString, Object> versionToStages = constructBVersionIdsToStages(nativeResponse.versionIdsToStages());
            describeSecretResp.put(Constants.SECRET_MNG_DESC_SECRET_VERSION_TO_STAGES, versionToStages);
        }
        return describeSecretResp;
    }

    private static BMap<BString, Object> constructBVersionIdsToStages(Map<String, List<String>> versionIdsToStages) {
        BMap<BString, Object> versionToStages = ValueCreator.createMapValue();
        versionIdsToStages.forEach((k, v) -> {
            if (Objects.isNull(v) || v.isEmpty()) {
                BString[] stages = new BString[0];
                versionToStages.put(StringUtils.fromString(k), ValueCreator.createArrayValue(stages));
                return;
            }
            BString[] stages = new BString[v.size()];
            v.stream().map(StringUtils::fromString).toList().toArray(stages);
            versionToStages.put(StringUtils.fromString(k), ValueCreator.createArrayValue(stages));
        });
        return versionToStages;
    }

    private static BMap<BString, Object> constructBReplicationStatus(ReplicationStatusType rs) {
        BMap<BString, Object> replicationStatusRec = ValueCreator
                .createRecordValue(REPLICATION_STATUS_REC_TYPE);
        String rsKmsKeyId = rs.kmsKeyId();
        if (Objects.nonNull(rsKmsKeyId)) {
            replicationStatusRec.put(
                    Constants.SECRET_MNG_REPLICATION_STATUS_KMS_KEY_ID, StringUtils.fromString(rsKmsKeyId));
        }
        Instant rsLastAccessed = rs.lastAccessedDate();
        if (Objects.nonNull(rsLastAccessed)) {
            replicationStatusRec.put(
                    Constants.SECRET_MNG_REPLICATION_STATUS_LAST_ACCESSED, new Utc(rsLastAccessed).build());
        }
        String rsRegion = rs.region();
        if (Objects.nonNull(rsRegion)) {
            replicationStatusRec.put(
                    Constants.SECRET_MNG_REPLICATION_STATUS_RGN, StringUtils.fromString(rsRegion));
        }
        String rsStatus = rs.statusAsString();
        if (Objects.nonNull(rsStatus)) {
            replicationStatusRec.put(Constants.SECRET_MNG_REPLICATION_STATUS_STATUS,
                    StringUtils.fromString(rsStatus));
        }
        String rsStatusMsg = rs.statusMessage();
        if (Objects.nonNull(rsStatusMsg)) {
            replicationStatusRec.put(
                    Constants.SECRET_MNG_REPLICATION_STATUS_STATUS_MSG, StringUtils.fromString(rsStatusMsg));
        }
        return replicationStatusRec;
    }

    private static BMap<BString, Object> constructBRotationRules(RotationRulesType rotationRules) {
        BMap<BString, Object> bRotationRules = ValueCreator.createRecordValue(
                ModuleUtils.getModule(), Constants.SECRET_MNG_ROTATION_RULES_RECORD);
        Long automaticallyAfterDays = rotationRules.automaticallyAfterDays();
        if (Objects.nonNull(automaticallyAfterDays)) {
            bRotationRules.put(
                    Constants.SECRET_MNG_ROTATION_RULES_AUTOMATICALLY_AFTER_DAYS, automaticallyAfterDays);
        }
        String duration = rotationRules.duration();
        if (Objects.nonNull(duration)) {
            bRotationRules.put(Constants.SECRET_MNG_ROTATION_RULES_DURATION, StringUtils.fromString(duration));
        }
        String scheduledExpr = rotationRules.scheduleExpression();
        if (Objects.nonNull(scheduledExpr)) {
            bRotationRules.put(
                    Constants.SECRET_MNG_ROTATION_RULES_SCHEDULE_EXPR, StringUtils.fromString(scheduledExpr));
        }
        return bRotationRules;
    }

    private static BMap<BString, Object> constructBTag(Tag tag) {
        BMap<BString, Object> bTag = ValueCreator.createRecordValue(TAG_REC_TYPE);
        String nativeTagKey = tag.key();
        if (Objects.nonNull(nativeTagKey)) {
            bTag.put(Constants.SECRET_MNG_TAG_KEY, StringUtils.fromString(nativeTagKey));
        }
        String nativeTagValue = tag.value();
        if (Objects.nonNull(nativeTagValue)) {
            bTag.put(Constants.SECRET_MNG_TAG_VALUE, StringUtils.fromString(nativeTagValue));
        }
        return bTag;
    }

    public static GetSecretValueRequest toNativeGetSecretValueRequest(BMap<BString, Object> request) {
        GetSecretValueRequest.Builder builder = GetSecretValueRequest.builder();
        builder.secretId(request.getStringValue(Constants.SECRET_MNG_GET_SECRET_VALUE_SECRET_ID).getValue());
        if (request.containsKey(Constants.SECRET_MNG_GET_SECRET_VALUE_VERSION_ID)) {
            builder.versionId(request.getStringValue(Constants.SECRET_MNG_GET_SECRET_VALUE_VERSION_ID).getValue());
        }
        if (request.containsKey(Constants.SECRET_MNG_GET_SECRET_VALUE_VERSION_STAGE)) {
            builder.versionId(request.getStringValue(Constants.SECRET_MNG_GET_SECRET_VALUE_VERSION_STAGE).getValue());
        }
        return builder.build();
    }

    public static BMap<BString, Object> getSecretValueResponse(GetSecretValueResponse nativeResponse) {
        SecretValue nativeSecretValue = new SecretValue(nativeResponse);
        return getSecretValue(nativeSecretValue);
    }

    private static BMap<BString, Object> getSecretValue(SecretValue nativeSecret) {
        BMap<BString, Object> secretValue = ValueCreator.createRecordValue(SECRET_VALUE_REC_TYPE);
        secretValue.put(Constants.SECRET_MNG_SECRET_VALUE_ARN, StringUtils.fromString(nativeSecret.arn()));
        secretValue.put(Constants.SECRET_MNG_SECRET_VALUE_CREATED, new Utc(nativeSecret.createdDate()).build());
        secretValue.put(Constants.SECRET_MNG_SECRET_VALUE_NAME, StringUtils.fromString(nativeSecret.name()));

        if (Objects.nonNull(nativeSecret.binaryValue())) {
            secretValue.put(
                    Constants.SECRET_MNG_SECRET_VALUE_VALUE, ValueCreator.createArrayValue(nativeSecret.binaryValue()));
        } else {
            secretValue.put(Constants.SECRET_MNG_SECRET_VALUE_VALUE, StringUtils.fromString(nativeSecret.strValue()));
        }

        secretValue.put(Constants.SECRET_MNG_SECRET_VALUE_VERSION_ID, StringUtils.fromString(nativeSecret.versionId()));

        BString[] versionToStages = nativeSecret.versionStages().stream()
                .map(StringUtils::fromString)
                .toArray(BString[]::new);
        secretValue.put(
                Constants.SECRET_MNG_SECRET_VALUE_VERSION_STAGES, ValueCreator.createArrayValue(versionToStages));
        return secretValue;
    }

    @SuppressWarnings("unchecked")
    public static BatchGetSecretValueRequest toNativeBatchGetSecretValueRequest(BMap<BString, Object> request) {
        BatchGetSecretValueRequest.Builder builder = BatchGetSecretValueRequest.builder();

        if (request.containsKey(Constants.SECRET_MNG_BATCH_GET_SECRET_VALUE_FILTERS)) {
            BArray filters = request.getArrayValue(Constants.SECRET_MNG_BATCH_GET_SECRET_VALUE_FILTERS);
            List<Filter> nativeFilters = new ArrayList<>();
            for (int i = 0; i < filters.size(); i++) {
                BMap<BString, Object> filter = (BMap<BString, Object>) filters.get(i);
                Filter nativeFilter = toNativeFilter(filter);
                nativeFilters.add(nativeFilter);
            }
            builder.filters(nativeFilters);
        } else {
            String[] secretIds = request.getArrayValue(Constants.SECRET_MNG_BATCH_GET_SECRET_VALUE_SECRET_IDS)
                    .getStringArray();
            builder.secretIdList(secretIds);
        }

        if (request.containsKey(Constants.SECRET_MNG_BATCH_GET_SECRET_VALUE_MAX_RESULTS)) {
            builder.maxResults(request.getIntValue(Constants.SECRET_MNG_BATCH_GET_SECRET_VALUE_MAX_RESULTS).intValue());
        }

        if (request.containsKey(Constants.SECRET_MNG_BATCH_GET_SECRET_VALUE_NXT_TOKEN)) {
            builder.nextToken(request.getStringValue(Constants.SECRET_MNG_BATCH_GET_SECRET_VALUE_NXT_TOKEN).getValue());
        }

        return builder.build();
    }

    private static Filter toNativeFilter(BMap<BString, Object> filter) {
        Filter.Builder builder = Filter.builder();
        if (filter.containsKey(Constants.SECRET_MNG_SECRET_VALUE_FILTER_KEY)) {
            builder.key(filter.getStringValue(Constants.SECRET_MNG_SECRET_VALUE_FILTER_KEY).getValue());
        }
        if (filter.containsKey(Constants.SECRET_MNG_SECRET_VALUE_FILTER_VALUES)) {
            BArray filterValues = filter.getArrayValue(Constants.SECRET_MNG_SECRET_VALUE_FILTER_VALUES);
            builder.values(filterValues.getStringArray());
        }
        return builder.build();
    }

    public static BMap<BString, Object> getBatchGetSecretValueResponse(BatchGetSecretValueResponse nativeResponse) {
        BMap<BString, Object> batchGetSecretValueResponse = ValueCreator.createRecordValue(
                ModuleUtils.getModule(), Constants.SECRET_MNG_BATCH_GET_SECRET_VALUE_RES_RECORD);

        List<APIErrorType> nativeErrors = nativeResponse.errors();
        if (Objects.nonNull(nativeErrors) && !nativeErrors.isEmpty()) {
            BArray errors = ValueCreator.createArrayValue(API_ERR_ARR_TYPE);
            nativeErrors.forEach(err -> {
                BMap<BString, Object> apiError = getApiError(err);
                errors.append(apiError);
            });
            batchGetSecretValueResponse.put(Constants.SECRET_MNG_BATCH_GET_SECRET_VALUE_RES_ERRORS, errors);
        }

        if (Objects.nonNull(nativeResponse.nextToken())) {
            batchGetSecretValueResponse.put(Constants.SECRET_MNG_BATCH_GET_SECRET_VALUE_RES_NXT_TOKEN,
                    StringUtils.fromString(nativeResponse.nextToken()));
        }

        List<SecretValueEntry> nativeSecretValues = nativeResponse.secretValues();
        if (Objects.nonNull(nativeSecretValues) && !nativeSecretValues.isEmpty()) {
            BArray secretValues = ValueCreator.createArrayValue(SECRET_VALUE_ARR_TYPE);
            nativeSecretValues.stream().map(SecretValue::new).forEach(sv -> {
                BMap<BString, Object> secretValue = getSecretValue(sv);
                secretValues.append(secretValue);
            });
            batchGetSecretValueResponse.put(
                    Constants.SECRET_MNG_BATCH_GET_SECRET_VALUE_RES_SECRET_VALUES, secretValues);
        }

        return batchGetSecretValueResponse;
    }

    public static BMap<BString, Object> getApiError(APIErrorType nativeError) {
        BMap<BString, Object> apiError = ValueCreator.createRecordValue(API_ERR_REC_TYPE);
        if (Objects.nonNull(nativeError.errorCode())) {
            apiError.put(Constants.SECRET_MNG_API_ERR_ERR_CODE, StringUtils.fromString(nativeError.errorCode()));
        }
        if (Objects.nonNull(nativeError.message())) {
            apiError.put(Constants.SECRET_MNG_API_ERR_MSG, StringUtils.fromString(nativeError.message()));
        }
        if (Objects.nonNull(nativeError.secretId())) {
            apiError.put(Constants.SECRET_MNG_API_ERR_SECRET_ID, StringUtils.fromString(nativeError.secretId()));
        }
        return apiError;
    }
}
