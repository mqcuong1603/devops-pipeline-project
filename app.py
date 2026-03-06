from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route("/")
def home():
    return jsonify({
        "message": "Hello from the DevOps Pipeline!",
        "status": "healthy",
        "version": os.getenv("APP_VERSION", "1.0.0")
    })


@app.route("/health")
def health():
    return jsonify({"status": "ok"}), 200


if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
