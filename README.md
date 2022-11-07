### harmoniques maree
Créer les fichiers de prédiction de marée à partir des hauteurs d'eau (pour info uniquement, prédictions impropres à la navigation). Il s'agit d'une mise bout à bout des codes de David Flater (https://flaterco.com/xtide/index.html) et Luke Miller (https://github.com/millerlp/Tide_calculator)


Preparer l'instance en suivant le fichier INSTALL.md


Récupérer les hauteurs d'eau en fait un POST sur https://services.data.shom.fr/maregraphie/dl/observations:

```bash
curl -d '{"tideGauges": "94,185,410", "sources": "4", "start": "2000-11-01T00:00:00Z", "end": "2021-12-10T00:00:00Z", "type": "TXT", "name": "nom", "mail": "<monmail@mail.fr>", "isContact": "false"}' -H "Content-Type: application/json" -X POST https://services.data.shom.fr/maregraphie/dl/observations
```

Le fichier des hauteurs d'eau sera créé et un lien de téléchargement sera envoyé à l'adresse mail. 
Changer tideGauges pour y mettre les noms des ports recherchés (voir la liste des ports et leur numéro http://refmar.shom.fr/fr/liste-maregraphes-data.shom.fr)

Récupérer le lien envoyé par mail et aller sur l'instance

```bash
docker image build -t maree .
docker volume create my-vol
docker container run -it --rm --volume my-vol:/data/ maree <lien récupéré par mail>
```

Les résultats sont dans les volumes docker : `/var/lib/docker/voluumes/my-vol/_data/`avec le volume `my-vol` de l'exemple et sur linux.
