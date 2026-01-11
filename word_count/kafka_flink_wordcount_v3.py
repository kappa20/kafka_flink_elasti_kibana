import os
import re
import string
import codecs
from pyflink.table import TableEnvironment, EnvironmentSettings, DataTypes, Row
from pyflink.table.expressions import col, lit
from pyflink.table.udf import udf, udtf, ScalarFunction

def run_wordcount_pipeline():
    # 1. Environment Setup
    env_settings = EnvironmentSettings.in_streaming_mode()
    t_env = TableEnvironment.create(env_settings)

    # 2. JARs - On ajoute flink-python si tu l'as téléchargé
    kafka_jar = "file:///opt/flink/lib/flink-sql-connector-kafka-3.0.1-1.18.jar"
    es_jar = "file:///opt/flink/lib/flink-sql-connector-elasticsearch7-3.0.1-1.17.jar"
    t_env.get_config().get_configuration().set_string("pipeline.jars", f"{kafka_jar};{es_jar}")

    # 3. DDLs
    source_ddl = """
        CREATE TABLE source_table(
            id_str STRING,
            username STRING,
            tweet STRING,
            location STRING,
            retweet_count BIGINT,
            followers_count BIGINT,
            lang STRING
        ) WITH (
            'connector' = 'kafka',
            'topic' = 'my-topic-test',
            'properties.bootstrap.servers' = 'kafka:29092',
            'properties.group.id' = 'flink_wordcount_group',
            'scan.startup.mode' = 'latest-offset',
            'format' = 'json'
        )
    """

    sink_wordcount_ddl = """
        CREATE TABLE sink_wordcount_table(
            word STRING,
            number BIGINT,
            PRIMARY KEY (word) NOT ENFORCED
        ) WITH (        
            'connector' = 'elasticsearch-7',
            'index' = 'demowordcloud',
            'hosts' = 'http://elasticsearch:9200',
            'format' = 'json',
            'sink.bulk-flush.max-actions' = '1'
        )
    """

    sink_full_data_ddl = """
        CREATE TABLE sink_full_table(
            id_str STRING,
            username STRING,
            tweet STRING,
            location STRING,
            retweet_count BIGINT,
            followers_count BIGINT,
            lang STRING
        ) WITH (        
            'connector' = 'elasticsearch-7',
            'index' = 'tweets_full_data',
            'hosts' = 'http://elasticsearch:9200',
            'format' = 'json',
            'sink.bulk-flush.max-actions' = '1'
        )
    """

    t_env.execute_sql(source_ddl)
    t_env.execute_sql(sink_wordcount_ddl)
    t_env.execute_sql(sink_full_data_ddl)

    # --- UDF DEFINITIONS ---

    @udf(result_type=DataTypes.STRING())
    def preprocess_text(text):
        if not text: return ""
        text = re.sub(r'http\S+|www\S+|https\S+', '', text, flags=re.MULTILINE)
        text = re.sub(r'@\w+', '', text)
        return text.lower().strip()

    @udtf(result_types=[DataTypes.STRING()])
    def split_words(line):
        text_content = line[0] 
        if text_content:
            clean_line = text_content.translate(str.maketrans('', '', string.punctuation))
            for word in clean_line.split():
                if len(word) > 2: yield word

    class IsNotStopWord(ScalarFunction):
        def __init__(self):
            self.stop_words = {"the", "and", "is", "for", "this", "with", "rt", "url", "user", "are", "was"}
        def eval(self, word):
            return word not in self.stop_words

    is_not_stopword = udf(IsNotStopWord(), result_type=DataTypes.BOOLEAN())

    # --- PROCESSING LOGIC ---

    # Flux 1 : Nettoyage et Word Count
    words_table = t_env.from_path('source_table') \
        .select(preprocess_text(col('tweet')).alias('clean_tweet')) \
        .flat_map(split_words).alias('word') \
        .filter(is_not_stopword(col('word'))) \
        .group_by(col('word')) \
        .select(col('word'), col('word').count.alias('number'))

    # Flux 2 : Données brutes (Direct)
    full_data_table = t_env.from_path('source_table')

    # --- EXECUTION VIA STATEMENT SET (Recommandé) ---
    # Cela permet d'exécuter les deux flux dans un SEUL Job Flink
    statement_set = t_env.create_statement_set()
    statement_set.add_insert('sink_wordcount_table', words_table)
    statement_set.add_insert('sink_full_table', full_data_table)

    print("--- Flink Dual-Sink Job Starting (WordCount + Full Data) ---")
    statement_set.execute().wait()

if __name__ == '__main__':
    run_wordcount_pipeline()