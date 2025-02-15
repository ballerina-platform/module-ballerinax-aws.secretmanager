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

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Module;

/**
 * Module utils for the Ballerina AWS Secret Manager connector to obtain the module info in the init.
 */
public final class ModuleUtils {

    private ModuleUtils() {
    }

    private static Module module;

    public static void setModule(Environment environment) {
        module = environment.getCurrentModule();
    }

    public static Module getModule() {
        return module;
    }
}
