# Sky Map 🌌

Bienvenue sur **Sky Map**, une application Flutter innovante qui vous permet de visualiser la carte du ciel en temps réel sur plusieurs plateformes ! 🚀

## Table des matières
- [Présentation](#présentation)
- [Fonctionnalités](#fonctionnalités)
- [Architecture du projet](#architecture-du-projet)
- [Installation et configuration](#installation-et-configuration)
- [Utilisation](#utilisation)
- [Contribution](#contribution)
- [Licence](#licence)

## Présentation
Sky Map est une application multiplateforme construite avec Flutter. Elle exploite les capteurs du téléphone pour orienter et afficher en temps réel les astres, avec une interface graphique soignée et des animations fluides. Parfait pour les passionnés d’astronomie et les curieux souhaitant explorer le ciel nocturne ! ✨

## Fonctionnalités
- **Affichage en temps réel** des constellations et planètes
- **Support multi-supports** : Windows, Linux, Web et iOS
- **Interaction tactile** et détection d’orientation grâce aux capteurs
- **Rendu graphique personnalisé** via des widgets Flutter
- **Structure modulaire** facilitant l’ajout de nouvelles fonctionnalités

## Architecture du projet
Le projet est structuré de manière à séparer clairement l’interface utilisateur, la logique métier et la gestion des plateformes :
- **lib/** : Code Flutter principal (UI, gestion d’états avec Bloc, etc.)
- **windows/**, **linux/**, **web/** et **ios/** : Spécificités et configurations pour chaque plateforme
- **astras/** : Composants dédiés au rendu des astres et à leur animation
- **phone/** : Gestion des capteurs et traitement des données d’orientation

## Installation et configuration

### Prérequis
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Un éditeur tel que [Visual Studio Code](https://code.visualstudio.com/)  
- (Optionnel) [Git](https://git-scm.com/) pour gérer le dépôt

### Installation
1. **Clonez le dépôt** :
   ```sh
   git clone https://github.com/votre-utilisateur/sky_map.git
   ```
2. **Installez les dépendances Flutter** :
   ```sh
   flutter pub get
   ```
3. **Configuration spécifique** :
   - Pour les applications de bureau, assurez-vous que les outils de build (CMake, etc.) sont correctement installés.
   - Pour le web, vous pouvez lancer le projet via :
     ```sh
     flutter run -d chrome
     ```

## Utilisation

### Exécution de l’application
- **Mobile** : Connectez un appareil ou utilisez un émulateur puis lancez :
  ```sh
  flutter run
  ```
- **Bureau** (Windows/Linux) : Lancez depuis l’IDE ou via la commande spécifique de votre plateforme (CMake configure et build).
- **Web** : Exécutez avec `flutter run -d chrome`.

### Tests et Debugging
- Utilisez le support intégré des tests unitaires de Flutter dans Visual Studio Code.
- Consultez la sortie du terminal pour les logs et messages de débogage lors de l'exécution.

### Documentation
Afin de bien comprendre la logique derrière le projet ou même le refaire vous-même from scratch, merci de vous rendre dans [documentation.md](documentation.md).

## Contribution
Les contributions sont les bienvenues ! Si vous souhaitez proposer des améliorations ou corriger des bugs :
1. Forkez le dépôt.
2. Créez une branche dédiée à votre fonctionnalité (`git checkout -b feature/ma-fonctionnalité`).
3. Envoyez votre pull request en détaillant les modifications apportées.

N’hésitez pas à consulter [CONTRIBUTING.md](CONTRIBUTING.md) pour plus de détails.

## Licence
Ce projet est sous licence [MIT](LICENSE). Vous êtes libre de l'utiliser et de le modifier selon les termes de cette licence.

---

Profitez de l'exploration du ciel avec Sky Map ! 🌠

*Créé avec ❤️ par [Louis Isaac DIOUF](https://github.com/i2sac)*
