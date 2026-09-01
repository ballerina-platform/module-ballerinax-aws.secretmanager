# Changelog

This file contains all the notable changes done to the Ballerina AWS Secrets Manager package through the releases.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-09-01 

This release revamps the connector's authentication and region configuration to use the shared
[`ballerinax/aws`](https://github.com/ballerina-platform/module-ballerinax-aws) package, so that all AWS
connectors share a single, consistent credential model.
([Revamp Connector Authentication Flow](https://github.com/wso2-enterprise/integration-engineering/issues/2091))

It contains breaking changes. See the "Migrating from 0.4.x" section below.

### Changed
- **[Breaking]** Authentication configuration is now sourced from `ballerinax/aws.auth` instead of being
  defined locally by this package. The `ConnectionConfig.auth` field type changed from
  `secretmanager:StaticAuthConfig|secretmanager:EC2_IAM_ROLE|secretmanager:DEFAULT_CREDENTIALS` to
  `auth:AuthConfig`. This is a widening — the former static credentials remain supported, with five new
  credential sources added.
- **[Breaking]** The `ConnectionConfig.region` field type changed from `secretmanager:Region` to
  `aws:Region|string`. The `string` alternative allows regions that are not yet present in the `aws:Region`
  enum to be supplied directly. `DescribeSecretResponse.primaryRegion` and `ReplicationStatus.region` changed
  in the same way.
- **[Breaking]** The detail type of `secretmanager:Error` changed from `secretmanager:ErrorDetails` to
  `aws:ErrorDetails`, so that all AWS connectors report failures through a single, shared error detail record.
  The two records have identical fields, with `aws:ErrorDetails` additionally including the optional
  `requestId` field, so field access on the value returned by `error.detail()` continues to work unchanged —
  only explicit `secretmanager:ErrorDetails` type references need updating.
- **[Breaking]** `Client.close` is now a regular method rather than a remote method, so it is invoked as
  `secretmanager.close()` instead of `secretmanager->close()`. Closing the client is a local resource-release
  operation, not a call to the remote service.
- **[Breaking]** `DescribeSecretResponse.description`, `.owningService` and `.primaryRegion` are now
  optional fields. All three were declared as required, but AWS returns each only when it applies:
  `Description` only when the secret has one, `OwningService` only for a secret managed by another AWS
  service, and `PrimaryRegion` only for a replicated secret. None is returned for a plain, unreplicated,
  customer-owned secret, so describing one left the three fields holding nil in spite of their
  non-nilable declared types — `response.description.length()` compiled and then panicked at run time.
  Reading any of the three is now a nilable access the compiler checks.
- The AWS SDK for Java version was updated from `2.30.22` to `2.41.30`.
- The minimum supported Ballerina distribution is now `2201.12.0` (Swan Lake Update 12), up from
  `2201.11.0`.

### Removed
- **[Breaking]** `secretmanager:StaticAuthConfig` has been removed in favour of the `ballerinax/aws.auth`
  equivalent. Its replacement, `auth:StaticAuthConfig`, has the same `accessKeyId`, `secretAccessKey` and
  optional `sessionToken` fields, so inline record literals continue to work unchanged — only explicit type
  references need updating.
- **[Breaking]** `secretmanager:DEFAULT_CREDENTIALS` has been removed in favour of
  `auth:DEFAULT_CREDENTIALS`, which resolves through the same AWS default credential provider chain.
- **[Breaking]** `secretmanager:EC2_IAM_ROLE` has been removed. It was accepted but never honoured — any
  value other than a static credentials record fell through to the default credential provider chain, which
  already covers the EC2 instance profile. Use `auth:DEFAULT_CREDENTIALS` instead.
- **[Breaking]** `secretmanager:ErrorDetails` has been removed in favour of `aws:ErrorDetails`. The
  replacement record is structurally identical to the one it replaces, plus the optional `requestId` field.
- **[Breaking]** The `secretmanager:Region` enum has been removed in favour of `aws:Region`.

### Added
- Support for five additional AWS credential sources, available through `auth:AuthConfig`:
  - `auth:ProfileAuthConfig` — credentials from a named profile in a local AWS credentials file.
  - `auth:AssumeRoleConfig` — temporary credentials obtained by assuming an IAM role via AWS STS.
  - `auth:WebIdentityConfig` — web identity (OIDC) federation, including IAM Roles for Service Accounts (IRSA).
  - `auth:SsoAuthConfig` — AWS IAM Identity Center (SSO).
  - `auth:ProcessAuthConfig` — credentials sourced from an external credential process.
- A new optional `ConnectionConfig.endpoint` field of type `aws:EndpointConfig`, for selecting FIPS or
  dualstack endpoint variants and for overriding the endpoint entirely (for example, LocalStack or VPC
  interface endpoints).
- A new optional `requestId` field on `aws:ErrorDetails`, carrying the AWS request ID of the failed call to
  simplify support escalations.
- New `aws:Region` members not present in the former `secretmanager:Region` enum.

### Fixed
- `batchGetSecretValue` failed with an `InherentTypeViolation` (`incompatible types: expected
  'aws.secretmanager:ApiError', found 'aws.secretmanager:SecretValue'`) whenever the response carried a
  secret value, which is to say on every successful call. The array holding the returned values was
  created with `ApiError` as its element type instead of `SecretValue`.
- `getSecretValue` ignored the `versionStage` selector and applied its value to the request's `versionId`
  instead, so `versionStage = "AWSCURRENT"` was sent as a version ID and the service reported the version
  as missing. Selecting a version by staging label now works.
- `describeSecret` no longer stores a nil under `description`, `owningService` or `primaryRegion` when AWS
  omits the corresponding field; the key is left absent, as it already was for every other conditional
  field on the record.
- The credential source's resources are now released when client initialization fails part-way through,
  instead of being left behind with no client to close them.
- `Client.close` is now idempotent, so a second call no longer fails on the already-closed native client.

### Migrating from 0.4.x

Add an `import ballerinax/aws;` alongside the existing Secrets Manager import, and qualify region members
with `aws:` rather than `secretmanager:`. Authentication record literals do not need to change:

```ballerina
// 0.4.x
import ballerinax/aws.secretmanager;

secretmanager:ConnectionConfig config = {
    region: secretmanager:US_EAST_1,
    auth: {accessKeyId, secretAccessKey}
};
```

```ballerina
// 1.0.0
import ballerinax/aws;
import ballerinax/aws.secretmanager;

secretmanager:ConnectionConfig config = {
    region: aws:US_EAST_1,
    auth: {accessKeyId, secretAccessKey}
};
```

Code that referred to the removed authentication types by name must be updated to the `ballerinax/aws.auth`
equivalents. The fields, including the optional `sessionToken`, are unchanged:

```ballerina
// 0.4.x
secretmanager:StaticAuthConfig authConfig = {accessKeyId, secretAccessKey, sessionToken};
```

```ballerina
// 1.0.0
import ballerinax/aws.auth;

auth:StaticAuthConfig authConfig = {accessKeyId, secretAccessKey, sessionToken};
```

`secretmanager:DEFAULT_CREDENTIALS` and `secretmanager:EC2_IAM_ROLE` both become
`auth:DEFAULT_CREDENTIALS`:

```ballerina
// 0.4.x
secretmanager:ConnectionConfig config = {
    region: secretmanager:US_EAST_1,
    auth: secretmanager:EC2_IAM_ROLE
};
```

```ballerina
// 1.0.0
secretmanager:ConnectionConfig config = {
    region: aws:US_EAST_1,
    auth: auth:DEFAULT_CREDENTIALS
};
```

Code that named `secretmanager:ErrorDetails` when inspecting an error must use `aws:ErrorDetails` instead.
Field access is unchanged:

```ballerina
// 0.4.x
if result is secretmanager:Error {
    secretmanager:ErrorDetails details = result.detail();
    io:println(details.errorCode);
}
```

```ballerina
// 1.0.0
if result is secretmanager:Error {
    aws:ErrorDetails details = result.detail();
    io:println(details.errorCode);
}
```

Code that read `description`, `owningService` or `primaryRegion` off a `DescribeSecretResponse` must handle
their absence. The values were never guaranteed — the field declarations simply did not admit it:

```ballerina
// 0.4.x — compiles, then panics on a secret that has no description
io:println(response.description.length());
```

```ballerina
// 1.0.0 — the compiler requires the nil case to be handled
string description = response.description ?: "<none>";
io:println(description.length());
```

Calls to `close` must use the method-call syntax instead of the remote-call syntax:

```ballerina
// 0.4.x
check secretmanager->close();
```

```ballerina
// 1.0.0
check secretmanager.close();
```

## [0.4.0]

### Added
- [Support default credential login for the AWS Secret Manager connector](https://github.com/wso2-enterprise/wso2-integration-internal/issues/4611)
