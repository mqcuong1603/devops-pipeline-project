# DevOps CI/CD Pipeline Project

A containerized CI/CD pipeline that automatically tests, builds, and pushes a Python Flask application using Git, Docker, and Jenkins.

## Project Structure

```
devops-pipeline-project/
├── app.py                 # Flask web server (Phase 1)
├── requirements.txt       # Python dependencies (Phase 1)
├── tests/
│   └── test_app.py        # Unit tests for pytest (Phase 1)
├── .gitignore             # Git ignore rules (Phase 2)
├── Dockerfile             # Container build instructions (Phase 3)
├── .dockerignore          # Docker build ignore rules (Phase 3)
├── Jenkinsfile            # CI/CD pipeline definition (Phase 4)
└── README.md              # You are here
```

---

## Phase 1: Run the Application Locally

```bash
# Create and activate a virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run the app
python app.py

# Test it (in another terminal)
curl http://localhost:5000
curl http://localhost:5000/health

# Run the unit tests
python -m pytest tests/ -v
```

You should see 4 tests pass. If they do, Phase 1 is complete.

---

## Phase 2: Set Up Git

```bash
# Initialize the repo
cd devops-pipeline-project
git init

# Stage all files
git add .

# First commit
git commit -m "Initial commit: Flask app with tests"

# Connect to your remote repo (create one on GitHub first)
git remote add origin https://github.com/YOUR_USERNAME/devops-pipeline-project.git

# Push
git branch -M main
git push -u origin main
```

---

## Phase 3: Build and Run with Docker

```bash
# Build the Docker image
docker build -t devops-pipeline-app:latest .

# Run it as a container
# -d = detached (runs in background)
# -p 5000:5000 = map host port 5000 to container port 5000
docker run -d -p 5000:5000 --name my-app devops-pipeline-app:latest

# Test it
curl http://localhost:5000

# View running containers
docker ps

# View container logs
docker logs my-app

# Stop and remove the container
docker stop my-app
docker rm my-app
```

### Useful Docker Commands to Know

| Command | What it does |
|---|---|
| `docker images` | List all local images |
| `docker ps` | List running containers |
| `docker ps -a` | List ALL containers (including stopped) |
| `docker logs <name>` | View container output |
| `docker exec -it <name> bash` | Open a shell inside a running container |
| `docker system prune` | Clean up unused images/containers |

---

## Phase 4: Set Up Jenkins

### Option A: Run Jenkins in Docker (Recommended for learning)

```bash
# Create a Docker network so Jenkins can talk to other containers
docker network create jenkins

# Run Jenkins with Docker-in-Docker support
docker run -d \
  --name jenkins \
  --network jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts

# Get the initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Then open http://localhost:8080 and paste that password.

### Option B: Install Jenkins directly on Linux

```bash
# Add Jenkins repo and install
sudo apt update
sudo apt install -y openjdk-17-jdk
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install -y jenkins
sudo systemctl start jenkins
```

### Configure Jenkins

1. **Install Plugins**: Go to Manage Jenkins → Plugins → Install:
   - Git plugin
   - Docker Pipeline plugin
   - Pipeline plugin (usually pre-installed)

2. **Add Docker Hub Credentials**:
   - Go to: Manage Jenkins → Credentials → System → Global credentials
   - Click "Add Credentials"
   - Kind: Username with password
   - ID: `dockerhub-credentials` (must match the Jenkinsfile)
   - Username: your Docker Hub username
   - Password: your Docker Hub password or access token

3. **Create the Pipeline Job**:
   - New Item → Enter name → Select "Pipeline" → OK
   - Under Pipeline section:
     - Definition: "Pipeline script from SCM"
     - SCM: Git
     - Repository URL: your GitHub repo URL
     - Branch: `*/main`
   - Save and click "Build Now"

4. **(Optional) Set Up a Webhook**:
   - In GitHub: Settings → Webhooks → Add webhook
   - Payload URL: `http://YOUR_JENKINS_URL/github-webhook/`
   - Content type: `application/json`
   - Events: Just the push event
   - Now Jenkins triggers automatically when you push code!

---

## How It All Connects

```
Developer pushes code to GitHub
         │
         ▼
GitHub webhook triggers Jenkins
         │
         ▼
┌─────────────────────────────┐
│  JENKINS PIPELINE           │
│                             │
│  1. Checkout  ─ Pull code   │
│  2. Test      ─ Run pytest  │
│  3. Build     ─ docker build│
│  4. Push      ─ docker push │
└─────────────────────────────┘
         │
         ▼
Docker image available on Docker Hub
(ready to be pulled and deployed anywhere)
```

---

## Troubleshooting

**"Permission denied" when Jenkins runs Docker commands:**
```bash
# Add the jenkins user to the docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

**Tests fail in Jenkins but pass locally:**
- Check that Jenkins has Python 3 installed
- The Jenkinsfile creates a virtual environment to isolate dependencies

**Docker build fails with "no space left on device":**
```bash
docker system prune -a   # WARNING: removes all unused images
```

---

## What You've Learned

| Phase | Skill | Why It Matters |
|---|---|---|
| 1 | Python Flask, pytest, requirements.txt | Every pipeline needs an application to deploy |
| 2 | Git, .gitignore, remote repos | Version control is the trigger for CI/CD |
| 3 | Docker, Dockerfile, image layers | Containers make deployments reproducible |
| 4 | Jenkins, Jenkinsfile, credentials | Automation eliminates manual error |
