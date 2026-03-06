# ==============================================================
# Phase 3: Dockerfile
# This file tells Docker HOW to build an image of your app.
# Think of it as a recipe — each instruction creates a "layer".
# ==============================================================

# STEP 1: Base Image
# python:3.9-slim is a minimal Debian image with Python pre-installed.
# "slim" means it strips out things you don't need (docs, compilers),
# keeping your image small (~120MB vs ~900MB for the full image).
FROM python:3.9-slim

# STEP 2: Set the working directory inside the container.
# All subsequent commands (COPY, RUN, CMD) will execute from here.
# This is like doing `cd /app` inside the container.
WORKDIR /app

# STEP 3: Copy ONLY requirements.txt first, then install.
# WHY? Docker caches each layer. If requirements.txt hasn't changed,
# Docker reuses the cached layer and skips `pip install`.
# This turns a 60-second rebuild into a 2-second rebuild.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# STEP 4: Now copy the rest of the application code.
# If you change app.py, only THIS layer and below are rebuilt.
# The pip install layer above stays cached. This is the key optimization.
COPY . .

# STEP 5: Document which port the app uses.
# EXPOSE doesn't actually publish the port — it's documentation.
# You still need `-p 5000:5000` when running the container.
EXPOSE 5000

# STEP 6: Set environment variables.
# These are available inside the container at runtime.
ENV APP_VERSION=1.0.0

# STEP 7: The command to run when the container starts.
# Only ONE CMD is allowed per Dockerfile. If you have multiple,
# only the last one takes effect.
CMD ["python", "app.py"]
