## Overview

[AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html) is a service that helps you protect sensitive information, such as database credentials, API keys, and other secrets, by securely storing and managing access to them.

The AWS Secrets Manager connector provides APIs to interact with the service, enabling developers to programmatically retrieve secrets and their metadata from their applications.

### Key Features

- Securely retrieve secret values without embedding credentials in the application
- Read secret metadata, including rotation, replication and tagging details
- Retrieve up to 20 secret values in a single batch call, by ID or by filter
- Authenticate through any standard AWS credential source, including IAM roles

## Setup guide

Before using this connector in your Ballerina application, complete the following:

1. Create an [AWS account](https://portal.aws.amazon.com/billing/signup?nc2=h_ct&src=default&redirect_url=https%3A%2F%2Faws.amazon.com%2Fregistration-confirmation#/start).
2. Create the secrets you want to read in [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/create_secret.html).
3. Make sure the identity the connector authenticates as is allowed `secretsmanager:DescribeSecret`, `secretsmanager:GetSecretValue` and `secretsmanager:BatchGetSecretValue` on those secrets, and `kms:Decrypt` on the KMS key that encrypts them if it is a customer-managed key.

### Obtain IAM user credentials

To create an IAM user and generate an access key, follow the [obtaining IAM user credentials](https://central.ballerina.io/ballerinax/aws/latest#obtaining-iam-user-credentials) guide.

## Quickstart

To use the `aws.secretmanager` connector in your Ballerina project, modify the `.bal` file as follows:

### Step 1: Import the module

Import the `ballerinax/aws` and `ballerinax/aws.secretmanager` modules into your Ballerina project.

```ballerina
import ballerinax/aws;
import ballerinax/aws.secretmanager;
```

### Step 2: Instantiate a new connector

Create a new `secretmanager:Client` by providing the region and authentication configurations.

```ballerina
configurable string accessKeyId = ?;
configurable string secretAccessKey = ?;

secretmanager:Client secretmanager = check new ({
    region: aws:US_EAST_1,
    auth: {
        accessKeyId,
        secretAccessKey
    }
});
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

```ballerina
secretmanager:SecretValue secret = check secretmanager->getSecretValue("<secret-id>");
```

### Step 4: Run the Ballerina application

Use the following command to compile and run the Ballerina program.

```bash
bal run
```

### Alternative authentication methods

#### Profile-based authentication

You can use AWS profile-based authentication as an alternative to static credentials.

```ballerina
secretmanager:Client secretmanager = check new ({
    region: aws:US_EAST_1,
    auth: {
        profileName: "myAwsProfile",
        credentialsFilePath: "/path/to/custom/credentials"
    }
});
```

#### Default credential provider chain

The standard default credential provider chain, trying each of the following in order and taking the first source that yields credentials:

1. JVM system properties
2. Environment variables (`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`, and `AWS_WEB_IDENTITY_TOKEN_FILE` if set)
3. The shared config/credentials file's active profile (`AWS_PROFILE`, or `default` if unset) — which may itself resolve via SSO, an external process, or a chained `AssumeRole` call, depending on that profile's configuration
4. Container credentials (ECS/EKS)
5. EC2 instance profile (IMDS)

This is the recommended option when the application runs on AWS infrastructure, since no long-lived credentials need to be stored with the application.

```ballerina
import ballerinax/aws.auth;

secretmanager:Client secretmanager = check new ({
    region: aws:US_EAST_1,
    auth: auth:DEFAULT_CREDENTIALS
});
```

> **Note:** Beyond the three options above, the `auth` field also accepts `auth:AssumeRoleConfig` (STS assume-role), `auth:WebIdentityConfig` (web identity / OIDC), `auth:SsoAuthConfig` (IAM Identity Center), and `auth:ProcessAuthConfig` (external credential process). See the [`Ballerina AWS`](https://central.ballerina.io/ballerinax/aws/latest) documentation for details.
