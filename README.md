
# Takeoff GCP Applied Skills Project

---
**NOTE**

Readme (and _some_ things) are still in progress / not enabled / not working.
Contact me in Slack if any questions

---

This project is prepared for Applied Skills Project session by [Vadym Liubko](http://github.com/vliubko)

Project contains three levels:

| Level | Short description  | URL                                         |
|-------|--------------------|---------------------------------------------|
| 1     | Website            | https://takeoff-projects.github.io/vliubko/ |
| 2     | RESTful API        | _in progress_
| 3     | Whistles and bells | _in progress_ |


## Tech Stack


### Website

- **Bootstrap** + **jQuery**: to build the layout
- client-side **JavaScript** + **Firestore DB**: to save/delete the data
- **Github Actions**: to build and deploy the project
- **Github Pages**: to host the static Website

### RESTful API

- [layout structure](https://github.com/TakeoffTech/webhook-provider/blob/master/docs/project_structure.md): it was proposed by arch group
- [go-gin](https://github.com/gin-gonic/gin): web framework with all the stuff needed for a quickstart
- [OpenTelemetry client](https://github.com/open-telemetry/opentelemetry-go): configured to send traces to the [Google Tracing](https://console.cloud.google.com/traces/list?project=roi-takeoff-user77)
- [swaggo/swag](https://github.com/swaggo/swag): to generate OpenAPI/Swagger docs
- 
## Run Locally

Clone the project

```bash
  git clone https://link-to-project
```

Go to the project directory

```bash
  cd my-project
```

Install dependencies

```bash
  npm install
```

Start the server

```bash
  npm run start
```

  
## Features

Specifications:

* Mult-stage lightweight Docker image
* Cached steps in the Docker image (faster CI)
* Health checks (readiness and liveness)
* Graceful shutdown on interrupt signals
* File watcher for secrets and configmaps
* Instrumented with Prometheus
* Tracing with Istio and Jaeger
* Linkerd service profile
* Structured logging with zap 
* 12-factor app with viper
* Fault injection (random errors and latency)
* Swagger docs
* Helm and Kustomize installers
* End-to-End testing with Kubernetes Kind and Helm
* Kustomize testing with GitHub Actions and Open Policy Agent
* Multi-arch container image with Docker buildx and Github Actions
* CVE scanning with trivy
## Demo

Insert gif or link to demo

  