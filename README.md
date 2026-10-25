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

Étapes 1 et 2 du document de conception :

- rendu 320 × 240 agrandi sans lissage, couleurs 15 bits avec tramage ;
- matériau PSX repris du prototype : sommets accrochés à la grille de l'écran, éclairage par
  sommet (soleil, néons du quai, lanternes), brouillard, jour et nuit ;
- Monceau reconstruit d'après le prototype navigateur, aux mêmes cotes : boulevard de Courcelles,
  bouche Guimard, totem, candélabre, Rotonde et grilles du parc, immeubles, deux escaliers,
  couloir, quai, voûte, deux voies, tunnels, avec les 49 textures tirées des photos ;
- vraies collisions (rampes invisibles sous les marches) ;
- joueur en vue subjective, visée d'objets et fenêtre d'examen ; deux indices provisoires
  (badge de Karim sous un siège, porte de service rayée au bout du quai).

Pas encore repris du prototype : les rames MF01, l'écran des prochains passages et le son (étape 3).
Seul le quai direction Porte Dauphine est accessible, comme dans le prototype ; un garde-fou
invisible longe le bord du quai en attendant les rames.

## Organisation

| Dossier | Contenu |
| --- | --- |
| `scenes/` | `main.tscn` (Monceau), `player.tscn` |
| `scripts/monceau.gd` | construction du lieu, collisions, jour / nuit, noms des lieux |
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
