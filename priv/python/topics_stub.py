def init_model(data, model_path):
    topics = [
        {
            "topic_model_id": 1,
            "model_title": "Title",
            "model_description": "Desc",
            "keywords": [],
        }
    ]
    assignments = []
    for statement in data:
        assignments.append(
            {"trained_topic_id": 1, "representative": True, "id": statement["id"]}
        )
    return assignments, topics
