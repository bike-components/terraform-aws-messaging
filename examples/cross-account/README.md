# Cross-account FIFO topic → FIFO queue

A FIFO SNS topic in one AWS account (**acc-1**, the topic owner)
delivers to a FIFO SQS queue in another account (**acc-2**, the queue
owner). Each account is its own root configuration with its own state
and its own credentials:

| Directory | AWS profile | Owns | Uses this module? |
| --------- | ----------- | ---- | ----------------- |
| [`acc-1/`](acc-1) | `acc-1` | FIFO topic + topic policy | No — plain `aws_sns_topic` / `aws_sns_topic_policy` |
| [`acc-2/`](acc-2) | `acc-2` | FIFO queue + queue policy + subscription | Yes (`source = "../../.."`, `external_topic_arn`) |

- **acc-2 creates the subscription.** When the queue owner subscribes,
  SNS needs no confirmation step for the SQS endpoint. That's the
  AWS-recommended direction for cross-account SNS → SQS
  ([ADR 0005](../../docs/decisions/0005-cross-account-subscription-by-queue-owner.md)).
- **acc-1 has to allow it first.** The module can't write another
  account's topic policy, so it outputs the statement acc-1 has to merge
  in as `external_topic_policy_json`: `sns:Subscribe` for acc-2's root,
  limited to `sns:Protocol = sqs` and `sns:Endpoint` = the queue's ARN.
  acc-1 merges it into its own policy with `source_policy_documents`.
- **The grant is known before the queue exists.** The module builds the
  queue ARN from the queue's name, including the `.fifo` suffix, so a
  `terraform plan` in acc-2 already shows the grant. You don't need a
  targeted apply or a toggle.

## Prerequisites

- AWS CLI profiles `acc-1` and `acc-2` for two **different** accounts.
  If both point at the same account, the module sees a same-account
  topic and `external_topic_policy_json` is `null`.
- `jq`, used to pull the grant out of a saved plan.

## Apply sequence

The step numbers are shared across both directories, and the same
`STEP n` / `WAIT` banners appear in `acc-1/main.tf` and `acc-2/main.tf`.

```text
acc-1                               acc-2
─────                               ─────
STEP 1  create FIFO topic
        └─ topic_arn ─────────────▶ WAIT
                                    STEP 2  plan only → grant.json
WAIT ◀──────────── grant.json ──────┘
STEP 3  merge grant into topic policy
        └─ policy applied ────────▶ WAIT
                                    STEP 4  apply: queue + subscription
STEP 5  publish test message ─────▶ receive it
```

### STEP 1 (acc-1): create the FIFO topic

```bash
cd examples/cross-account/acc-1
terraform init
terraform apply                      # subscriber_policy_json = null → owner-only policy
TOPIC_ARN=$(terraform output -raw topic_arn)
```

### STEP 2 (acc-2): render the grant (plan only)

**Waits for:** `topic_arn` from STEP 1.

```bash
cd ../acc-2
terraform init
terraform plan -var "topic_arn=$TOPIC_ARN" -out=grant.tfplan
terraform show -json grant.tfplan \
  | jq -r '.planned_values.outputs.external_topic_policy_json.value' > grant.json
```

**Don't apply yet.** An apply would also try to create the subscription,
and SNS rejects it with `AuthorizationError` until STEP 3 is done. The
plan is only used to read the grant. Discard `grant.tfplan` afterwards.
STEP 4 runs a fresh apply. In a real two-team setup, `grant.json` is
what you send to the topic owner.

### STEP 3 (acc-1): merge the grant into the topic policy

**Waits for:** `grant.json` from STEP 2.

```bash
cd ../acc-1
terraform apply -var "subscriber_policy_json=$(cat ../acc-2/grant.json)"
terraform output topic_policy_json   # now includes AllowSubscribeFrom<acc-2 account id>
```

`aws_sns_topic_policy` replaces the whole policy, so acc-1 restates its
own `TopicOwnerAccess` statement next to the merged grant. Pass the same
`-var` on every later acc-1 apply, or move it into an untracked
`*.tfvars` file. Otherwise the grant is removed again.

### STEP 4 (acc-2): create the queue and subscription

**Waits for:** the STEP 3 apply to finish.

```bash
cd ../acc-2
terraform apply -var "topic_arn=$TOPIC_ARN"
```

This creates the FIFO queue `ex-messaging-cross-account-events.fifo`,
its queue policy (`sns.amazonaws.com`, `aws:SourceArn` = acc-1's topic),
and the subscription. The subscription is created in the topic's region,
which the module reads from the ARN.

### STEP 5 (acc-1 → acc-2): send a test message

```bash
aws sns publish --profile acc-1 --topic-arn "$TOPIC_ARN" \
  --message 'hello from acc-1' --message-group-id demo   # content-based dedup is on

aws sqs receive-message --profile acc-2 \
  --queue-url "$(terraform output -raw queue_url)" --wait-time-seconds 10
```

## Tearing down

Destroy in reverse order. Run `terraform destroy -var "topic_arn=$TOPIC_ARN"`
in `acc-2` first, then `terraform destroy` in `acc-1`.

## Encryption (KMS)

This example doesn't enable encryption. If you add it:

- **Topic encrypted with a CMK** (acc-1): this only affects publishing
  from acc-2. The key policy must allow acc-2 `kms:GenerateDataKey*`
  and `kms:Decrypt`, and the publishing principal needs the same
  permissions on that key ARN in its IAM policy. The module's topic tx
  policy doesn't include them. Delivery to SQS works either way.
- **Queue encrypted with a CMK** (acc-2): the key policy must allow
  `sns.amazonaws.com` `kms:GenerateDataKey*` and `kms:Decrypt`, ideally
  conditioned on `aws:SourceArn` = the topic ARN. The AWS-managed
  `alias/aws/sqs` key can't be used, because its policy can't grant SNS.
