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
}
