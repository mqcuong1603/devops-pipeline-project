# Containerized CI/CD Pipeline with Jenkins, Docker & GitHub Webhooks

An end-to-end CI/CD pipeline that automatically tests, builds, containerizes, and deploys a Python Flask application whenever code is pushed to GitHub. Built on a DigitalOcean cloud server running Ubuntu 24.04.

## Architecture

```
┌──────────┐       webhook        ┌──────────────────────────────────────┐
│  GitHub   │ ──────────────────► │  Jenkins (DigitalOcean Droplet)      │
│  (repo)   │                     │                                      │
└──────────┘                      │  1. Checkout   ── Pull latest code   │
                                  │  2. Test       ── Run pytest suite   │
                                  │  3. Build      ── docker build       │
                                  │  4. Push       ── docker push        │
                                  │  5. Deploy     ── docker run         │
                                  └──────────────┬───────────────────────┘
                                                 │
                                  ┌──────────────▼───────────────────────┐
                                  │  Docker Hub                          │
                                  │  mqcuong1603/devops-pipeline-app     │
                                  └──────────────────────────────────────┘
```

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Application | Python 3, Flask | Lightweight REST API with health check endpoint |
| Testing | pytest | Unit tests run automatically before every build |
| Containerization | Docker | Application packaged as a portable image |
| CI/CD Engine | Jenkins (Declarative Pipeline) | Orchestrates the full build-test-deploy workflow |
| Registry | Docker Hub | Stores versioned Docker images |
| Infrastructure | DigitalOcean (Ubuntu 24.04) | Cloud server hosting Jenkins and the deployed app |
| Version Control | Git + GitHub Webhooks | Triggers pipeline automatically on every push |

## How It Works

Every `git push` to the `main` branch triggers the full pipeline automatically via a GitHub webhook. Jenkins pulls the latest code, runs the test suite, builds a Docker image tagged with the Jenkins build number, pushes it to Docker Hub, then stops any existing container and deploys the new version — all without manual intervention.

The Dockerfile uses a multi-step `COPY` strategy to leverage Docker's layer caching: `requirements.txt` is copied and dependencies installed before the application code. This means rebuilds that only change application logic skip the dependency installation step entirely, reducing build time significantly.

Credentials for Docker Hub are stored securely in Jenkins Credential Manager and injected at runtime — no secrets exist in the codebase or version control history.

## Project Structure

```
├── app.py                  # Flask application with / and /health endpoints
├── tests/
│   └── test_app.py         # 4 unit tests covering response codes and payloads
├── requirements.txt        # Python dependencies (Flask, pytest)
├── Dockerfile              # Multi-layer build with caching optimization
├── .dockerignore           # Keeps images lean by excluding dev files
├── Jenkinsfile             # Declarative pipeline: Checkout → Test → Build → Push → Deploy
└── .gitignore              # Excludes venvs, caches, IDE files, and .env
```

## API Endpoints

| Endpoint | Method | Response |
|---|---|---|
| `/` | GET | `{"message": "Hello from the DevOps Pipeline!", "status": "healthy", "version": "1.0.0"}` |
| `/health` | GET | `{"status": "ok"}` — used for container health checks |

## Pipeline Stages

**Checkout** — Clones the repository using the SCM configuration in the Jenkins job.

**Test** — Creates a Python virtual environment, installs dependencies, and runs `pytest` with verbose output. If any test fails, the pipeline stops immediately (fail fast principle).

**Build** — Builds two Docker images: one tagged with the Jenkins build number (`:5`, `:6`, etc.) for traceability, and one tagged `:latest` for convenience.

**Push** — Authenticates with Docker Hub using credentials stored in Jenkins and pushes both tagged images.

**Deploy** — Stops and removes the previous container (if running), then starts a new container from the freshly built image on port 5000.

## Infrastructure Setup

The server was provisioned as a DigitalOcean droplet (2 GB RAM, 2 CPUs, Ubuntu 24.04) with the following installed directly on the host:

- **Docker Engine** (CE) — installed from Docker's official repository, not the Ubuntu default package
- **Jenkins** (LTS) — running as a systemd service on port 8080, with the `jenkins` user added to the `docker` group for daemon access
- **OpenJDK 21** — required runtime for Jenkins
- **UFW firewall** — configured to allow SSH (22), Jenkins (8080), and the application (5000)

A non-root `deploy` user was created for all operational work, following the principle of least privilege.

## Key Concepts Demonstrated

- **Continuous Integration** — automated testing on every commit ensures broken code never gets packaged
- **Continuous Deployment** — zero-touch deployment from code push to live application
- **Infrastructure as Code** — the entire pipeline is defined in the `Jenkinsfile`, versioned alongside application code
- **Containerization** — the application runs identically on any machine that has Docker
- **Layer caching** — Dockerfile structured to minimize rebuild time
- **Secret management** — Docker Hub credentials stored in Jenkins, never in source code
- **Webhook-driven automation** — GitHub push events trigger the pipeline with no polling or manual intervention
- **Immutable deployments** — each build produces a uniquely tagged image; rollback is as simple as redeploying a previous tag

## Running Locally

```bash
# Clone the repo
git clone https://github.com/mqcuong1603/devops-pipeline-project.git
cd devops-pipeline-project

# Run tests
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m pytest tests/ -v

# Build and run with Docker
docker build -t devops-pipeline-app .
docker run -d -p 5000:5000 devops-pipeline-app
curl http://localhost:5000
```