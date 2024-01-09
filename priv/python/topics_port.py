from erlport.erlterms import Atom, Map, List
from erlport.erlang import set_message_handler, cast
import codecs
import numpy

topics_impl = None
TRAINING_DATA = []


def register_handler(dest):
    def handler(message):
        command = message[0]
        payload = translate(message[1])
        if command == b"init_model":
            init_model(payload, dest)

    set_message_handler(handler)
    return Atom(b"ok")


def import_impl(impl_name):
    global topics_impl
    if impl_name == b"Elixir.Discussit.TopicAnalyzer.Local":
        module_name = "topics"
    elif impl_name == b"Elixir.Discussit.StubTopicAnalyzer":
        module_name = "topics_stub"
    topics_impl = __import__(module_name)
    return Atom(b"ok")


def save_item(message):
    statement = translate(message)
    item = {
        "id": statement["id"],
        "content": statement["content"],
        "vector": numpy.asarray(statement["embedding"]["vector"]),
        "labelled_topic": statement["labelled_topic"],
    }
    TRAINING_DATA.append(item)
    return Atom(b"ok")


def init_model(path, dest):
    topic_assignments, topics = topics_impl.init_model(TRAINING_DATA, path)
    for topic in topics:
        cast(dest, (Atom(b"create_topic"), topic))
    for topic_assignment in topic_assignments:
        cast(dest, (Atom(b"assign_topic"), topic_assignment))

    cast(dest, (Atom(b"done")))


def merge_models(models, path):
    topics_impl.merge_models(models, codecs.decode(path))
    return Atom(b"ok")


def translate(target):
    if isinstance(target, List):
        res = list(target)
        if len(res) > 0:
            return [translate(i) for i in res]
        return res
    elif isinstance(target, Map):
        res = dict(target)
        new = {}
        for k, v in res.items():
            new[translate(k)] = translate(v)
        return new
    elif target == b"nil":
        return None
    elif isinstance(target, Atom):
        return codecs.decode(target)
    elif isinstance(target, str) or isinstance(target, bytes):
        return codecs.decode(target)
    else:
        return target
