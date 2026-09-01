# Database credentials

This use case shows how the AWS Secrets Manager API can be used to keep a database credential out of the application's
configuration. It showcases;

- Reading the current version of a secret
- Parsing the JSON document of a database secret into a typed record
- Logging the credential with the password redacted
- Checking for a previous version to fall back on during a rotation

## Prerequisites

- AWS Account with Secrets Manager access
- AWS Access Key ID and Secret Access Key
- Ballerina Swan Lake 2201.12.0 or later

The caller needs `secretsmanager:GetSecretValue` on the secret, and `kms:Decrypt` on the KMS key encrypting it if that
key is a customer managed one.

## Configuration

Create a `Config.toml` file in the example's root directory and provide your AWS account-related configurations as
follows:

```toml
accessKeyId = "<AWS_ACCESS_KEY_ID>"
secretAccessKey = "<AWS_SECRET_ACCESS_KEY>"
region = "us-east-1"
secretId = "<SECRET_NAME_OR_ARN>"
```

`secretId` is the name or the ARN of a secret holding a JSON document with at least `username` and `password` — the
shape Secrets Manager creates for a database secret. A secret managed for an RDS instance also carries `engine`,
`host`, `port` and `dbname`, and the example prints those when they are present. There is no default: the example fails
at startup if `secretId` is not configured.

## Run the example

Execute the following command to run the example:

```bash
bal run
```
