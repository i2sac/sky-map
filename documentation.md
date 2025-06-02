# Documentation du Projet Sky Map Flutter

## 1. Introduction

Ce document détaille la création d'une application Flutter de type "Sky Map" (carte du ciel). L'objectif principal est d'afficher des corps célestes (planètes, Soleil, Lune) en fonction de l'orientation du téléphone de l'utilisateur. Lorsque l'utilisateur pointe son téléphone vers le ciel, l'application montre les astres présents dans cette direction. Les astres sont cliquables, affichant des informations détaillées dans une fenêtre modale.

**Fonctionnalités clés :**

*   Affichage en temps réel des astres basé sur l'orientation du téléphone.
*   Calcul de la position et de la taille apparente des astres.
*   Transformation 3D des coordonnées pour un rendu réaliste.
*   Interactivité : les astres sont cliquables.
*   Affichage d'informations détaillées (nom, altitude, azimut, distance, diamètre) dans un modal.
*   Utilisation du pattern BLoC pour la gestion de l'état.

## 2. Prérequis et Configuration Initiale

### 2.1 Installation de Flutter

Assurez-vous d'avoir Flutter installé sur votre machine. Suivez les instructions officielles sur [flutter.dev](https://flutter.dev/docs/get-started/install).

### 2.2 Création d'un nouveau projet Flutter

```bash
flutter create sky_map
cd sky_map
```

### 2.3 Dépendances (`pubspec.yaml`)

Voici les dépendances clés utilisées dans ce projet. Ajoutez-les à votre fichier `pubspec.yaml` :

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Pour la gestion de l'état (Business Logic Component)
  flutter_bloc: ^9.1.1 
  
  # Pour lire les données des capteurs d'orientation (quaternions, etc.)
  flutter_rotation_sensor: ^0.1.1 
  
  # Pour les opérations sur les vecteurs et matrices 3D
  vector_math: ^2.1.4 
  
  # Pour simplifier la comparaison d'objets (utilisé dans les états BLoC)
  equatable: ^2.0.7 
  
  # Pour effectuer des requêtes HTTP (récupérer les données des astres)
  http: ^1.4.0 
  
  # Pour charger des variables d'environnement (ex: clés API)
  flutter_dotenv: ^5.2.1 
  
  # Pour obtenir la localisation de l'utilisateur (latitude, longitude)
  geolocator: ^14.0.1 
  
  # Icônes Cupertino (facultatif, mais souvent inclus par défaut)
  cupertino_icons: ^1.0.8
  # Pour afficher un indicateur de chargement stylisé
  flutter_spinkit: ^5.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0 # Pour l'analyse statique et le respect des bonnes pratiques
```

Après avoir ajouté les dépendances, exécutez `flutter pub get` dans votre terminal.

## 3. Concepts Clés : Orientation du Téléphone

Pour afficher correctement les astres, l'application doit connaître l'orientation du téléphone dans l'espace.

### 3.1 Capteurs du Téléphone

Les smartphones modernes utilisent une combinaison de capteurs pour déterminer leur orientation :

*   **Accéléromètre** : Mesure l'accélération (y compris la gravité).
*   **Gyroscope** : Mesure la vitesse de rotation.
*   **Magnétomètre** : Mesure le champ magnétique terrestre (comme une boussole).

Les données de ces capteurs sont fusionnées (souvent via des algorithmes comme le filtre de Kalman) pour fournir une estimation stable de l'orientation.

### 3.2 Représentation de l'Orientation

#### Angles d'Euler

Une manière intuitive de représenter l'orientation est d'utiliser les angles d'Euler : lacet (yaw), tangage (pitch), et roulis (roll).
*   **Lacet (Azimut)** : Rotation autour de l'axe Z (vertical).
*   **Tangage (Pitch/Élévation)** : Rotation autour de l'axe Y (transversal).
*   **Roulis (Roll)** : Rotation autour de l'axe X (longitudinal).

*(Suggestion de diagramme : Un repère 3D avec un objet (téléphone) et les trois rotations d'Euler illustrées par des flèches courbes autour de chaque axe.)*

Bien qu'intuitifs, les angles d'Euler souffrent d'un problème appelé "Gimbal Lock" (blocage de cardan) : dans certaines configurations, deux axes de rotation peuvent s'aligner, faisant perdre un degré de liberté. Cela peut entraîner des comportements erratiques dans les calculs de rotation.

#### Quaternions

Les quaternions sont une extension des nombres complexes (avec une partie réelle et trois parties imaginaires : \( q = w + xi + yj + zk \)). Ils sont plus robustes pour représenter les rotations 3D et évitent le problème du Gimbal Lock. Un quaternion unitaire peut représenter n'importe quelle rotation dans l'espace 3D.

*(Suggestion de diagramme : Représentation d'une rotation par un axe \( (x, y, z) \) et un angle \( \theta \), et comment cela se traduit en quaternion \( q = (\cos(\theta/2), \sin(\theta/2)x, \sin(\theta/2)y, \sin(\theta/2)z) \).)*

Le package `flutter_rotation_sensor` fournit directement l'orientation du téléphone sous forme de quaternion.

### 3.3 Système de Coordonnées du Téléphone et `PhoneBloc`

Nous définissons un système de coordonnées local pour le téléphone :
*   **Axe X (Right)** : Pointe vers la droite de l'écran.
*   **Axe Y (Up)** : Pointe vers le haut de l'écran.
*   **Axe Z (Back)** : Pointe vers l'arrière du téléphone (c'est la direction de "visée").

Initialement, dans le repère local du téléphone, ces vecteurs sont :
*   `right_local = (1, 0, 0)`
*   `up_local = (0, 1, 0)`
*   `back_local = (0, 0, -1)` (ou `(0,0,1)` selon la convention, ici `-1` si Z positif sort de l'écran)

Le `PhoneBloc` écoute les événements d'orientation du `flutter_rotation_sensor`. Chaque événement contient un quaternion `q_orientation` qui représente la rotation du téléphone depuis une position de référence (par exemple, téléphone à plat, écran vers le haut, pointant vers le Nord) vers son orientation actuelle.

Pour obtenir les vecteurs des axes du téléphone dans le *système de coordonnées du monde* (par exemple, Est-Nord-Zénith), nous appliquons la rotation du quaternion aux vecteurs locaux :

`v_world = q_orientation * v_local * q_orientation_conjugate`

Ou plus simplement, si la bibliothèque de quaternions fournit une méthode `rotateVector` :

`rotatedRight = q_orientation.rotateVector(right_local)`
`rotatedUp = q_orientation.rotateVector(up_local)`
`rotatedBack = q_orientation.rotateVector(back_local)`

Ces `rotatedRight`, `rotatedUp`, `rotatedBack` sont stockés dans `PhoneRotatedState`.
Le `PhoneBloc` calcule également l'azimut et l'altitude vers lesquels le dos du téléphone pointe, en utilisant `rotatedBack` :
*   Azimut : `atan2(rotatedBack.x, rotatedBack.z)` (si X est Est, Z est Nord, ou ajuster selon la convention).
*   Altitude : `asin(rotatedBack.y)` (si Y est le Zénith).

## 4. Concepts Clés : Données Astronomiques

### 4.1 Modèle de Données (`Astra.dart`)

Chaque corps céleste (`Astra`) est modélisé avec les propriétés essentielles :

```dart
class Astra extends Equatable {
  final String name;        // Nom de l'astre
  final double azimuth;     // Azimut dans le ciel (en degrés)
  final double altitude;    // Altitude au-dessus de l'horizon (en degrés)
  final double distanceInKM;// Distance depuis l'observateur (en km)
  // D'autres propriétés peuvent être ajoutées (diamètre, magnitude, etc.)

  // ... constructeur et props pour Equatable ...
}
```

### 4.2 Récupération des Données (`AstraBloc`)

L'`AstraBloc` est responsable de récupérer les données des astres. Dans une application réelle, cela impliquerait :
1.  Obtenir la position de l'utilisateur (latitude, longitude, altitude) via `geolocator`.
2.  Obtenir la date et l'heure actuelles.
3.  Effectuer une requête HTTP (avec `http`) vers une API astronomique (ex: API de l'IMCCE, ou une API custom comme celle utilisée dans le projet initial) en fournissant la position et l'heure.
    *   Les identifiants API (APP_ID, APP_SECRET) sont stockés de manière sécurisée (par exemple, avec `flutter_dotenv`).
4.  Parser la réponse JSON et créer des objets `Astra`.
5.  Émettre un nouvel `AstraState` contenant la liste des astres.

Pour cet exemple, nous supposons que les données (azimut, altitude, distance) sont déjà calculées pour la position et l'heure de l'utilisateur.

### 4.3 Système de Coordonnées pour les Astres (Référentiel Local de l'Observateur / Monde)

Les positions des astres (azimut, altitude) sont généralement données dans un système de coordonnées horizontal local :
*   **Azimut (Az)** : Angle mesuré depuis un point de référence sur l'horizon (souvent le Nord géographique = 0°, augmentant vers l'Est : Est=90°, Sud=180°, Ouest=270°).
*   **Altitude (Alt)** : Angle mesuré verticalement depuis l'horizon (0°) vers le zénith (+90°). Les objets sous l'horizon ont une altitude négative.
*   **Distance (d)** : Distance de l'observateur à l'astre.

*(Suggestion de diagramme : Un observateur au centre d'un plan horizontal. Le Nord, l'Est, le Sud, l'Ouest indiqués. Un astre dans le ciel avec ses angles d'azimut et d'altitude montrés par rapport à l'observateur et à l'horizon/Nord.)*

Pour les calculs 3D, nous convertissons ces coordonnées sphériques (Az, Alt, d) en coordonnées Cartésiennes 3D (X, Y, Z) dans le référentiel du monde. Une convention courante est :
*   **Axe X positif** : Pointe vers l'Est.
*   **Axe Y positif** : Pointe vers le Nord.
*   **Axe Z positif** : Pointe vers le Zénith (vers le haut).

Les formules de conversion sont (avec Azimut en radians, Altitude en radians) :

Si l'azimut est mesuré depuis le Nord (0° Nord, 90° Est) :
\[ x_{world} = d \cdot \cos(Alt) \cdot \sin(Az) \]
\[ y_{world} = d \cdot \cos(Alt) \cdot \cos(Az) \]
\[ z_{world} = d \cdot \sin(Alt) \]

(Note: Dans le code actuel du painter, `xWorld` utilise `sin(azRad)` et `yWorld` utilise `cos(azRad)`. Si l'azimut 0° est le Nord, alors `sin(0)=0` et `cos(0)=1`. Donc, pour az=0 (Nord), `xWorld=0`, `yWorld=d*cos(Alt)`. Cela signifie que l'axe Y pointe vers le Nord et l'axe X pointe vers l'Est. C'est cohérent.)

## 5. Rendu du Ciel : `MyPainter.dart`

`MyPainter` est une sous-classe de `CustomPainter` responsable du dessin des astres sur un `Canvas`.

### 5.1 `CustomPainter`

`CustomPainter` permet un dessin personnalisé de bas niveau. Il a deux méthodes principales :
*   `paint(Canvas canvas, Size size)` : C'est ici que toute la logique de dessin est implémentée. Le `canvas` offre des méthodes pour dessiner des formes, du texte, des images, etc. `size` est la taille de la zone de dessin.
*   `shouldRepaint(covariant CustomPainter oldDelegate)` : Détermine si le `painter` a besoin d'être redessiné. Il est appelé lorsque le widget `CustomPaint` est reconstruit. Nous redessinons si les données des astres (`astraState`) ou l'orientation du téléphone (`phoneState`) ont changé.

### 5.2 Entrées du `MyPainter`

Notre `MyPainter` prend :
*   `BuildContext context` (généralement non utilisé directement dans `paint` mais peut être utile).
*   `AstraState data` : Contient la liste des `Astra` à dessiner.
*   `PhoneRotatedState phoneState` : Contient les vecteurs d'orientation du téléphone (`rightVector`, `upVector`, `backVector`) dans le référentiel du monde.
*   Des constantes comme `solarSystemPlanets` (diamètres) et `planetColors` pour le style.

### 5.3 Transformation de Vue (Monde vers Coordonnées Caméra/Téléphone)

Nous traitons le téléphone comme une caméra. La direction de "visée" est l'arrière du téléphone (le long de son axe Z, `backVector`).
Les étapes pour afficher un astre :

1.  **Position de l'Astre dans le Monde** :
    Nous avons `(x_world, y_world, z_world)` pour chaque astre (calculé à partir de son Az/Alt/dist). C'est `pWorld = vm.Vector3(xWorld, yWorld, zWorld)`.

2.  **Construction de la Matrice de Vue (`viewMatrix`)** :
    Cette matrice transforme les coordonnées du référentiel du monde vers le référentiel de la caméra (téléphone).
    Les vecteurs `phoneState.rightVector`, `phoneState.upVector`, `phoneState.backVector` sont les axes X, Y, Z du téléphone *exprimés dans les coordonnées du monde*.
    
    Si \( R_x, R_y, R_z \) sont ces vecteurs (colonnes) formant la matrice de rotation qui transforme du téléphone vers le monde, alors la matrice qui transforme du monde vers le téléphone est \( (R_x | R_y | R_z)^T \). Ses lignes sont donc \( R_x, R_y, R_z \).

    ```dart
    final vm.Vector3 phoneX_inWorld = vm.Vector3(phoneState.rightVector.x, ...);
    final vm.Vector3 phoneY_inWorld = vm.Vector3(phoneState.upVector.x, ...);
    final vm.Vector3 phoneZ_inWorld = vm.Vector3(phoneState.backVector.x, ...); // C'est l'axe de visée

    final vm.Matrix3 viewMatrix = vm.Matrix3.zero();
    viewMatrix.setRow(0, phoneX_inWorld); // L'axe X du téléphone devient la 1ère ligne
    viewMatrix.setRow(1, phoneY_inWorld); // L'axe Y du téléphone devient la 2ème ligne
    viewMatrix.setRow(2, phoneZ_inWorld); // L'axe Z du téléphone (arrière) devient la 3ème ligne
    ```

3.  **Transformation des Coordonnées de l'Astre** :
    On applique la `viewMatrix` au point `pWorld` de l'astre :
    `vm.Vector3 pCamera = viewMatrix.transform(pWorld);`

    Maintenant, `pCamera` contient les coordonnées `(x_cam, y_cam, z_cam)` de l'astre par rapport au téléphone :
    *   `pCamera.x` : Coordonnée le long de l'axe "droite" du téléphone.
    *   `pCamera.y` : Coordonnée le long de l'axe "haut" du téléphone.
    *   `pCamera.z` : Coordonnée le long de l'axe "arrière" du téléphone.

### 5.4 Projection Perspective

1.  **Culling (Élimination des objets non visibles)** :
    Si `pCamera.z <= 0`, l'astre est derrière la "caméra" (ou sur son plan), donc il n'est pas visible. On passe au suivant.

2.  **Calcul des Angles de Vue** :
    Nous calculons les angles horizontal et vertical de l'astre par rapport à l'axe de visée de la caméra (l'axe Z de la caméra, qui est `pCamera.z`).
    \[ \text{angleHorizontalRad} = \text{atan2}(pCamera.x, pCamera.z) \]
    \[ \text{angleVerticalRad} = \text{atan2}(pCamera.y, pCamera.z) \]
    `atan2(y,x)` est utilisé car il gère correctement les signes pour tous les quadrants, donnant un angle entre \(-\pi\) et \(+\pi\).

    *(Suggestion de diagramme : Vue de dessus de la caméra. L'axe Z de la caméra pointe vers l'avant. Un point (x_cam, z_cam) dans le plan XZ de la caméra. L'angleHorizontal est l'angle entre l'axe Z et la ligne allant de l'origine de la caméra au point projeté sur le plan XZ. Similaire pour l'angleVertical dans le plan YZ.)*

3.  **Champ de Vision (FOV - Field of View)** :
    Nous définissons un champ de vision, par exemple `fovDegrees = 90.0`. Seuls les objets dans ce cône de vision sont affichés.
    Si `abs(angleHorizontalDeg) > fovDegrees / 2` ou `abs(angleVerticalDeg) > fovDegrees / 2`, l'astre est hors champ.

4.  **Conversion en Coordonnées d'Écran** :
    Le centre de l'écran est `(ox = size.width / 2, oy = size.height / 2)`.
    Les échelles pour convertir les degrés d'angle en pixels :
    `scaleDegToPixX = size.width / fovDegrees;`
    `scaleDegToPixY = size.height / fovDegrees;`

    Coordonnées sur l'écran :
    `x_screen = ox + angleHorizontalDeg * scaleDegToPixX;`
    `y_screen = oy - angleVerticalDeg * scaleDegToPixY;` (le `-` pour `y_screen` car l'axe Y du canvas pointe vers le bas, alors que l'angle vertical positif est vers le haut).

### 5.5 Calcul de la Taille Apparente

Le diamètre angulaire d'un objet dépend de son diamètre réel et de sa distance.
`planetDiameterKm = solarSystemPlanets[astra.name]`
`distanceToPlanet = pCamera.length` (distance réelle de la caméra à la planète)

L'angle apparent (diamètre angulaire) en radians est :
\[ \text{apparentAngleRad} = 2 \cdot \text{atan}\left(\frac{\text{planetDiameterKm} / 2}{\text{distanceToPlanet}}\right) \]

Convertir en degrés et multiplier par un facteur d'échelle (`scale` dans le painter, ici `scaleFactorForApparentSize`) pour une meilleure visibilité sur l'écran :
`apparentSizeOnScreen = (apparentAngleRad * 180 / pi) * scaleFactorForApparentSize;`
La taille est ensuite limitée (clampée) pour éviter des points trop petits ou trop gros.

### 5.6 Dessin

Finalement, on dessine l'astre :
`canvas.drawCircle(Offset(x_screen, y_screen), apparentSizeOnScreen, paint);`
Où `paint` définit la couleur (depuis `planetColors`) et d'éventuels effets comme le flou.

## 6. Interactivité : Rendre les Planètes Cliquables (`BlackCanvas.dart`)

Le widget `BlackCanvas` contient le `CustomPaint` qui utilise `MyPainter`. Pour rendre les planètes cliquables :

1.  **`GestureDetector`** :
    Le `CustomPaint` est enveloppé dans un `GestureDetector`.
    ```dart
    GestureDetector(
      onTapUp: (details) => _handleTap(context, details, astraState, phoneState, screenSize),
      child: CustomPaint(...),
    );
    ```
    `onTapUp` nous donne `TapUpDetails`, qui contient `details.localPosition` (les coordonnées du clic dans le repère du `GestureDetector`).

2.  **Fonction `_handleTap`** :
    Cette fonction est appelée à chaque clic. Elle a besoin de `astraState`, `phoneState`, et la taille de l'écran (`screenSize`).
    *   **Répéter la Projection** : Pour chaque astre visible dans `astraState`:
        *   Recalculer sa position projetée sur l'écran (`projectedX`, `projectedY`) et sa taille apparente (`apparentSize`) en utilisant exactement la même logique de transformation et de projection que dans `MyPainter`.
    *   **Hit Testing (Détection de Cible)** :
        Pour chaque astre projeté, calculer la distance entre le point de clic (`tapPosition`) et le centre de l'astre projeté :
        `distanceToAstraCenter = (Offset(projectedX, projectedY) - tapPosition).distance;`
        Si `distanceToAstraCenter <= apparentSize`, alors l'utilisateur a cliqué sur cet astre.
        On stocke l'`Astra` touché et on arrête la boucle (pour ne sélectionner que l'astre le plus "en avant" en cas de superposition).

3.  **Afficher le Modal** :
    Si un `tappedAstra` est trouvé (non nul), on appelle `showDialog` pour afficher le `PlanetInfoModal`.

    ```dart
    if (tappedAstra != null) {
      showDialog(
        context: context,
        builder: (_) => PlanetInfoModal(
          astra: tappedAstra!, // '!' car on a vérifié non-nullité
          planetColors: BlackCanvas.planetColors, // Utilise les maps statiques
          solarSystemPlanets: BlackCanvas.solarSystemPlanets,
        ),
      );
    }
    ```

    *Note sur la duplication* : Les maps `solarSystemPlanets`, `planetColors` et `scaleFactorForApparentSize` sont actuellement dupliquées entre `MyPainter` et `BlackCanvas`. Pour une meilleure organisation, elles pourraient être placées dans un fichier de constantes ou un service accessible.

## 7. Affichage des Informations : `PlanetInfoModal.dart`

C'est un `StatelessWidget` simple qui affiche les informations d'un astre.

*   **Paramètres** : Il prend en entrée l'`Astra` sélectionné, ainsi que les maps `planetColors` et `solarSystemPlanets` pour récupérer la couleur et le diamètre.
*   **Structure** : Utilise un `AlertDialog` pour un style de modal standard.
    *   `backgroundColor` et `shape` pour personnaliser l'apparence.
    *   `title` : Affiche le nom de l'astre.
    *   `content` : Utilise `SingleChildScrollView` et `Column` pour lister les informations.
        *   Un `CircleAvatar` affiche un cercle avec la couleur de l'astre.
        *   Une méthode privée `_buildInfoRow(String label, String value)` est utilisée pour formater chaque ligne d'information de manière cohérente (Label à gauche, Valeur à droite).
    *   `actions` : Contient un bouton "Fermer" (`TextButton`) qui appelle `Navigator.of(context).pop()` pour fermer le modal.

Le modal affiche des informations comme l'altitude, l'azimut, la distance, et le diamètre (s'il est disponible).

## 8. Gestion de l'État avec `flutter_bloc` (Vue d'ensemble)

`flutter_bloc` aide à séparer la logique métier de la présentation.

*(Suggestion de diagramme : Un flux simple : UI déclenche Événement -> Événement envoyé au Bloc -> Bloc traite l'événement, interagit si besoin avec des services (API, capteurs), et émet un nouvel État -> UI écoute les changements d'État via BlocBuilder et se met à jour.)*

*   **Événements (`..._event.dart`)** : Représentent des intentions utilisateur ou des notifications système.
    *   `AppOpened` (dans `AstraEvent`) : Déclenché au démarrage pour charger les données des astres.
    *   `PhoneOrientationEvent` (dans `PhoneEvent`) : Déclenché lorsque le capteur d'orientation envoie de nouvelles données. Il encapsule `OrientationEvent` du package `flutter_rotation_sensor`.

*   **États (`..._state.dart`)** : Représentent l'état de l'interface utilisateur à un instant T. Ils sont immuables.
    *   `AstraState` : Contient la liste des `Astra` (`List<Astra> astras`).
    *   `PhoneRotatedState` : Contient les vecteurs d'orientation du téléphone (`backVector`, `rightVector`, `upVector`) et l'azimut/altitude calculés du pointage du téléphone.
    *   Les états étendent `Equatable` pour faciliter la comparaison et éviter des reconstructions inutiles de l'UI.

*   **Blocs (`..._bloc.dart`)** : Contiennent la logique métier.
    *   `AstraBloc(Bloc<AstraEvent, AstraState>)`:
        *   Réagit à `AppOpened` : appelle la méthode `_fetchData` pour récupérer les données des astres et émet un nouvel `AstraState`.
    *   `PhoneBloc(Bloc<PhoneEvent, PhoneRotatedState>)`:
        *   Réagit à `PhoneOrientationEvent` :
            *   Récupère le quaternion de l'événement.
            *   Calcule les nouveaux `rotatedRight`, `rotatedUp`, `rotatedBack` en appliquant la rotation du quaternion aux vecteurs de base du téléphone.
            *   Calcule l'azimut et l'altitude du pointage du téléphone.
            *   Émet un nouveau `PhoneRotatedState`.
        *   Inclut une logique pour éviter des mises à jour trop fréquentes si l'orientation n'a pas significativement changé.

*   **`BlocBuilder`** : Un widget qui écoute les changements d'état d'un Bloc spécifique et reconstruit sa portion d'UI en conséquence.
    *   Dans `BlackCanvas`, deux `BlocBuilder` imbriqués fournissent `phoneState` et `astraState` au `GestureDetector` et au `MyPainter`.

## 9. Assemblage (`main.dart`, Structure UI)

*   **`main()`** : Initialise les variables d'environnement (`dotenv.load()`) et lance l'application (`runApp(const MyApp())`).
*   **`MyApp` (StatelessWidget)** : Configure `MaterialApp`.
    *   **`MultiBlocProvider`** : Rend les Blocs (`AstraBloc`, `PhoneBloc`) accessibles à tous les widgets descendants dans l'arbre. C'est ici que les instances des Blocs sont créées.
        ```dart
        MultiBlocProvider(
          providers: [
            BlocProvider<AstraBloc>(
              create: (context) => AstraBloc(data: [])..add(AppOpened()),
            ),
            BlocProvider<PhoneBloc>(create: (context) => PhoneBloc()),
          ],
          child: const MyHomePage(),
        )
        ```
*   **`MyHomePage` (StatefulWidget)** :
    *   **`initState()`** :
        *   Configure la fréquence d'échantillonnage du capteur (`RotationSensor.samplingPeriod`).
        *   S'abonne au flux d'orientation (`RotationSensor.orientationStream.listen(...)`).
        *   À chaque nouvel `OrientationEvent` du capteur, si les données des astres sont chargées, il ajoute un `PhoneOrientationEvent` au `PhoneBloc`.
    *   **`dispose()`** : Annule l'abonnement au flux du capteur pour éviter les fuites de mémoire.
    *   **`build()`** :
        *   Utilise un `Scaffold` comme structure de base.
        *   Un `BlocBuilder<AstraBloc, AstraState>` pour vérifier si les données des astres sont chargées.
        *   Un `Stack` est utilisé pour superposer :
            *   Le `BlackCanvas` (qui dessine le ciel).
            *   Un conteneur de chargement (avec un `SpinKitFadingCircle`) si les données des astres ne sont pas encore chargées.

## 10. Conclusion et Améliorations Possibles

Ce projet constitue une base solide pour une application de carte du ciel. Les concepts de transformation 3D, de gestion des capteurs et d'interaction utilisateur sont mis en œuvre.

**Améliorations possibles :**

*   **Précision Astronomique** : Utiliser des modèles de calcul astronomique plus précis (éphémérides) au lieu de dépendre uniquement d'une API pour Az/Alt.
*   **Affichage des Étoiles et Constellations** : Ajouter des catalogues d'étoiles et dessiner les constellations.
*   **Textures pour les Planètes** : Remplacer les cercles colorés par des images/textures des planètes.
*   **Recherche et Sélection Manuelle** : Permettre à l'utilisateur de rechercher un astre et de le pointer sur la carte.
*   **Réalité Augmentée** : Superposer la carte du ciel à la vue de la caméra du téléphone.
*   **Paramètres Utilisateur** : Choix du lieu, notifications pour événements astronomiques.
*   **Optimisations** :
    *   Centraliser les constantes (couleurs, diamètres).
    *   Optimiser la détection de clics si le nombre d'objets devient très grand.
*   **Interface Utilisateur (UI/UX)** : Améliorer le design du modal, ajouter des animations, un tutoriel, etc.

J'espère que cette documentation vous sera utile ! 