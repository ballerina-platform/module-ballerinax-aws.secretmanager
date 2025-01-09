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
 * @param region The AWS region with which the connector should communicate.
 * @param auth   The authentication configurations for the AWS Secret Manager service
 */
public record ConnectionConfig(Region region, AuthConfig auth) {
    private static final List<Region> AWS_GLOBAL_REGIONS = List.of(
            Region.AWS_GLOBAL, Region.AWS_CN_GLOBAL, Region.AWS_US_GOV_GLOBAL, Region.AWS_ISO_GLOBAL,
            Region.AWS_ISO_B_GLOBAL);
    private static final BString REGION = StringUtils.fromString("region");
    private static final BString AUTH = StringUtils.fromString("auth");

    @SuppressWarnings("unchecked")
    public ConnectionConfig(BMap<BString, Object> configurations) {
        this(
                getRegion(configurations),
                getAuth(configurations.get(AUTH))
        );
    }

    private static Region getRegion(BMap<BString, Object> configurations) {
        String region = configurations.getStringValue(REGION).getValue();
        return AWS_GLOBAL_REGIONS.stream()
                .filter(gr -> gr.id().equals(region)).findFirst().orElse(Region.of(region));
    }

    @SuppressWarnings("unchecked")
    private static AuthConfig getAuth(Object authConfig) {
        if (authConfig instanceof BMap) {
            return new StaticAuthConfig((BMap<BString, Object>) authConfig);
        }
        return new AuthConfig() {
        };
    }
}
