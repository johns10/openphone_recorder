import os
from bertopic import BERTopic
from bertopic.vectorizers import OnlineCountVectorizer
from bertopic.vectorizers import ClassTfidfTransformer
from river import cluster
from river_partial_fit import River


def get_path(account_id):
    account_string = account_id.decode()
    return f"/Users/johndavenport/Documents/github/openphone_recorder/priv/python/{account_string}"


def save_model(topic_model, path):
    backup_path = f"{path}_old"
    os.rename(path, backup_path)
    topic_model = save_new_model(topic_model, path)
    os.remove(backup_path)
    return topic_model


def save_new_model(topic_model, path):
    topic_model.save(path, serialization="pickle", save_ctfidf=True)
    return topic_model


def init_model(statements, account_id):
    model_path = get_path(account_id)
    cluster_model = River(cluster.DBSTREAM())
    vectorizer_model = OnlineCountVectorizer(stop_words="english")
    ctfidf_model = ClassTfidfTransformer(
        reduce_frequent_words=True, bm25_weighting=True
    )

    topic_model = BERTopic(
        hdbscan_model=cluster_model,
        vectorizer_model=vectorizer_model,
        ctfidf_model=ctfidf_model,
    )

    new_topics = fit_topics(topic_model, statements)
    save_new_model(topic_model, model_path)
    return new_topics


def train_model(statements, account_id):
    model_path = get_path(account_id)
    topic_model = BERTopic.load(model_path)
    new_topics = fit_topics(topic_model, statements)
    save_model(topic_model, model_path)
    return new_topics


def fit_topics(model, statements):
    topics = []
    input = [str(s) for s in statements]
    model.partial_fit(input)
    topics.extend(model.topics_)
    # We will have to slice the topic assignment out of this list
    new_topics = model.topics_[-input.__len__() :]
    return new_topics


def get_topics(account_id):
    model_path = get_path(account_id)
    topic_model = BERTopic.load(model_path)
    return topic_model.topic_labels_


def atexit_handler():
    try:
        print("atexit")
    except SystemExit:
        pass
