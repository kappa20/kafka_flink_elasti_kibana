import random
import time
import uuid
from json import dumps
from kafka import KafkaProducer

# Configuration pour correspondre à votre setup Docker
producer = KafkaProducer(
    bootstrap_servers=['localhost:9092'],
    api_version=(0, 10, 2),
    value_serializer=lambda K: dumps(K).encode('utf-8'),
    metadata_max_age_ms=5000,
    request_timeout_ms=5000
)

print("--- [SUCCESS] Connected to Kafka! Starting WordCount Stream ---")

# Données de simulation pour le traitement de texte
usernames = ["LofiGirl", "TokyoBeats", "Anass_Dev", "JazzVibes", "BigData_Student"]
locations = ["Rabat, Morocco", "Tokyo, Japan", "Paris, France", "New York, USA", "Casablanca, Morocco"]
languages = ["en", "fr", "es", "ar"]
music_tweets = [
    "Chill beats to study and relax! #lofi #study",
    "Tokyo night vibes are the best for citypop music.",
    "Learning Apache Flink and Kafka for Big Data project.",
    "I love listening to jazz while coding in Python.",
    "The weather in Casablanca is perfect for outdoor music festivals!",
    "Check out my new lofi track on YouTube! RT if you like it.",
    "Artificial Intelligence is changing the way we produce music."
]

try:
    while True:
        # Création d'un dictionnaire avec tous les champs requis par le DDL de Flink
        cur_data = {
            "id_str": str(uuid.uuid4()),        # VARCHAR
            "username": random.choice(usernames), # VARCHAR
            "tweet": random.choice(music_tweets),   # VARCHAR
            "location": random.choice(locations), # VARCHAR
            "retweet_count": random.randint(0, 100), # BIGINT
            "followers_count": random.randint(100, 50000), # BIGINT
            "lang": random.choice(languages)       # VARCHAR
        }
        
        # Envoi vers le topic 'my-topic-test'
        future = producer.send('my-topic-test', value=cur_data)
        record_metadata = future.get(timeout=10)
        
        print(f"✔ Sent: {cur_data['username']} tweeted: {cur_data['tweet'][:30]}...")
        time.sleep(5) # Un tweet par seconde
except Exception as e:
    print(f"--- [ERROR] Producer crashed: {e} ---")