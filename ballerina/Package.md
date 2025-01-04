## Overview

[AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html) is a service that helps you protect sensitive information, such as database credentials, API keys, and other secrets, by securely storing and managing access to them.

The `ballerinax/aws.secretmanager` package provides APIs to interact with AWS Secrets Manager, enabling developers to programmatically manage secrets, including creating, retrieving, updating, and deleting secrets in their applications.

## Setup guide
Before using this connector in your Ballerina application, complete the following:
1. Create an [AWS account](https://portal.aws.amazon.com/billing/signup?nc2=h_ct&src=default&redirect_url=https%3A%2F%2Faws.amazon.com%2Fregistration-confirmation#/start)
2. [Obtain tokens](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)

## Quickstart

To use the `aws.secretmanager` connector in your Ballerina project, modify the `.bal` file as follows:

### Step 1: Import the module

Import the `ballerinax/aws.secretmanager` module into your Ballerina project.

```ballerina
import ballerinax/aws.secretmanager;
```

### Step 2: Instantiate a new connector

Create a new `secretmanager:Client` by providing the access key ID, secret access key, and the region.

```ballerina
configurable string accessKeyId = ?;
configurable string secretAccessKey = ?;

secretmanager:Client secretmanager = check new(region = secretmanager:US_EAST_1, auth = {
    accessKeyId,
    secretAccessKey
});
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

```ballerina
secretmanager:DescribeSecretResponse response = check secretManager->describeSecret("<secret-id>");
```

### Step 4: Run the Ballerina application

Use the following command to compile and run the Ballerina program.

```bash
bal run
```
