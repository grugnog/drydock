# Drydock

Library of Docker application templates following a common pattern.

## What is the Drydock Pattern

### All images

* Updated regularly
* Built and tested automatically
* Have strong code quality standards
* Work in both sandbox and CI environments
* Agnostic to sandbox tools - can work with Docker Compose or something else
* Agnostic to CI server/tool selection
* Support "exposed commands" to make Dockerized commands discoverable and avoid running non-container based dev/build tools
* Can be built on (using FROM) or can be extracted and customized fully
* Uses environment variables for configuration
* Standardized mount-points and environment variables for each application
* Use "lazy load" bootstrapping to make it easy to trigger build or import processes
* Support build processes that bundle database/indexes to make it fast and easy to spin up sandboxes and reset CI environments
* Reduce friction working with PaaS hosting environments by providing highly accurate reproductions

### Production images

* Support immutable deployment patterns - final image build as part of CI pipeline and can run in full read-only mode
* Compatible - image tests include full application automated tests and platform validation checks
* Secure:
  * Start from only trusted images, pin versions for images and key packages
  * Hardened to USGCB via STIG and scanned for compliance
  * NIST 800.53 compliance documented in OpenControl format
  * Processes run as non-root user
* Optimized for running in Kubernetes environments:
  * Supports "retry/crash on connection fail" service start-up
  * Provides health check endpoints
  * Provides Prometheus metric exporter
  * Keep images as small as possible (e.g. by using multi-stage builds)
  * Supports containerized persistent state (e.g. clustered databases managed via operators) or externalized storage (e.g. RDS)