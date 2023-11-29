import os
import openai
import numpy
from bertopic import BERTopic
from sklearn.feature_extraction.text import CountVectorizer
from bertopic.vectorizers import ClassTfidfTransformer
from sentence_transformers import SentenceTransformer
from bertopic.representation import KeyBERTInspired, OpenAI
from umap import UMAP
from hdbscan import HDBSCAN


def save_model(topic_model, path):
    backup_path = f"{path}_old"
    os.rename(path, backup_path)
    topic_model = save_new_model(topic_model, path)
    os.remove(backup_path)
    return topic_model


def save_new_model(topic_model, path):
    topic_model.save(path, serialization="safetensors", save_ctfidf=True)
    return topic_model


def new_model(api_key, items_count):
    min_cluster_size = 25
    n_neighbors = 15
    n_components = 5
    top_n_words = 10

    if items_count > 1000 and items_count < 10000:
        min_cluster_size = 5
        n_neighbors = 5

    if items_count < 250:
        min_cluster_size = 2
        n_neighbors = 2

    embedding_model = SentenceTransformer("all-MiniLM-L6-v2")
    hdbscan_model = HDBSCAN(
        min_cluster_size=min_cluster_size,
        metric="euclidean",
        cluster_selection_method="eom",
        prediction_data=True,
    )
    vectorizer_model = CountVectorizer(
        stop_words="english",
        ngram_range=(1, 2),
        # min_df=2,
    )
    ctfidf_model = ClassTfidfTransformer(
        # reduce_frequent_words=True, bm25_weighting=True
    )
    umap_model = UMAP(
        n_neighbors=n_neighbors,
        n_components=n_components,
        min_dist=0.0,
        metric="cosine",
        random_state=42,
    )
    openai.api_key = api_key
    title_prompt = """
    I have a topic that contains the following documents: 
    [DOCUMENTS]
    The topic is described by the following keywords: [KEYWORDS]

    Based on the information above, extract a short but highly descriptive topic label of at most 5 words. 
    Make sure it is in the following format:
    <topic label>
    """
    description_prompt = """
    I have a topic that contains the following documents: 
    [DOCUMENTS]
    The topic is described by the following keywords: [KEYWORDS]

    Based on the information above, extract a short but highly descriptive topic description of at most 100 words. 
    Make sure it is in the following format:
    <topic description>
    """
    title_model = OpenAI(
        model="gpt-3.5-turbo", exponential_backoff=True, chat=True, prompt=title_prompt
    )
    description_model = OpenAI(
        model="gpt-3.5-turbo",
        exponential_backoff=True,
        chat=True,
        prompt=description_prompt,
    )
    representation_model = {
        "keywords": KeyBERTInspired(),
        "model_title": KeyBERTInspired(),
        "model_description": KeyBERTInspired(),
    }
    return BERTopic(
        embedding_model=embedding_model,
        umap_model=umap_model,
        hdbscan_model=hdbscan_model,
        vectorizer_model=vectorizer_model,
        ctfidf_model=ctfidf_model,
        representation_model=representation_model,
        top_n_words=top_n_words,
        verbose=True,
    )


def init_model(data, model_path, api_key):
    content = [item["content"] for item in data]
    embeddings = numpy.asarray([item["vector"] for item in data])
    labels = cast_statements_and_topics(data)
    ids = [item["id"] for item in data]
    topic_model = new_model(api_key, content.__len__())
    new_topics = fit_topics(topic_model, content, embeddings, labels)
    doc_info = topic_model.get_document_info(content)
    doc_info["id"] = ids
    doc_info = doc_info.rename(
        columns=(
            {"Topic": "model_topic_id", "Representative_document": "representative"}
        )
    )
    new_topics = doc_info.get(["id", "model_topic_id", "representative"])
    topics = get_topics(topic_model)
    save_new_model(topic_model, model_path)
    del topic_model
    return new_topics.to_dict(orient="records"), cast_topics(topics)


def train_model(statements, embeddings, model_path_bytes):
    model_path = model_path_bytes.decode()
    topic_model = BERTopic.load(model_path)
    new_topics = fit_topics(topic_model, statements, embeddings)
    save_model(topic_model, model_path)
    return new_topics


def fit_topics(model, statements, embeddings, labels):
    topics, probs = model.fit_transform(statements, embeddings, y=labels)
    return topics


def load_model(model_path):
    return BERTopic.load(model_path)


def get_topics(topic_model):
    return topic_model.topic_aspects_


def cast_topics(topics):
    results = []
    for key, aspects in topics.items():
        values = []
        for id, value in aspects.items():
            values = values + [assign_values(key, value, id)]
        if results == []:
            results = values
        else:
            results = [v | r for v, r in zip(values, results)]
    return results


def cast_statements_and_topics(statements):
    result = []
    for statement in statements:
        if "labelled_topic" in statement and statement["labelled_topic"] != None:
            if statement["labelled_topic"]["title"]:
                result.append(statement["labelled_topic"]["model_id"])
            else:
                result.append(-1)
        else:
            result.append(-1)
    return result


def assign_values(key, value, id):
    return {key: format_value(key, value), "model_id": id}


def format_value(key, value):
    if key == "keywords":
        return [
            {"keyword": keyword[0], "probability": str(keyword[1])} for keyword in value
        ]
    if key in ["model_title", "model_description"]:
        result = ""
        for item in value:
            result = result + " " + item[0]
        return result


def get_hierarchical_topics(topic_model, docs):
    hierarchical_topics = topic_model.hierarchical_topics(docs)
    return hierarchical_topics


def regenerate_labels(model_path_bytes):
    model_path = model_path_bytes.decode()
    topic_model = BERTopic.load(model_path)
    topic_labels = topic_model.generate_topic_labels(nr_words=2, separator=", ")
    return topic_labels


def cleanup_modules():
    del CountVectorizer
    del ClassTfidfTransformer
    del SentenceTransformer
    del KeyBERTInspired
    del OpenAI
    del UMAP
    del HDBSCAN
