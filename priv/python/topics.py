import os
import openai
import numpy
from bertopic import BERTopic
from bertopic.vectorizers import OnlineCountVectorizer
from bertopic.vectorizers import ClassTfidfTransformer
from sentence_transformers import SentenceTransformer
from bertopic.representation import KeyBERTInspired, OpenAI
from river import cluster
from river_partial_fit import River
from umap import UMAP


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


def init_model(statements, embeddings, account_id):
    model_path = get_path(account_id)
    embedding_model = SentenceTransformer("all-MiniLM-L6-v2")
    cluster_model = River(cluster.DBSTREAM())
    vectorizer_model = OnlineCountVectorizer(
        stop_words="english", min_df=2, ngram_range=(1, 2)
    )
    ctfidf_model = ClassTfidfTransformer(
        reduce_frequent_words=True, bm25_weighting=True
    )
    umap_model = UMAP(
        n_neighbors=15, n_components=5, min_dist=0.0, metric="cosine", random_state=42
    )
    keybert_model = KeyBERTInspired()
    openai.api_key = "sk-..."
    prompt = """
    I have a topic that contains the following documents: 
    [DOCUMENTS]
    The topic is described by the following keywords: [KEYWORDS]

    Based on the information above, extract a short but highly descriptive topic label of at most 5 words. Make sure it is in the following format:
    topic: <topic label>
    """
    openai_model = OpenAI(
        model="gpt-3.5-turbo", exponential_backoff=True, chat=True, prompt=prompt
    )

    topic_model = BERTopic(
        embedding_model=embedding_model,
        hdbscan_model=cluster_model,
        vectorizer_model=vectorizer_model,
        ctfidf_model=ctfidf_model,
        umap_model=umap_model,
        representation_model=keybert_model,
        top_n_words=10,
        verbose=True,
    )

    new_topics = fit_topics(topic_model, statements, embeddings)
    save_new_model(topic_model, model_path)
    return new_topics


def train_model(statements, embeddings, account_id):
    model_path = get_path(account_id)
    topic_model = BERTopic.load(model_path)
    new_topics = fit_topics(topic_model, statements, embeddings)
    save_model(topic_model, model_path)
    return new_topics


def fit_topics(model, statements, embeddings):
    topics = []
    input = [str(s) for s in statements]
    numpy_embeddings = [numpy.asarray(embedding) for embedding in embeddings]
    model.partial_fit(input, numpy.asarray(numpy_embeddings))
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
