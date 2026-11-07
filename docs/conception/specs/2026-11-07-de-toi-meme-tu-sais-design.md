# « De toi-même tu sais » — fiche du jeu

Date : 7 novembre 2026 · Auteur : LAFLEURSTUDIO · Statut : à relire par Johnny

## 1. L'idée

Un jeu d'ambiance pour soirées entre potes. On joue **en duo** devant les autres.
Un mot du quotidien s'affiche ; celui qui le voit doit le faire deviner à son partenaire
**uniquement en évoquant des souvenirs vécus ensemble** (« tu te rappelles hier soir, j'étais
pas bien, tu m'as dit de prendre un truc… » → « Doliprane ! »). Les spectateurs ne comprennent
rien, le duo, lui, « de lui-même il sait ».

L'appli affiche les mots (on peut passer un mot trop dur), rappelle les règles dans un petit carré,
permet de créer ses propres catégories, et note sur la console les mots affichés pour des
statistiques futures. Le jeu lui-même se joue à l'oral, entre joueurs.

**Le jeu est réussi si** on lance une partie en quelques secondes, en soirée, sans rien lire
ni rien expliquer.

## 2. Plateformes

| Plateforme | Quand | Comment |
|---|---|---|
| Anbernic RG SP (ROCKNIX, 720×480) | v1 | Port PortMaster dans `/storage/roms/ports` |
| Web (ordi + navigateur de téléphone) | v1 | Version navigateur du même jeu, hébergée sur lafleurstudio.ch (adresse exacte à choisir, mise en ligne seulement avec l'accord de Johnny) |
| Applis iPhone / Android | plus tard, hors v1 | À étudier le moment venu |

Outil : **LÖVE 11.5** (Lua), le même que LAFLEURMUSIC. Un seul code pour la console et le web.
Le jeu marche **sans internet**. Il est **en français uniquement**.

## 3. Les mots

### 3.1 Les listes

Fichiers texte dans `words/`, encodés en UTF-8, **un mot ou une expression par ligne** :

| Fichier | Contenu | Taille visée |
|---|---|---|
| `melange.txt` | Mots du quotidien, tous thèmes | environ 500 |
| `maison.txt` | Maison | environ 60 |
| `bouffe.txt` | Nourriture, boissons | environ 60 |
| `transport.txt` | Transports, déplacements | environ 60 |
| `boulot-ecole.txt` | Travail, école | environ 60 |
| `sante.txt` | Santé, corps, pharmacie | environ 60 |
| `soiree.txt` | Soirée, un peu osé (gueule de bois, capote, suçon…) | environ 60 |

- Les lignes vides et les lignes qui commencent par `#` sont ignorées.
- Les espaces en début et fin de ligne sont retirés.
- Un mot présent en double dans un même fichier n'est gardé qu'une fois.
- Une catégorie dont le fichier est vide ou absent n'apparaît pas dans l'accueil.
- Johnny peut modifier ces fichiers lui-même, sans toucher au code.
- Les listes de départ sont relues et validées par Johnny avant la v1.

### 3.2 La pioche

- **Sans catégorie cochée** : les mots viennent tous de `melange.txt`.
- **Avec une ou plusieurs catégories cochées** : un **dé caché** choisit 2, 3 ou 4 (chances
  égales). Le mot numéro 2, 3 ou 4 qui suit vient des catégories cochées ; les autres viennent de
  `melange.txt`. Puis le dé est relancé.
  Exemple : dé = 3 → normal, normal, **catégorie** ; dé = 2 → normal, **catégorie** ; …
- Avec plusieurs catégories cochées, leurs mots forment **un seul paquet commun**.
- Chaque paquet (`melange` d'un côté, catégories cochées de l'autre) est **mélangé comme un jeu de
  cartes** : un mot ne revient pas tant que tout son paquet n'est pas passé. Quand le paquet est
  vide, il est remélangé, en évitant que le premier mot soit celui qui vient de sortir.
- Un mot présent dans deux listes (par exemple `melange` et `soiree`) peut sortir de chaque paquet.
- Changer les catégories cochées recrée les paquets.
- **Mémoire des mots déjà vus (ajout du 7.11.2026)** : le jeu retient, d'une partie et d'un lancement
  à l'autre, les mots déjà affichés (fichier `vus.txt` dans le dossier de sauvegarde ; stockage du
  navigateur sur le web). Quand une pile est (re)construite, les mots pas encore vus passent d'abord,
  mélangés ; les mots déjà vus ne reviennent qu'une fois tous les autres passés. Quand tous les mots
  d'une pile ont été vus, sa mémoire repart de zéro. Fichier absent ou abîmé : on repart de zéro.


## 4. Les écrans

Maquette validée par Johnny le 7.11.2026. Style LAFLEURSTUDIO : fond `#1a1a1a`, rose `#F26EF2`,
texte clair. **Toutes les polices viennent du catalogue LAFLEURSTUDIO**
(https://jonlekern.github.io/Fonts/), aucune autre. **Les mots** sont en **Clebard Tall** (graisse
800, licence GUST, chasse à 140 % : un mot long passe sur deux lignes ou rétrécit). Le reste
(titre, catégories, boutons) est en **Calebard** (licence OFL). Les fichiers de licence sont
livrés avec le jeu. La fleur et le
logo ne figurent pas dans la v1 de la maquette ; on pourra les ajouter plus tard, après nouvelle
maquette.

1. **Accueil**
   - Titre « De toi-même » et, en rose, « tu sais ».
   - Les 6 catégories en pastilles : rose = cochée, contour gris = non cochée.
   - Chrono : aucun · 30 s · 60 s · 90 s (choix actif en rose).
   - Bouton **Jouer**.
   - Un **« ? »** rose en haut à droite : ouvre le carré des règles.
   - Les catégories de Johnny (« Mes catégories ») s'affichent après les 6 de base, en pastilles
     identiques.
   - Rappel en bas à gauche : « SELECT : règles · Y : mes catégories » (console) ; sur écran
     tactile, un petit bouton « Mes catégories ».
2. **Jeu**
   - Le mot en très grand, centré. Un mot trop long passe sur deux lignes ou réduit sa taille,
     sans jamais déborder de l'écran.
   - En haut à gauche, en petit : la catégorie du mot (« Soirée »…), rien pour un mot de `melange`.
   - En haut à droite, en rose : le temps restant, seulement si le chrono est actif.
   - En bas, en petit : « A : suivant · X : passer · clapet : suivant ». Sur écran tactile, un
     vrai bouton **Passer** à toucher à la place.
3. **Temps écoulé** (seulement avec chrono)
   - « Temps écoulé » en rose, bouton **Rejouer** (relance une manche avec les mêmes réglages).
4. **Carré des règles** (par-dessus l'accueil), maquette validée le 7.11.2026 :
   titre « Comment on joue » en rose, puis :
   1. Jouez à deux. L'autre équipe écoute et peut aussi deviner.
   2. Un mot s'affiche : un seul le voit.
   3. Fais-le deviner **avec un souvenir** que vous avez vécu ensemble.
   4. Trouvé : mot suivant. Trop dur : passe.
   Se ferme avec B, ou en touchant à côté. Seulement dans ce jeu.
5. **Mes catégories** (maquette validée le 7.11.2026), voir §8.

Pas de score à l'écran, pas de compteur, pas de liste des mots joués.

## 5. Les commandes

| Action | Console RG SP | Ordi | Téléphone |
|---|---|---|---|
| Se déplacer dans l'accueil | croix | flèches / souris | toucher |
| Cocher / choisir | A | Entrée / clic | toucher |
| Mot suivant | A, ou fermer puis rouvrir le clapet | Espace / Entrée / clic | toucher l'écran |
| Passer le mot | X | touche P / bouton Passer | bouton Passer |
| Règles (accueil) | SELECT | touche ? ou clic sur « ? » | toucher « ? » |
| Mes catégories (accueil) | Y | touche C / bouton | bouton « Mes catégories » |
| Retour à l'accueil | B | Échap | bouton retour en haut à gauche |
| Rejouer (temps écoulé) | A | Entrée / clic | toucher |
| Quitter le jeu | raccourci ROCKNIX habituel | fermer l'onglet | fermer l'onglet |

### 5.1 Le clapet (console)

- Vérifié le 7.11.2026 sur la console de Johnny, en lecture seule : le clapet est un interrupteur
  `SW_LID` (aujourd'hui `/dev/input/event3`) et la mise en veille au clapet est déjà coupée par le
  fichier `80-lafleur-clapet.conf` de LAFLEURMUSIC (`HandleLidSwitch=ignore`).
- Le jeu trouve l'interrupteur dans `/proc/bus/input/devices` (même méthode que le gardien du
  clapet de LAFLEURMUSIC) et le lit dans un fil à part.
- **Fermer puis rouvrir** pendant l'écran Jeu = mot suivant. Fermer seul ne fait rien.
- Pendant que le clapet est fermé, le chrono continue.
- Si l'interrupteur est introuvable ou illisible, le jeu continue normalement, sans clapet
  (bouton A seulement), et l'écrit dans son journal.
- Sur le web, rien de tout ça : le code du clapet n'est pas chargé.

## 6. Le chrono (option)

- Réglé dans l'accueil : aucun (par défaut), 30, 60 ou 90 secondes.
- Le chrono compte **par mot** : il démarre au premier mot et repart de zéro à chaque nouveau mot
  (suivant, passer ou clapet). À zéro : écran « Temps écoulé » ; « Rejouer » affiche un nouveau
  mot avec un chrono neuf (la pioche continue).
- Aucun son en v1.

## 7. Mémoire des réglages

- Le jeu retient les catégories cochées et le chrono choisi, dans un petit fichier de réglages
  (dossier de sauvegarde LÖVE ; stockage du navigateur pour le web).
- Si le fichier est absent ou abîmé : réglages par défaut (aucune catégorie, pas de chrono).

## 8. Mes catégories (éditeur dans le jeu)

- Ouvert depuis l'accueil (Y sur la console, bouton sur écran tactile, touche C au clavier).
- **Liste** : les catégories de Johnny avec leur nombre de mots, et « + Nouvelle catégorie ».
  A : ouvrir · Y : supprimer · B : retour.
- **Une catégorie** : « + Ajouter un mot », puis ses mots. A : modifier · Y : supprimer · B : retour.
- **Saisie** : sur la console, clavier AZERTY à l'écran parcouru à la croix (lettres a–z, é, è, à,
  ç, Maj, espace, effacer, OK ; A : lettre · X : effacer · START : OK). Sur ordi et téléphone, le
  vrai clavier de l'appareil (saisie de texte LÖVE).
- Un nom de catégorie : 1 à 24 caractères, unique (sans tenir compte des majuscules), différent
  des 6 catégories de base. Un mot : 1 à 40 caractères ; espaces en trop retirés ; un mot déjà
  présent dans la catégorie n'est pas ajouté deux fois.
- Supprimer une catégorie ou un mot demande « Sûr ? » (A : oui · B : non).
- Les 6 catégories de base ne sont pas modifiables.
- Les catégories de Johnny se cochent dans l'accueil et passent par le même dé caché.
  Une catégorie sans mot n'est pas cochable.
- Elles sont enregistrées dans le dossier de sauvegarde du jeu (`mes-mots.txt`), sur l'appareil où
  elles ont été créées ; pas de partage automatique entre appareils.
- Si le fichier est abîmé, les lignes illisibles sont ignorées, le reste est gardé.

## 9. Statistiques (console)

- Sur la console seulement, chaque mot affiché est noté à la fin de son passage, une ligne par mot,
  dans `stats.txt` (dossier de sauvegarde du jeu, sur la carte `games-roms`, récupérable par le
  Wi-Fi) :
  `2026-11-08 23:14 · Soirée · Suçon · passé` (ou `suivant`).
  Catégorie `Mélange` pour un mot de `melange`.
- Le résultat est `suivant` (A, toucher, clapet), `passé` (X) ; un mot encore à l'écran quand le
  chrono tombe à zéro ou qu'on revient à l'accueil est noté `fin`.
- Rien n'est envoyé sur internet. Le fichier n'est jamais effacé par le jeu.
- Les statistiques elles-mêmes (calculs, graphiques) sont faites plus tard, à part, sur le Mac.

## 10. Organisation du code

```
de-toi-meme-tu-sais/
├── main.lua            point d'entrée LÖVE : relie les écrans
├── conf.lua            fenêtre 720×480, titre
├── src/
│   ├── words.lua       lit et nettoie les listes (pur, testable)
│   ├── deck.lua        paquets mélangés + dé caché (pur, testable, hasard injectable)
│   ├── settings.lua    lecture / écriture des réglages
│   ├── input.lua       traduit boutons, clavier, toucher → actions (« suivant », « retour »…)
│   ├── lid.lua         clapet de la console (fil de lecture evdev)
│   ├── custom.lua      catégories de Johnny : lecture, écriture, règles de noms (pur, testable)
│   ├── stats.lua       lignes du journal des mots (pur, testable)
│   ├── keyboard.lua    clavier à l'écran : grille et déplacements (pur, testable)
│   └── screens/        home, play, timeup, rules, mycats, catwords, typing, confirm
├── words/              les 7 listes .txt
├── assets/fonts/       Clebard Tall, Calebard et leurs licences
├── tests/              tests des modules purs
├── port/               lanceur PortMaster pour la console
└── web/                fabrication de la version navigateur
```

Chaque pièce a un seul rôle. `words` et `deck` ne dépendent ni de l'écran ni du clavier, ce qui
permet de les tester seuls.

## 11. Vérifications

- **Tests automatiques** (`words`, `deck`, `settings`, `custom`, `stats`, `keyboard`), lancés sur le Mac :
  - noms de catégories invalides refusés, mots en double non ajoutés, fichier abîmé lu en partie ;
  - ligne de statistique au bon format pour `suivant`, `passé` et `fin` ;
  - le curseur du clavier ne sort jamais de la grille ;
  - le dé ne donne que 2, 3 ou 4, et chaque valeur sort à peu près aussi souvent ;
  - sans catégorie, tous les mots viennent de `melange` ;
  - avec catégorie, un mot de catégorie arrive toujours après 2 à 4 mots ;
  - aucun mot ne revient avant la fin de son paquet, ni deux fois de suite au remélange ;
  - lignes vides, `#`, espaces et doublons bien nettoyés ; catégorie vide écartée ;
  - réglages abîmés → réglages par défaut.
- **Sur le Mac** : chaque écran vérifié à la main, en 720×480.
- **Sur la console** : installation seulement avec l'accord de Johnny, en suivant les règles
  d'écriture sur les partages Samba (copie de sauvegarde, `cat >`, vérification `cmp`, pas de
  `sed -i` ni `rsync`). À chaque essai, on précise s'il faut redémarrer. À tester : boutons,
  clapet, et clapet avec LAFLEURMUSIC en arrière-plan.
- **Web** : chargement et jeu au doigt sur iPhone et Android avant toute mise en ligne.

## 12. Dépôt et publication

- Dépôt git local ; messages de commit et README en anglais ; aucune mention d'IA.
- Rien sur GitHub (compte Jonlekern) ni sur lafleurstudio.ch sans l'accord de Johnny.

## 13. Hors v1

Score, équipes, sons, fleur ou logo (en attente d'une maquette), modifier les 6 catégories de base,
partager ses catégories entre appareils, statistiques sur le web, calcul et affichage des
statistiques, autres langues, applis iPhone et Android.

## 14. Ajouts du 7.11.2026 (validés par Johnny)

### 14.1 Nom et logo
- Le jeu s'appelle **« Toi-même tu sais »** (et non « De toi-même tu sais ») : titre de l'accueil
  (« Toi-même » sur la ligne 1, « tu sais » en rose sur la ligne 2), fenêtre, page web, lanceur
  console (`Toi-meme tu sais.sh`), README.
- Logo validé : carré arrondi `#1a1a1a`, « Toi-même » en blanc (Calebard), bulle de dialogue rose
  `#F26EF2` avec « tu sais » en `#1a1a1a` (Clebard Tall), sans fleur. Fichiers `assets/logo/`
  (1024, 512, 192, 180, 32 px). Utilisé comme icône de la page web (favicon + icône d'écran d'accueil),
  icône de la fenêtre LÖVE et en haut du README.

### 14.2 Format téléphone (web)
- Quand la fenêtre est plus haute que large (téléphone tenu debout), le jeu passe en **mise en page
  debout** : écran logique 480×800 au lieu de 720×480. Sinon (console, ordi, téléphone couché) rien
  ne change.
- Maquette validée :
  - **Accueil** : « ? » en haut à droite ; titre sur deux lignes ; pastilles des catégories qui
    passent à la ligne ; « Chrono » puis « aucun · 30 · 60 · 90 s » ; en bas deux boutons pleine
    largeur : « Mes catégories » (contour gris) puis « Jouer » (rose).
  - **Jeu** : « ‹ Retour » en haut à gauche, chrono en haut à droite, catégorie centrée en dessous ;
    le mot en très grand au centre (jusqu'à 3 lignes) ; « Touche : mot suivant » en gris ; gros
    bouton « Passer » rose en bas.
  - **Règles** : le carré prend presque toute la largeur ; « Touche pour fermer ».
  - Les autres écrans (temps écoulé, mes catégories, mots, saisie, confirmation) reprennent leur
    mise en page avec la largeur 480 (listes et boutons pleine largeur).
- Passer d'un format à l'autre (tourner le téléphone) refait la mise en page sans perdre la partie.

### 14.3 Gestes (version web seulement, validés le 7.11.2026)
- Sur l'écran Jeu, hors console :
  - **Glisser à droite** : mot suivant (comme A / toucher). **Glisser à gauche** : revenir au mot
    précédent (historique de la manche ; rien s'il n'y en a pas). Le chrono repart du début dans les
    deux cas. Le toucher simple et le bouton « Passer » restent.
  - **Appui long** (~0,5 s sans bouger) : un **post-it rose** (`#F26EF2`, texte « Toi-même tu sais » en
    `#1a1a1a`, bande de scotch translucide en haut, légère rotation, ombre) tombe sur le mot et le
    cache, avec une petite animation de chute.
  - **Décoller** : on pose le doigt sur le post-it et on glisse vers le haut. **Le coin du côté où le
    doigt a commencé (gauche ou droite) se soulève** et se replie en suivant le doigt ; au-delà d'un
    seuil, le post-it se décolle complètement et s'envole vers le haut ; sinon il se recolle.
  - Tant qu'il est collé, le post-it bloque le glisser gauche/droite et le toucher « suivant » ; le
    chrono continue.
  - Réglages retenus : glisser = au moins 60 px surtout à l'horizontale en moins de 0,6 s ; appui
    long = 0,5 s sans bouger de plus de 12 px ; le post-it se décolle au-delà de 35 % de sa hauteur
    ou sur un coup rapide vers le haut. Tant qu'il est collé, « Passer » est bloqué aussi
    (rien ne change le mot) ; « ‹ Retour » marche. Quitter l'écran ou la fin du chrono l'enlève.
  - Revenir au mot précédent ne note rien dans les statistiques ; un mot revu est noté de nouveau
    quand il repart (sans effet en pratique : statistiques sur la console seulement). Après un
    retour, « suivant » rejoue l'historique avant de piocher de nouveaux mots.
- Sur la console, rien ne change.
