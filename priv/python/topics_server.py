from flask import Flask
from flask_sock import Sock
from topics import init_model, get_topics, load_model
import json
import numpy
import threading
from erlport.erlterms import Atom
from erlport.erlang import set_message_handler, cast
import socket

app = Flask(__name__)
app.debug = False
sock = Sock(app)
server_thread = None

TRAINING_DATA = []


@app.route("/init")
def init():
    return "<p>Hello, World!</p>"


@sock.route("/data")
def echo(ws):
    while True:
        binary_data = ws.receive()
        json_data = binary_data.decode()
        data = json.loads(json_data)
        if data["message_type"] == "statement_data":
            payload = data["payload"]
            id = payload["id"]
            content = payload["content"]
            vector = numpy.asarray(payload["embedding"]["vector"])
            TRAINING_DATA.append(
                {
                    "id": id,
                    "content": content,
                    "vector": vector,
                    "labelled_topic": payload["labelled_topic"],
                }
            )
            json_result = json.dumps({"message_type": "statement_received", "id": id})
            ws.send(json_result)
        if data["message_type"] == "init_model":
            payload = data["payload"]
            model_url = payload["model_url"]
            id = payload["id"]
            topic_assignments, topics = init_model(TRAINING_DATA, id, model_url)
            TRAINING_DATA.clear()
            result = {
                "message_type": "model_initialized",
                "payload": {
                    "topic_assignments": topic_assignments,
                    "topics": topics,
                },
            }
            json_result = json.dumps(result)
            ws.send(json_result)
        if data["message_type"] == "get_topics":
            payload = data["payload"]
            model_path = payload["model_path"]
            topic_model = load_model(model_path)
            topics = get_topics(topic_model)
            result = {"message_type": "topics_received", "payload": {"topics": topics}}
            json_result = json.dumps(result)
            ws.send(json_result)
        if data["message_type"] == "shutdown":
            msg = {"status": "stopped"}
            json_msg = json.dumps(msg)
            ws.send(msg)


def start_server():
    global server_thread
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.bind(("localhost", 0))
    port = sock.getsockname()[1]
    sock.close()
    if server_thread == None or not server_thread.is_alive():
        try:
            server_thread = threading.Thread(
                target=lambda: app.run(
                    host="localhost", port=port, debug=True, use_reloader=False
                )
            )
            server_thread.start()
            return {"status": "started", "port": port}
        except:
            return {"status": "not_started", "port": None}
    else:
        return {"status": "started", "port": port}
