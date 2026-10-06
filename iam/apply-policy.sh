#!/usr/bin/env bash
# Push iam/agentcore-lab-policy.json to AWS as a new policy version.
# Run with an ADMIN profile (not agentcore-lab, which cannot edit IAM policies):
#   ./iam/apply-policy.sh            # uses AWS_PROFILE or default
#   ADMIN_PROFILE=default ./iam/apply-policy.sh
set -euo pipefail

POLICY_NAME="agentcore-lab-policy"
USER_NAME="agentcore-lab"
DIR="$(cd "$(dirname "$0")" && pwd)"
FILE="$DIR/agentcore-lab-policy.json"
PROFILE_ARGS=()
[[ -n "${ADMIN_PROFILE:-}" ]] && PROFILE_ARGS=(--profile "$ADMIN_PROFILE")

python3 -m json.tool "$FILE" > /dev/null   # fail fast on bad JSON

ACCOUNT_ID=$(aws sts get-caller-identity "${PROFILE_ARGS[@]}" --query Account --output text)
ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"

if ! aws iam get-policy --policy-arn "$ARN" "${PROFILE_ARGS[@]}" > /dev/null 2>&1; then
  echo "Creating $POLICY_NAME ..."
  aws iam create-policy --policy-name "$POLICY_NAME" \
    --policy-document "file://$FILE" "${PROFILE_ARGS[@]}" > /dev/null
else
  # IAM keeps at most 5 versions: delete the oldest non-default one if full
  VERSIONS=$(aws iam list-policy-versions --policy-arn "$ARN" "${PROFILE_ARGS[@]}" \
    --query 'Versions[?IsDefaultVersion==`false`].VersionId' --output text)
  COUNT=$(aws iam list-policy-versions --policy-arn "$ARN" "${PROFILE_ARGS[@]}" \
    --query 'length(Versions)' --output text)
  if [[ "$COUNT" -ge 5 ]]; then
    OLDEST=$(echo "$VERSIONS" | tr '\t' '\n' | sort -V | head -1)
    echo "Deleting oldest version $OLDEST (IAM limit is 5) ..."
    aws iam delete-policy-version --policy-arn "$ARN" --version-id "$OLDEST" "${PROFILE_ARGS[@]}"
  fi
  echo "Publishing new default version of $POLICY_NAME ..."
  aws iam create-policy-version --policy-arn "$ARN" \
    --policy-document "file://$FILE" --set-as-default "${PROFILE_ARGS[@]}" > /dev/null
fi

# Attach to the lab user (no-op if already attached)
if aws iam get-user --user-name "$USER_NAME" "${PROFILE_ARGS[@]}" > /dev/null 2>&1; then
  aws iam attach-user-policy --user-name "$USER_NAME" --policy-arn "$ARN" "${PROFILE_ARGS[@]}"
  echo "Attached to user $USER_NAME."
else
  echo "User $USER_NAME not found yet - create it, then re-run to attach."
fi

aws iam get-policy --policy-arn "$ARN" "${PROFILE_ARGS[@]}" \
  --query 'Policy.{Name:PolicyName,DefaultVersion:DefaultVersionId,Updated:UpdateDate}' --output table
