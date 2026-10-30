#!/bin/sh
# Lance les scénarios de test du jeu (Linux, sans écran : xvfb). Chaque scénario joue une partie
# en simulant les touches et affiche ce qu'il vérifie ; les captures vont dans $CAPTURES.
#   GODOT=/chemin/vers/godot tests/lancer.sh            (tous les scénarios)
#   GODOT=/chemin/vers/godot tests/lancer.sh dialogues  (un seul)
GODOT=${GODOT:-godot}
export CAPTURES=${CAPTURES:-/tmp/ligne2_captures}
mkdir -p "$CAPTURES"
cd "$(dirname "$0")/.."
for t in ${1:-souris parcours villiers pigalle telephone dialogues chapitre_1 chapitre_2 chapitre_3 menus debogage}; do
	echo "== $t"
	xvfb-run -a -s "-screen 0 1280x960x24" "$GODOT" --path . --rendering-driver opengl3 -s "tests/$t.gd" 2>&1 \
		| grep -vE "ALSA|alsa|audio|V-Sync|vsync|^\s+at:|^$|OpenGL|Godot Engine|status < 0|leaked"
done
