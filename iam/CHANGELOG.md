# AgentCoreLabPolicy changelog

Newest first. One line per change: date · lab · what changed · the AccessDenied that caused it.

| Date | Lab | Change | Reason |
| --- | --- | --- | --- |
| 2026-10-04 | Notebook 01/02 | Exempted bedrock:InvokeModel* from the us-east-1 lock; new deny allows them only in us-east-1/us-east-2/us-west-2 | us. cross-region profile routed Haiku 4.5 to us-east-2 -> explicit deny |
| 2026-10-04 | Setup | Removed bedrock:Converse/ConverseStream (not real IAM actions; covered by InvokeModel*). Scoped iam:CreateServiceLinkedRole to aws-service-role/* for AgentCore + Application Signals | Console policy validator errors/warning |
| 2026-10-04 | Setup | Initial policy: Bedrock invoke, AgentCore, deploy toolkit services, AgentCore-only IAM roles, us-east-1 lock | Starting point for the course |
