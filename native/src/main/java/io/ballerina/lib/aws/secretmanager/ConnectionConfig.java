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

import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import software.amazon.awssdk.regions.Region;

import java.util.List;

/**
 * {@code ConnectionConfig} contains the java representation of the Ballerina AWS Secret Manager client configurations.
 *
 * @param region          The AWS region with which the connector should communicate.
 * @param accessKeyId     The AWS access key, used to identify the user interacting with AWS.
 * @param secretAccessKey The AWS secret access key, used to authenticate the user interacting with AWS.
 * @param sessionToken    The AWS session token, retrieved from an AWS token service, used for authenticating that
 *                        this user has received temporary permission to access some resource.
 */
public record ConnectionConfig(Region region, String accessKeyId, String secretAccessKey, String sessionToken) {
    private static final List<Region> AWS_GLOBAL_REGIONS = List.of(
            Region.AWS_GLOBAL, Region.AWS_CN_GLOBAL, Region.AWS_US_GOV_GLOBAL, Region.AWS_ISO_GLOBAL,
            Region.AWS_ISO_B_GLOBAL);
    private static final BString REGION = StringUtils.fromString("region");
    private static final BString AUTH = StringUtils.fromString("auth");
    private static final BString AUTH_ACCESS_KEY_KEY = StringUtils.fromString("accessKeyId");
    private static final BString AUTH_SECRET_ACCESS_KEY = StringUtils.fromString("secretAccessKey");
    private static final BString AUTH_SESSION_TOKEN = StringUtils.fromString("sessionToken");

    public ConnectionConfig(BMap<BString, Object> configurations) {
        this(
                getRegion(configurations),
                getAuthConfig(configurations, AUTH_ACCESS_KEY_KEY),
                getAuthConfig(configurations, AUTH_SECRET_ACCESS_KEY),
                getAuthConfig(configurations, AUTH_SESSION_TOKEN)
        );
    }

    private static Region getRegion(BMap<BString, Object> configurations) {
        String region = configurations.getStringValue(REGION).getValue();
        return AWS_GLOBAL_REGIONS.stream().filter(gr -> gr.id().equals(region)).findFirst().orElse(Region.of(region));
    }

    @SuppressWarnings("unchecked")
    private static String getAuthConfig(BMap<BString, Object> configurations, BString key) {
        BMap<BString, Object> authConfig = (BMap<BString, Object>) configurations.getMapValue(AUTH);
        if (authConfig.containsKey(key)) {
            return authConfig.getStringValue(key).getValue();
        }
        return null;
    }
}
