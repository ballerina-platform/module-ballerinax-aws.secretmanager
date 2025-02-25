// Copyright (c) 2025 WSO2 LLC. (http://www.wso2.com).
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

import ballerina/constraint;
import ballerina/time;

# Represents the Client configurations for AWS Secret Manager service.
public type ConnectionConfig record {|
    # The AWS region with which the connector should communicate
    Region region;
    # The authentication configurations for the AWS Secret Manager service
    StaticAuthConfig|EC2_IAM_ROLE auth;
|};

# An Amazon Web Services region that hosts a set of Amazon services.
public enum Region {
    AF_SOUTH_1 = "af-south-1",
    AP_EAST_1 = "ap-east-1",
    AP_NORTHEAST_1 = "ap-northeast-1",
    AP_NORTHEAST_2 = "ap-northeast-2",
    AP_NORTHEAST_3 = "ap-northeast-3",
    AP_SOUTH_1 = "ap-south-1",
    AP_SOUTH_2 = "ap-south-2",
    AP_SOUTHEAST_1 = "ap-southeast-1",
    AP_SOUTHEAST_2 = "ap-southeast-2",
    AP_SOUTHEAST_3 = "ap-southeast-3",
    AP_SOUTHEAST_4 = "ap-southeast-4",
    AWS_CN_GLOBAL = "aws-cn-global",
    AWS_GLOBAL = "aws-global",
    AWS_ISO_GLOBAL = "aws-iso-global",
    AWS_ISO_B_GLOBAL = "aws-iso-b-global",
    AWS_US_GOV_GLOBAL = "aws-us-gov-global",
    CA_WEST_1 = "ca-west-1",
    CA_CENTRAL_1 = "ca-central-1",
    CN_NORTH_1 = "cn-north-1",
    CN_NORTHWEST_1 = "cn-northwest-1",
    EU_CENTRAL_1 = "eu-central-1",
    EU_CENTRAL_2 = "eu-central-2",
    EU_ISOE_WEST_1 = "eu-isoe-west-1",
    EU_NORTH_1 = "eu-north-1",
    EU_SOUTH_1 = "eu-south-1",
    EU_SOUTH_2 = "eu-south-2",
    EU_WEST_1 = "eu-west-1",
    EU_WEST_2 = "eu-west-2",
    EU_WEST_3 = "eu-west-3",
    IL_CENTRAL_1 = "il-central-1",
    ME_CENTRAL_1 = "me-central-1",
    ME_SOUTH_1 = "me-south-1",
    SA_EAST_1 = "sa-east-1",
    US_EAST_1 = "us-east-1",
    US_EAST_2 = "us-east-2",
    US_GOV_EAST_1 = "us-gov-east-1",
    US_GOV_WEST_1 = "us-gov-west-1",
    US_ISOB_EAST_1 = "us-isob-east-1",
    US_ISO_EAST_1 = "us-iso-east-1",
    US_ISO_WEST_1 = "us-iso-west-1",
    US_WEST_1 = "us-west-1",
    US_WEST_2 = "us-west-2"
}

# Represents the EC2 IAM role based authentication for AWS Secret Manager service.
public const EC2_IAM_ROLE = "EC2_IAM_ROLE";

# Represents the static authentication configurations for AWS Secret Manager service.
public type StaticAuthConfig record {|
    # The AWS access key, used to identify the user interacting with AWS
    string accessKeyId;
    # The AWS secret access key, used to authenticate the user interacting with AWS
    string secretAccessKey;
    # The AWS session token, retrieved from an AWS token service, used for authenticating 
    # a user with temporary permission to a resource
    string sessionToken?;
|};

# The ARN or name of the secret.
@constraint:String {
    minLength: {
        value: 1,
        message: "SecretId must contain at least 1 character"
    },
    maxLength: {
        value: 2048,
        message: "SecretId cannot exceed 2048 characters"
    }
}
public type SecretId string;

# Represents the results retrieved from `GetEntitlements` operation.
public type DescribeSecretResponse record {|
    # The ARN of the secret
    string arn;
    # The date the secret was created
    time:Utc createdDate;
    # The date the secret is scheduled for deletion
    time:Utc deletedDate?;
    # The description of the secret
    string description;
    # The key ID or alias ARN of the AWS KMS key that Secrets Manager uses to encrypt the secret value
    string kmsKeyId?;
    # The date that the secret was last accessed in the Region
    time:Utc lastAccessedDate?;
    # The last date and time that this secret was modified in any way
    time:Utc lastChangedDate?;
    # The last date and time that Secrets Manager rotated the secret
    time:Utc lastRotatedDate?;
    # The name of the secret
    string name;
    # The next rotation is scheduled to occur on or before this date
    time:Utc nextRotationDate?;
    # The ID of the service that created this secret
    string owningService;
    # The Region the secret is in. If a secret is replicated to other Regions, the replicas are listed in `replicationStatus`
    Region primaryRegion;
    # A list of the replicas of this secret and their status
    ReplicationStatus[] replicationStatus?;
    # Specifies whether automatic rotation is turned on for this secret
    boolean rotationEnabled;
    # The ARN of the Lambda function that Secrets Manager invokes to rotate the secret
    string rotationLambdaArn?;
    # The rotation schedule and Lambda function for this secret
    RotationRules rotationRules?;
    # The list of tags attached to the secret
    Tag[] tags?;
    # A list of the versions of the secret that have staging labels attached
    map<StagingStatus[]> versionToStages?;
|};

# Represents the replication status of a secret in AWS Secrets Manager.
public type ReplicationStatus record {|
    # The ARN, key ID, or an alias ARN of the AWS KMS key that Secrets Manager uses to encrypt the secret value
    string kmsKeyId?;
    # The date that the secret was last accessed in the Region
    time:Utc lastAccessedDate?;
    # The Region where replication occurs
    Region region?;
    # The replication status
    "InSync"|"Failed"|"InProgress" status?;
    # The status message
    string statusMessage?;
|};

# Represents the rotation rules for a secret in AWS Secrets Manager
public type RotationRules record {|
    # The number of days between rotations of the secret
    int automaticallyAfterDays?;
    # The length of the rotation window in hours
    string duration?;
    # A `cron` or `rate` expression that defines the schedule for rotating your secret
    string scheduleExpresssion?;
|};

# Represents a tag associated with an AWS resource.
public type Tag record {|
    # The key identifier, or name, of the tag
    string 'key?;
    # The string value associated with the key of the tag
    string value?;
|};

# Represents the staging label that indicates the version of the secret in AWS Secrets Manager.
public enum StagingStatus {
    # Indicates the current version of the secret
    AWSCURRENT,
    # Indicates the version of the secret that contains 
    # new secret information that will become the next 
    # current version when rotation finishes
    AWSPENDING,
    # Indicates the previous current version of the secret
    AWSPREVIOUS
}

# Represents the request to retrieve a secret value from AWS Secrets Manager.
public type SecretVersionSelector record {|
    # The unique identifier of the version of the secret
    @constraint:String {
        minLength: {
            value: 32,
            message: "VersionId must be at least 32 characters long"
        },
        maxLength: {
            value: 64,
            message: "VersionId cannot exceed 64 characters"
        }
    }
    string versionId?;
    # The staging label of the version of the secret
    @constraint:String {
        minLength: {
            value: 1,
            message: "VersionStage must contain at least 1 character"
        },
        maxLength: {
            value: 256,
            message: "VersionStage cannot exceed 256 characters"
        }
    }
    string versionStage?;
|};

# Represents the details of a secret retrieved from AWS Secrets Manager.
public type SecretValue record {|
    # The ARN of the secret
    string arn;
    # The date and time that this version of the secret was created
    time:Utc createdDate;
    # The friendly name of the secret
    string name;
    # The decrypted secret value
    byte[]|string value;
    # The unique identifier of this version of the secret
    string versionId;
    # A list of all the staging labels currently attached to this version of the secret
    string[] versionStages;
|};

# Represents the request parameters for the `batchGetSecretValue` API of the AWS Secrets Manager connector.
public type BatchGetSecretValueRequest record {|
    # The filters to choose which secrets to retrieve
    @constraint:Array {
        maxLength: {
            value: 10,
            message: "Can only have maximum 10 filters per request"
        }
    }
    SecretValueFilter[] filters?;
    # The number of results to include in the response. If there are more results available, 
    # in the response, Secrets Manager includes `nextToken`. To use this parameter, 
    # you must also use the `filters` parameter
    @constraint:Int {
        minValue: {
            value: 1,
            message: "MaxResults must be at least 1"
        },
        maxValue: {
            value: 20,
            message: "MaxResults cannot exceed 20"
        }
    }
    int maxResults?;
    # A token that indicates where the output should continue from, 
    # if a previous call did not show all results
    @constraint:String {
        minLength: {
            value: 1,
            message: "NextToken must contain at least 1 character"
        },
        maxLength: {
            value: 4096,
            message: "NextToken cannot exceed 4096 characters"
        }
    }
    string nextToken?;
    # The ARN or names of the secrets to retrieve. You must include `filters` or `secretIds`, but not both
    @constraint:Array {
        minLength: {
            value: 1,
            message: "Should have atleast 1 secretId per request"
        },
        maxLength: {
            value: 20,
            message: "Can only have maximum 20 secretIds per request"
        }
    }
    SecretId[] secretIds?;
|};

# Represents a filter used to match specific secrets based on a key and its values.
public type SecretValueFilter record {|
    # The key used to filter secrets
    FilterKey 'key?;
    # A list of values associated with the filter key
    @constraint:Array {
        minLength: {
            value: 1,
            message: "The `values` must contain at least 1 element"
        },
        maxLength: {
            value: 10,
            message: "The `values` cannot contain more than 10 elements"
        }
    }
    FilterValue[] values?;
|};

# The allowed filter keys for `SecretValueFilter`.
public type FilterKey "description"|"name"|"tag-key"|"tag-value"|"primary-region"|"owning-service"|"all";

# Represents a value used in the filter criteria for a `SecretValueFilter`.
@constraint:String {
    pattern: {
        value: re `^!?[a-zA-Z0-9 :_@/+=.\-!]{0,512}$`,
        message: "Invalid filter value format"
    }
}
public type FilterValue string;

# Represents the response returned by the `batchGetSecretValue` API of the AWS Secrets Manager connector.
public type BatchGetSecretValueResponse record {|
    # A list of errors encountered by Secrets Manager while attempting to retrieve individual secrets.
    # Each error provides details such as the error code, message, and the affected secret's identifier.
    ApiError[] errors?;
    # A token indicating that more results are available than what is included in the current response. 
    # Use this token to retrieve the next set of results by making another call to `batchGetSecretValue`. 
    # This token might be present even if no values are returned, such as when filtering a long list
    string nextToken?;
    # A list of retrieved secret values. Each value represents a specific secret returned by the API.
    SecretValue[] secretValues?;
|};

# Represents an error encountered by Secrets Manager while retrieving an individual secret.
public type ApiError record {|
    # The error code returned by Secrets Manager indicating the issue encountered.
    string errorCode?;
    # A descriptive message explaining the nature of the error.
    string message?;
    # The ARN or name of the secret for which the error occurred.
    SecretId secretId?;
|};
