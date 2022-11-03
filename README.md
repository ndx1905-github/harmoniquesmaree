### harmoniques maree
Créer les fichiers de prédiction de marée à partir des hauteurs d'eau - IMPROPRE A LA NAVIGATION


Preparer l'instance en suivant le fichier INSTALL.md


Récupérer les hauteurs d'eau en fait un POST sur https://services.data.shom.fr/maregraphie/dl/observations
en envoyant 
{
  "tideGauges": "94,185,410",
  "sources": "4",
  "start": "2000-11-01T00:00:00Z",
  "end": "2021-12-10T00:00:00Z",
  "type": "TXT",
  "name": "nom",
  "mail": "monmail@mail.fr",
  "isContact": "false"
}
Le fichier des hauteurs d'eau sera créé et un lien de téléchargement sera envoyé à l'adresse mail. 
Changer tideGauges pour y mettre les noms des ports recherchés (voir la liste des ports et leur numéro http://refmar.shom.fr/fr/liste-maregraphes-data.shom.fr )


récupérer le lien envoyé par mail et aller sur l'instance

cd ~/data
wget [lien récupéré par mail]
cd

chmod +x wl2tide.sh (la première fois uniquement)

./wl2tide.sh

les résultats sont dans  ~/data/arduino_libraries/


