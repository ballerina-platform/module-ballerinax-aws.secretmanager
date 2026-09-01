# Secret rotation audit

This use case shows how the AWS Secrets Manager API can be used to report on the rotation posture of a group of
secrets. It showcases;

- Discovering secrets by tag key with a filtered batch call
- Paging through the results with `nextToken`
- Reporting the secrets an individual call could not retrieve
- Reading the rotation metadata of a secret without decrypting its value

## Prerequisites

- AWS Account with Secrets Manager access
- AWS Access Key ID and Secret Access Key
- Ballerina Swan Lake 2201.12.0 or later

The caller needs `secretsmanager:BatchGetSecretValue` on the account, plus `secretsmanager:GetSecretValue` and
`secretsmanager:DescribeSecret` on each audited secret. A secret the caller cannot decrypt is reported as a skipped
entry rather than failing the run.

## Configuration

Create a `Config.toml` file in the example's root directory and provide your AWS account-related configurations as
follows:

```toml
accessKeyId = "<AWS_ACCESS_KEY_ID>"
secretAccessKey = "<AWS_SECRET_ACCESS_KEY>"
region = "us-east-1"
tagKey = "<TAG_KEY_ON_THE_AUDITED_SECRETS>"
rotationSlaDays = 90
```

`tagKey` is the tag key that marks a secret as in scope for the audit — for example `owner` or `managed-by`. Every
secret in the region carrying that key is audited, whatever its value. There is no default: the example fails at
startup if `tagKey` is not configured.

`rotationSlaDays` is the number of days a secret may go without rotating before the audit reports it. It defaults to
`90`.

## Run the example

Execute the following command to run the example:

```bash
bal run
```
