def init_model(data, model_path):
    f = open(f"{model_path}/test.txt", "w+")
    f.close()
    f = open(f"{model_path}/2.txt", "w+")
    f.close()
    f = open(f"{model_path}/3.txt", "w+")
    f.close()
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


def merge_models(models, model_path):
    f = open(f"{model_path}/1.txt", "w+")
    f.close()
    f = open(f"{model_path}/2.txt", "w+")
    f.close()
    f = open(f"{model_path}/3.txt", "w+")
    f.close()
    return
