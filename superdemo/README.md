# Application Integration Super-Demo

Welcome to the **Application Integration Super-Demo** workspace! This directory provides an automated utility to deploy all core, standard Google Cloud Application Integration samples in a single command.

## Deployed Samples

The automated script deploys the following 14 standard integration scenarios:
1. **`call-rest-api`**: Invokes external web services using a native REST task.
2. **`case-conversion`**: Converts string array inputs to uppercase using Data Mapping.
3. **`catch-task-error`**: Exercises built-in error trapping and custom exception paths.
4. **`concat-string-array`**: Concatenates array items with separators.
5. **`ecom-order-processing`**: Mock back-office e-commerce approval and routing flow.
6. **`ecom-order-processing-using-data-transformer`**: The e-commerce scenario rewritten with advanced Data Transformer tasks.
7. **`filter-json-array`**: Filters array properties according to criteria.
8. **`foreach-loop-send-email`**: Loops over datasets to trigger sub-integrations.
9. **`merge-json-arrays`**: Merges separate JSON arrays into a single structure.
10. **`remove-json-property`**: Modifies and updates JSON nodes dynamically.
11. **`resolve-json`**: Evaluates nested JSON objects.
12. **`status-based-retry`**: Robust loop calling a REST service with intelligent retries.
13. **`string-to-uppercase`**: Standard text casing conversions.
14. **`update-json-array`**: Appends elements to JSON lists.

## Undeployed Samples

The following samples are present in the repository's `src/` directory but are explicitly excluded from the automated `deploy.sh` utility:

*   **`sftp-get-file`** and **`upload-download-gcs-sftp`**: Require provisioning an external, network-accessible SFTP server, setting up specific ssh keys, creating target Google Cloud Storage buckets, and configuring the SFTP/GCS Integration Connectors.
*   **`adk-incident-management`** and **`adk-order-processing`**: Rely on custom Integration Connector SDK (ADK) configurations that require pre-provisioned connector profiles and backend connection integrations.
*   **`vertex-ai-task`** and **`vertex-agents-bigquery`**: Depend on active Vertex AI model endpoints, specific regional ML services, pre-built BigQuery tables, and sophisticated IAM permission bindings.

### Rationale Behind the Selection

The decision to exclude these samples and focus on the 14 standard integrations was made to ensure an out-of-the-box, frictionless "superdemo" experience:

1.  **Zero-Dependency Execution**: The 14 deployed integrations rely entirely on native, built-in Application Integration tasks (such as Data Mapping, REST API triggers, Data Transformers, loops, and native exceptions). They can be deployed to any clean GCP project without requiring third-party accounts, external servers, or pre-existing databases.
2.  **Frictionless Setup**: Including connector-based or agent-based integrations would cause the automated script to fail unless users engaged in complex, manual credential configuration and external platform setups beforehand.
3.  **No Auxiliary Cost or Permission Overhead**: Excluded samples require enterprise-level billing permissions, connector provisioning costs, and additional security policies. The chosen 14 samples run fully within standard limits and have a near-zero cost profile.

See [SETUP.md](SETUP.md) for full configuration details, and [GUIDE.md](GUIDE.md) to learn how to run and test each integration.
