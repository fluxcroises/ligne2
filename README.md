# Ligne 2

Polar réaliste en vue subjective, style PS1, sur la ligne 2 du métro parisien.
Moteur : Godot 4.3 (rendu « Compatibility », léger et fidèle au style PS1).

## Lancer le projet

1. Installer [Godot 4.3](https://godotengine.org/download) (version standard, pas .NET).
2. Dans le gestionnaire de projets : **Importer** → choisir `project.godot`.
3. **F5** pour lancer.

## Contrôles

| Action | Clavier / souris | Manette |
| --- | --- | --- |
| Se déplacer | ZQSD (AZERTY) / WASD (QWERTY), flèches | Stick gauche |
| Regarder | Souris | Stick droit |
| Courir | Maj | Clic stick gauche |
| Examiner | E ou clic gauche | A / Croix |
| Téléphone (à venir) | Tab | Y / Triangle |
| Jour / nuit | N | Select |
| Libérer la souris | Échap | Start |

## Où en est-on

Étapes 1 à 3 du document de conception :

- rendu 320 × 240 agrandi sans lissage, couleurs 15 bits avec tramage ;
- matériau PSX repris du prototype : sommets accrochés à la grille de l'écran, éclairage par
  sommet (soleil, néons du quai, lanternes), brouillard, jour et nuit ;
- Monceau reconstruit d'après le prototype navigateur, aux mêmes cotes : boulevard de Courcelles,
  bouche Guimard, totem, candélabre, Rotonde et grilles du parc, immeubles, deux escaliers,
  couloir, quai, voûte, deux voies, tunnels, avec les 49 textures tirées des photos ;
- les deux quais sont accessibles : un passage sous les voies relie le quai direction
  Porte Dauphine au quai direction Nation (escalier le long du mur de chaque quai) ;
- rames MF01 sur les deux voies, une toutes les 94 s : arrivée, ouverture des portes, bip de
  fermeture, départ ; on peut monter à bord et la rame emmène le joueur (pour l'instant elle
  revient à Monceau, en attendant les autres stations) ;
- écrans des prochains passages au format PANAM sur chaque quai : prochains passages, heure de jeu
  (départ à 23 h 05), encart d'info trafic modifiable par l'histoire ; on peut les examiner ;
- grondement des rames et bip des portes, fabriqués par le jeu au lancement ;
- vraies collisions (rampes invisibles sous les marches, garde-fous de quai ôtés quand une
  rame est à quai, portes qui laissent passer une fois ouvertes) ;
- joueur en vue subjective, visée d'objets et fenêtre d'examen ; deux indices provisoires
  (badge de Karim sous un siège, porte de service rayée au bout du quai).

Les panneaux « Direction Nation » et « Sortie et direction Pte Dauphine » du passage sont dessinés
par le jeu en attendant une photo.

## Organisation

| Dossier | Contenu |
| --- | --- |
| `scenes/` | `main.tscn` (Monceau), `player.tscn` |
| `scripts/monceau.gd` | construction du lieu, collisions, jour / nuit, noms des lieux |
| `scripts/mf01.gd` | une rame MF01 : caisse, intérieur, portes, collisions |
| `scripts/trafic.gd` | cycle des passages, montée à bord, écrans des prochains passages, sons |
| `scripts/psx_geo.gd`, `psx_builder.gd` | primitives à la manière de three.js, fusion par matériau |
| `scripts/` (autres) | joueur, contrôles, interface, objets à examiner |
| `shaders/` | `psx.gdshader` (matériau), `psx_post.gdshader` (15 bits + tramage) |
| `textures/` | textures 64 px tirées des photos (`textures_monceau_ps1.zip`) |

## Réglages du rendu

- Tremblement des sommets : paramètre global `psx_resolution` (Projet → Paramètres du projet →
  Paramètres globaux des shaders) ; 320 × 240 = discret, 160 × 120 = très PS1.
- Profondeur des couleurs et tramage : `color_levels` et `dither_strength` dans `shaders/psx_post.gdshader`.
- Soleil, ambiance, brouillard et lampes : valeurs de jour et de nuit dans `scripts/monceau.gd`
  (`set_night`, `_apply_fog`), reprises du prototype.
