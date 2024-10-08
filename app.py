"""Basic Flask application that prints a message."""

from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello_world():
    """Prints hello world."""
    return 'Hello World!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
