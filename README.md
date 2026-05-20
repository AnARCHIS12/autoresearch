<p align="center">
  <img src="assets/autoresearch-logo.svg" alt="Autoresearch" width="760">
</p>

# Crédit
Autoresearch, projet original de LaurentVoanh.
Merci à toi pour ce projet génial.


# Autoresearch

Autoresearch est une interface locale pour generer, sauvegarder et tester des applications PHP/SQLite avec l'API Mistral.

L'application propose:

- une configuration API depuis l'interface;
- un mode autonome qui genere un projet complet;
- un mode chat;
- une recherche web avec synthese;
- une boucle de correction automatique;
- un lancement simple par double-clic.

## Demarrage rapide

L'application s'ouvre ensuite sur:

```text
http://127.0.0.1:8010/index.php
```

## Installation depuis GitHub

Pour une personne non technique, le plus simple est de telecharger le projet en ZIP.

1. Ouvrir la page GitHub du projet.
2. Cliquer sur le bouton vert **Code**.
3. Cliquer sur **Download ZIP**.
4. Attendre la fin du telechargement.
5. Decompresser le fichier ZIP.
6. Ouvrir le dossier decompresse.
7. Double-cliquer sur le fichier adapte au systeme:

```text
Windows  : demarrer-autoresearch.bat
macOS    : demarrer-autoresearch.command
Linux    : Autoresearch.desktop
```

8. Accepter les autorisations si le systeme en demande.
9. Attendre que le navigateur s'ouvre.
10. Si le navigateur ne s'ouvre pas automatiquement, aller a cette adresse:

```text
http://127.0.0.1:8010/index.php
```

11. Dans l'application, ouvrir **Configuration API** et coller la cle API Mistral.

Il faut telecharger le depot une seule fois. Ensuite, pour relancer Autoresearch, il suffit de refaire le double-clic.

### Linux

Double-cliquer sur:

```text
Autoresearch.desktop
```

ou:

```text
demarrer-autoresearch.sh
```

Le lanceur tente d'utiliser Dockan. Si Dockan manque, il tente de l'installer. Si Dockan ne peut pas fonctionner, il essaie de lancer PHP directement.

### macOS

Double-cliquer sur:

```text
demarrer-autoresearch.command
```

Si PHP manque et que Homebrew est present, le script tente d'installer PHP.

### Windows

Double-cliquer sur:

```text
demarrer-autoresearch.bat
```

Si PHP manque, le script tente une installation avec `winget` ou Chocolatey.

## Configuration API

Au premier lancement, ouvrir le panneau **Configuration API** en haut de l'interface.

Renseigner:

- l'endpoint Mistral, par defaut `https://api.mistral.ai/v1/chat/completions`;
- une ou plusieurs cles API Mistral, une par ligne.

Sans cle API valide, les modes IA ne peuvent pas generer de reponse.

## Commandes utiles

Demarrer avec Dockan:

```sh
dockan compose up
```

Arreter:

```sh
dockan compose down
```

Voir les logs:

```sh
dockan logs autoresearch-web
```

Lancer directement avec PHP:

```sh
php -S 127.0.0.1:8010 -t .
```

## Fichiers generes

Autoresearch utilise ces dossiers:

- `generated_apps/` pour les projets produits par l'IA;
- `logs/` pour les journaux;
- `data/` pour la configuration et la base SQLite locale.

Avec Dockan, ces dossiers sont declares dans le `Dockanfile`:

```dockerfile
VOLUME ["/app/data", "/app/generated_apps", "/app/logs"]
```

Le service reste en `isolation: bubblewrap`.

## Securite

Autoresearch genere et lance du code PHP produit par IA. Il est recommande de l'utiliser en local, dans un environnement de test, et de ne pas l'exposer publiquement sans audit de securite.

Ne partagez pas vos cles API.
