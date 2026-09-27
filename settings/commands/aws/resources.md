---
description: List key AWS resources in current account
---

Show me an overview of key AWS resources in the current account/region:

**Compute:**
- EC2 instances (count by state: running, stopped)
- ECS clusters and services
- Lambda functions (count)

**Storage:**
- S3 buckets (top 10 by size if possible)
- EBS volumes (count, total size)

**Database:**
- RDS instances (count by engine)
- DynamoDB tables (count)

**Network:**
- VPCs (count)
- Load balancers (count by type)

Keep it high-level - just counts and summaries, not detailed listings.
Show the AWS CLI commands you're running so I can reuse them.
