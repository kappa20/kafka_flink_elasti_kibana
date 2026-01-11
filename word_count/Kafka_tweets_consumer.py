from kafka import KafkaConsumer
from json import loads
from rich import print
from rich.panel import Panel

# Configuration du consommateur
consumer = KafkaConsumer(
    'my-topic-test',
    bootstrap_servers=['localhost:9092'],
    auto_offset_reset='latest',
    enable_auto_commit=True,
    group_id='debug-consumer-group', # Utiliser un groupe pour ne pas rater de messages
    value_deserializer=lambda x: loads(x.decode('utf-8'))
)

print("[bold green]✔ Consommateur connecté ! En attente de tweets enrichis...[/bold green]\n")

for message in consumer:
    data = message.value
    
    # Affichage structuré pour voir les nouveaux champs du producteur amélioré
    tweet_info = (
        f"[bold cyan]Utilisateur:[/bold cyan] {data.get('username')}\n"
        f"[bold cyan]Localisation:[/bold cyan] {data.get('location')}\n"
        f"[bold yellow]Tweet:[/bold yellow] {data.get('tweet')}\n"
        f"[dim]ID: {data.get('id_str')} | Langue: {data.get('lang')}[/dim]"
    )
    
    print(Panel(tweet_info, title="[bold white]Nouveau Message Kafka[/bold white]", expand=False))