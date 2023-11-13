from flask import Flask
from flask_sock import Sock
from topics import (
    init_model,
    get_topics,
    load_model,
    cast_topics,
    cleanup_modules,
)
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
            TRAINING_DATA.append({"id": id, "content": content, "vector": vector})
            json_result = json.dumps({"message_type": "statement_received", "id": id})
            ws.send(json_result)
        if data["message_type"] == "init_model":
            payload = data["payload"]
            content = [item["content"] for item in TRAINING_DATA]
            embeddings = numpy.asarray([item["vector"] for item in TRAINING_DATA])
            ids = [item["id"] for item in TRAINING_DATA]
            model_path = payload["model_path"]
            api_key = payload["openai_api_key"]
            TRAINING_DATA.clear()
            topic_assignments, topic_model = init_model(
                content, embeddings, model_path, api_key
            )
            topics = get_topics(topic_model)
            casted_topics = cast_topics(topics)
            zipped_topic_assignments = [
                {"id": item[0], "topic": item[1]}
                for item in zip(ids, topic_assignments)
            ]
            result = {
                "message_type": "model_initialized",
                "payload": {
                    "topic_assignments": zipped_topic_assignments,
                    "topics": casted_topics,
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
