# Ballerina AWS Secrets Manager connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-aws.secretmanager/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-aws.secretmanager/actions/workflows/ci.yml)
[![Trivy](https://github.com/ballerina-platform/module-ballerinax-aws.secretmanager/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-aws.secretmanager/actions/workflows/trivy-scan.yml)
[![GraalVM Check](https://github.com/ballerina-platform/module-ballerinax-aws.secretmanager/actions/workflows/build-with-bal-test-graalvm.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-aws.secretmanager/actions/workflows/build-with-bal-test-graalvm.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-aws.secretmanager.svg)](https://github.com/ballerina-platform/module-ballerinax-aws.secretmanager/commits/main)

[AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html) is a service that helps
you protect sensitive information, such as database credentials, API keys, and other secrets, by securely storing and
managing access to them.

The `ballerinax/aws.secretmanager` package provides APIs to interact with AWS Secrets Manager, enabling developers to
programmatically retrieve secrets and their metadata from their applications.

## Setup guide

Before using this connector in your Ballerina application, complete the following:

1. Create an [AWS account](https://portal.aws.amazon.com/billing/signup?nc2=h_ct&src=default&redirect_url=https%3A%2F%2Faws.amazon.com%2Fregistration-confirmation#/start).
2. Create the secrets you want to read in [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/create_secret.html).
3. Make sure the identity the connector authenticates as is allowed `secretsmanager:DescribeSecret`, `secretsmanager:GetSecretValue` and `secretsmanager:BatchGetSecretValue` on those secrets, and `kms:Decrypt` on the KMS key that encrypts them if it is a customer managed key.

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

1. Environment variables (`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`, and `AWS_WEB_IDENTITY_TOKEN_FILE` if set)
2. The shared config/credentials file's active profile (`AWS_PROFILE`, or `default` if unset) — which may itself resolve via SSO, an external process, or a chained `AssumeRole` call, depending on that profile's configuration
3. Container credentials (ECS/EKS)
4. EC2 instance profile (IMDS)

This is the recommended option when the application runs on AWS infrastructure, since no long-lived credentials need to be stored with the application.

```ballerina
import ballerinax/aws.auth;

secretmanager:Client secretmanager = check new ({
    region: aws:US_EAST_1,
    auth: auth:DEFAULT_CREDENTIALS
});
```

> **Note:** Beyond the three options above, the `auth` field also accepts `auth:AssumeRoleConfig` (STS assume-role), `auth:WebIdentityConfig` (web identity / OIDC), `auth:SsoAuthConfig` (IAM Identity Center), and `auth:ProcessAuthConfig` (external credential process). See the [`Ballerina AWS`](https://central.ballerina.io/ballerinax/aws/latest) documentation for details.

## Build from the source

### Setting up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 21. You can download it from either of the following sources:

    * [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
    * [OpenJDK](https://adoptium.net/)

   > **Note:** After installation, remember to set the `JAVA_HOME` environment variable to the directory where JDK was installed.

2. Download and install [Ballerina Swan Lake](https://ballerina.io/).

3. Download and install [Docker](https://www.docker.com/get-started).

   > **Note**: Ensure that the Docker daemon is running before executing any tests.

4. Export Github Personal access token with read package permissions as follows,

    ```bash
    export packageUser=<Username>
    export packagePAT=<Personal access token>
    ```

### Build options

Execute the commands below to build from the source.

1. To build the package:

   ```bash
   ./gradlew clean build
   ```

2. To run the tests:

   ```bash
   ./gradlew clean test
   ```

3. To build the without the tests:

   ```bash
   ./gradlew clean build -x test
   ```

4. To run tests against different environments:

   ```bash
   ./gradlew clean test -Pgroups=<Comma separated groups/test cases>
   ```

5. To debug the package with a remote debugger:

   ```bash
   ./gradlew clean build -Pdebug=<port>
   ```

6. To debug with the Ballerina language:

   ```bash
   ./gradlew clean build -PbalJavaDebug=<port>
   ```

7. Publish the generated artifacts to the local Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

8. Publish the generated artifacts to the Ballerina Central repository:

   ```bash
   ./gradlew clean build -PpublishToCentral=true
   ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`aws.secretmanager` package](https://central.ballerina.io/ballerinax/aws.secretmanager/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
