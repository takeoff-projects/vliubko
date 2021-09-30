
# oms-lite

---
### IMPORTANT NOTE

Readme (and _some_ things) are still in progress / not enabled / not working.  
_Contact me in Slack if any questions_

---
![OMS lite logo](public/oms-lite-logo.png?raw=true "OMS lite logo")

Cola and Pepsi have their _light_ versions, so perhaps OMS also should has?  
Welcome **OMS-lite** — a magic place where an order could contain only one product!

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

|                              |                                 |
|------------------------------|---------------------------------|
| **HTML/JavaScript**          | fully client-side rendering     |
| **Bootstrap**  +  **jQuery** | to build the layout             |
| **Firestore DB**             | to save/delete the data         |
| **Github Actions**           | to build and deploy the project |
| **Github Pages**             | to host the static Website      |

### RESTful API

|                                                                                                             |                                                                                                                             |
|-------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| **layout structure**  https://github.com/TakeoffTech/webhook-provider/blob/master/docs/project_structure.md | as it was proposed by arch group                                                                                            |
| **go-gin** https://github.com/gin-gonic/gin                                                                 | web framework with all the stuff needed for a quickstart                                                                    |
| **OpenTelemetry client** https://github.com/open-telemetry/opentelemetry-go                                 | configured to send traces to the  [Google Tracing](https://console.cloud.google.com/traces/list?project=roi-takeoff-user77) |
| **swaggo/swag** https://github.com/swaggo/swag                                                              | to generate OpenAPI/Swagger docs                                                                                            |
| **sqlc** https://github.com/kyleconroy/sqlc                                                                 | to generate type-safe source code from SQL                                                                                  |
| **air** https://github.com/cosmtrek/air                                                                     | to enable faster development (live reload for for Go apps)                                                                  |

## Run Locally

Clone the project

```bash
  git clone https://github.com/takeoff-projects/vliubko
```

Go to the project directory

```bash
  cd vliubko
```

Start UI and API

```bash
  make run
```

Open separate terminal window and run DB migrations

```bash
  make migrate-up
```

## Features

Specifications:

* Multi-stage lightweight Docker image
* Cached steps in the Docker image (faster CI)
* Cached Docker buildx and Github Actions (faster CI)
* GolangCI linter for Pull Requests
* Graceful shutdown on interrupt signals
<!-- * Health checks (readiness and liveness) -->
* Tracing with OpenTelemetry and Google Trace
* Swagger docs
<!-- * Helm and Kustomize installers -->
<!-- * End-to-End testing with Kubernetes Kind and Helm -->
<!-- * CVE scanning with trivy -->
## Demo

Insert gif or link to demo

![OMS lite logo](public/oms-lite-str.png?raw=true "OMS lite logo")