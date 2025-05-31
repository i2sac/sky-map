# Sky Map

Sky Map est une application Flutter permettant de visualiser [Décrire brièvement l'objectif principal ici, par exemple : "les objets célestes en temps réel en fonction de l'orientation du téléphone"].

## Fonctionnalités (Exemples)

*   Affichage d'une carte du ciel interactive.
*   Utilisation des capteurs du téléphone (accéléromètre, magnétomètre) pour orienter la vue.
*   Chargement et affichage de données astronomiques.
*   [Ajouter d'autres fonctionnalités clés]

## Captures d'écran (Optionnel mais recommandé)

[Insérer ici des captures d'écran de l'application si vous en avez]

## Prérequis

*   Flutter SDK installé. (Voir [Instructions d'installation de Flutter](https://docs.flutter.dev/get-started/install))
*   Un appareil ou émulateur Android/iOS.

## Installation et Lancement

1.  **Cloner le dépôt :**
2.  **Installer les dépendances :**
3.  **Configurer les variables d'environnement :**
    Créez un fichier `.env` à la racine du projet et ajoutez les variables nécessaires. Basé sur le code, cela pourrait être :
    *Note : Le fichier `main.dart` charge les variables depuis `.env` (`await dotenv.load(fileName: '.env');`). Assurez-vous que ce fichier est présent et correctement configuré.*
4.  **Lancer l'application :**

## Structure du Projet (Aperçu)

*   `lib/`: Contient le code source Dart de l'application.
    *   `main.dart`: Point d'entrée de l'application.
    *   `astras/`: Logique liée aux objets célestes (Bloc, États, Événements, Vues).
    *   `phone/`: Logique liée à la gestion du téléphone (orientation, capteurs) (Bloc, États, Événements, Vues).
    *   `widgets/` ou `common/` (Suggestion) : Pourrait contenir des widgets réutilisables.

## Technologies Utilisées

*   [Flutter](https://flutter.dev/)
*   [Bloc / flutter_bloc](https://bloclibrary.dev/) pour la gestion d'état.
*   [sensors_plus](https://pub.dev/packages/sensors_plus) pour l'accès aux capteurs du téléphone.
*   [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) pour la gestion des variables d'environnement.
*   [flutter_spinkit](https://pub.dev/packages/flutter_spinkit) pour les indicateurs de chargement.
*   [Dart](https://dart.dev/)

## Contribuer (Optionnel)

Les contributions sont les bienvenues ! Si vous souhaitez contribuer, veuillez :

1.  Forker le projet.
2.  Créer une nouvelle branche (`git checkout -b feature/nouvelle-fonctionnalite`).
3.  Faire vos modifications.
4.  Commit vos changements (`git commit -am 'Ajout d'une nouvelle fonctionnalité'`).
5.  Push vers la branche (`git push origin feature/nouvelle-fonctionnalite`).
6.  Ouvrir une Pull Request.

## Licence (Optionnel)

Ce projet est sous licence [Nom de la Licence - par exemple, MIT]. Voir le fichier `LICENSE` pour plus de détails.

---