# « De toi-même tu sais » — plan de fabrication


**Goal:** un jeu LÖVE qui affiche des mots du quotidien tirés au hasard (avec catégories et dé caché), jouable sur l'Anbernic RG SP (ROCKNIX) et dans un navigateur.

**Architecture:** la logique (`words`, `deck`, `settings`, `round`, `textfit`, `input`, `lid`) est en Lua pur, sans LÖVE, testée avec LuaJIT sur le Mac. Les écrans (`screens/`) et `main.lua` ne font que dessiner et relier ces pièces. Deux emballages à partir du même dossier : un port PortMaster pour la console, une version love.js pour le web.

**Tech Stack:** LÖVE 11.5, LuaJIT (tests), love.js (web), bash (lanceur console).

**Spec:** `docs/conception/specs/2026-11-07-de-toi-meme-tu-sais-design.md`

## Global Constraints

- Écran logique 720×480 ; sur un autre écran (web, téléphone) on met à l'échelle en gardant les proportions, avec des bandes `#1a1a1a`.
- Couleurs : fond `#1a1a1a`, rose `#F26EF2`, texte `#f4f4f4`, gris `#888888` (indications), contour gris `#555555`.
- Polices uniquement du catalogue https://jonlekern.github.io/Fonts/ : mots en **Clebard Tall** (`Clebard-Tall.ttf`), tout le reste en **Calebard** (le dossier local des polices Calebard). Fichiers de licence copiés dans `assets/fonts/`.
- Catégories, dans cet ordre, avec leurs libellés : `maison` « Maison », `bouffe` « Bouffe », `transport` « Transport », `boulot-ecole` « Boulot/École », `sante` « Santé », `soiree` « Soirée ».
- Chrono : `0` (aucun, défaut), `30`, `60`, `90` secondes.
- Dé caché : 2, 3 ou 4, chances égales.
- Boutons console : A suivant/choisir, B retour, X passer, Y mes catégories (accueil) / supprimer (éditeur), SELECT règles, START OK (clavier à l'écran). Clavier ordi : P passer, C mes catégories, ? règles.
- Catégories de Johnny : id `perso:<nom>`, nom 1–24 caractères, unique sans tenir compte des majuscules, différent des 6 de base ; mot 1–40 caractères ; fichier `mes-mots.txt` dans le dossier de sauvegarde.
- Statistiques (console seulement) : `stats.txt` dans le dossier de sauvegarde, ligne `AAAA-MM-JJ HH:MM · <Catégorie ou Mélange> · <mot> · <suivant|passé|fin>`.
- Français uniquement, sans internet, pas de score, pas de son.
- Commits en anglais, sans aucune mention d'IA ni ligne Co-Authored-By. Rien sur GitHub ni sur lafleurstudio.ch sans l'accord de Johnny.
- Console : écrire sur les partages Samba uniquement par copie de sauvegarde + `cat nouveau > fichier` (ou `cp -X`) + `cmp` ; jamais `sed -i`, `rsync` ni renommage ; `export COPYFILE_DISABLE=1`, supprimer les `._*`. Accord de Johnny avant chaque écriture, et lui dire à chaque essai s'il faut redémarrer. Ne jamais toucher à `/storage/roms/lafleur-music` ni à `80-lafleur-clapet.conf`.

## Review Focus

1. **Mot très long ou expression longue** (« Brosse à dents électrique ») : jamais de débordement ; il passe sur deux lignes puis rétrécit. → test `test_textfit_long_phrase` (Task 5).
2. **Réglages qui citent une catégorie disparue** (fichier vidé par Johnny) : la catégorie est ignorée, pas de plantage, la pioche part sur `melange`. → test `test_settings_unknown_category` (Task 3).
3. **Clapet qui rebondit ou appuis très rapides** : un seul mot suivant par ouverture ; « fermé » répété ou « ouvert » sans « fermé » avant ne fait rien. → test `test_lid_tracker_bounces` (Task 7).
4. **Accents et ligatures** (É, œ, ç, apostrophe ’) : lus sans perte depuis les fichiers et présents dans les deux polices. → test `test_words_utf8` (Task 2) + vérification des glyphes (Task 5, étape 6).
5. **Toucher sur téléphone** : LÖVE envoie à la fois `touchpressed` et `mousepressed` ; un toucher ne doit avancer que d'un mot. → test `test_input_touch_no_double` (Task 6).

---

### Task 1: Dossier, testeur et fenêtre vide

**Files:**
- Create: `conf.lua`, `main.lua`, `tests/run.lua`, `tests/test_smoke.lua`, `README.md`, `.gitignore`

**Interfaces:**
- Produces: `luajit tests/run.lua` lance tous les fichiers `tests/test_*.lua`. Chaque fichier renvoie une table `{ name = function() ... end }`. Le testeur fournit `T.eq(a, b, msg)`, `T.ok(v, msg)` et `T.fails(fn)` en global `T`, affiche `ok` ou `FAIL nom : message` par test, et sort avec le code 1 s'il y a un échec. `package.path` inclut `src/?.lua`.

- [ ] **Step 1:** écrire `tests/run.lua` et `tests/test_smoke.lua` (`T.eq(1 + 1, 2)`).
- [ ] **Step 2:** lancer `luajit tests/run.lua` → `1 ok, 0 FAIL`, code 0. Ajouter un test faux puis vérifier le code 1, et l'enlever.
- [ ] **Step 3:** `conf.lua` : `t.window.width = 720`, `height = 480`, `title = "De toi-même tu sais"`, `resizable = true`, `t.identity = "detoimeme"`. `main.lua` : fond `#1a1a1a`.
- [ ] **Step 4:** installer LÖVE sur le Mac (`brew install --cask love`) et lancer `love .` → fenêtre sombre 720×480.
- [ ] **Step 5:** `README.md` en anglais (but, lancer les tests, lancer le jeu). `.gitignore` : `build/`, `._*`, `.DS_Store`.
- [ ] **Step 6:** commit `Set up LÖVE project and test runner`.

### Task 2: Listes de mots (`src/words.lua`)

**Files:**
- Create: `src/words.lua`, `src/categories.lua`, `tests/test_words.lua`, `words/*.txt` (fichiers de départ de 3 mots chacun, remplis à la Task 8)

**Interfaces:**
- Produces:
  - `categories.LIST` : tableau ordonné `{ {id = "maison", label = "Maison"}, … }` (ordre et libellés des Global Constraints).
  - `words.parse(text: string) -> {string}` : lignes nettoyées, sans vides, sans `#…`, sans doublons, dans l'ordre du fichier.
  - `words.load(read: function(path) -> string|nil) -> { melange = {string}, categories = { {id, label, words = {string}} } }` : lit `words/melange.txt` et `words/<id>.txt` ; une catégorie sans mot est absente de `categories`.

- [ ] **Step 1: tests**
  - `test_parse_cleans` : `words.parse("  frigo \n\n# note\nbus\nfrigo\r\n")` → `{"frigo", "bus"}`.
  - `test_words_utf8` : `words.parse("Œuf\nÉcole\nAujourd’hui\n")` → les trois chaînes à l'identique (octets compris).
  - `test_load_skips_empty_category` : `read` renvoie `"a\nb"` pour melange, `"# rien\n"` pour soiree, `nil` pour les autres → `#r.melange == 2`, aucune catégorie présente.
  - `test_load_keeps_order` : toutes les catégories ont un mot → les ids sortent dans l'ordre de `categories.LIST`.
- [ ] **Step 2:** `luajit tests/run.lua` → les 4 échouent (module absent).
- [ ] **Step 3:** écrire `src/categories.lua` et `src/words.lua`. Retirer aussi un éventuel BOM UTF-8 en tête de fichier.
- [ ] **Step 4:** tests → tous `ok`.
- [ ] **Step 5:** commit `Add word list loading`.

### Task 3: Réglages (`src/settings.lua`)

**Files:**
- Create: `src/settings.lua`, `tests/test_settings.lua`

**Interfaces:**
- Produces:
  - `settings.default() -> { categories = {}, timer = 0 }` (`categories` : ensemble `{[id] = true}`).
  - `settings.parse(text: string|nil, known: {[id]=true}) -> settings` : format texte `timer=60` et `categories=soiree,bouffe` ; toute valeur inconnue ou abîmée retombe sur le défaut, champ par champ.
  - `settings.serialize(s) -> string` : ids triés dans l'ordre de `categories.LIST`.

- [ ] **Step 1: tests**
  - `test_settings_roundtrip` : `{categories={soiree=true,bouffe=true}, timer=60}` → serialize → parse → identique.
  - `test_settings_garbage` : `parse("@@@\ntimer=45\n", known)` → `timer == 0`, `categories` vide.
  - `test_settings_nil` : `parse(nil, known)` → défaut.
  - `test_settings_unknown_category` : `parse("categories=soiree,vacances", {soiree=true})` → seulement `soiree`.
- [ ] **Step 2:** tests → échecs.
- [ ] **Step 3:** écrire `src/settings.lua`.
- [ ] **Step 4:** tests → `ok`.
- [ ] **Step 5:** commit `Add settings parsing`.

### Task 4: Pioche et dé caché (`src/deck.lua`)

**Files:**
- Create: `src/deck.lua`, `tests/test_deck.lua`

**Interfaces:**
- Consumes: résultat de `words.load` (Task 2), ensemble `settings.categories` (Task 3).
- Produces:
  - `deck.bag(items: {any}, rng) -> bag`, `bag:draw() -> item` : paquet mélangé (Fisher-Yates avec `rng`) ; un élément ne revient pas avant la fin du paquet ; au remélange, le premier tiré n'est pas le dernier sorti (si le paquet a plus d'un élément).
  - `deck.new(lists, checked: {[id]=true}, rng) -> deck`, `deck:next() -> word: string, category: {id, label}|nil`. `rng(a, b)` renvoie un entier entre a et b inclus (comme `love.math.random`).
  - Le paquet des catégories cochées est commun : éléments `{word, category}`.

Le dé : `self.wait = rng(2, 4)` au départ et après chaque mot de catégorie ; à chaque `next()`, on décrémente `wait` ; à 1, le mot vient du paquet des catégories, sinon de `melange`. Sans catégorie cochée (ou cochées mais toutes vides), le dé n'est pas utilisé.

- [ ] **Step 1: tests** (rng à graine fixe `math.randomseed(1)`, `rng = math.random`)
  - `test_bag_no_repeat_before_empty` : paquet de 10 → 10 tirages tous différents.
  - `test_bag_no_back_to_back` : 1000 tirages d'un paquet de 3 → jamais deux fois le même d'affilée.
  - `test_deck_melange_only` : aucune case cochée → 200 mots, tous dans `melange`, `category == nil`.
  - `test_deck_dice_gap` : `soiree` cochée → les écarts entre deux mots de catégorie valent toujours 2, 3 ou 4 sur 3000 tirages, et chaque valeur apparaît entre 25 % et 42 % des fois.
  - `test_deck_shared_pool` : `soiree` et `bouffe` cochées → les deux catégories sortent, chaque mot de catégorie porte son `category.label`.
  - `test_deck_single_word_lists` : melange = `{"a"}`, soiree = `{"b"}` → 20 tirages sans erreur.
- [ ] **Step 2:** tests → échecs.
- [ ] **Step 3:** écrire `src/deck.lua`.
- [ ] **Step 4:** tests → `ok`.
- [ ] **Step 5:** commit `Add word deck with hidden die`.

### Task 5: Manche, ajustement du texte et écrans

**Files:**
- Create: `src/round.lua`, `src/textfit.lua`, `src/screens/home.lua`, `src/screens/play.lua`, `src/screens/timeup.lua`, `src/ui.lua`, `tests/test_round.lua`, `tests/test_textfit.lua`
- Create: `assets/fonts/Clebard-Tall.ttf`, `assets/fonts/Calebard-*.ttf` (graisses utilisées), fichiers de licence
- Modify: `main.lua`

**Interfaces:**
- Consumes: `deck` (Task 4), `settings` (Task 3), `words`/`categories` (Task 2).
- Produces:
  - `round.new(deck, seconds) -> round` ; `round:next()` (mot suivant ; démarre le chrono au premier mot) ; `round:update(dt) -> "timeup"|nil` ; champs `word`, `category`, `remaining` (nil si pas de chrono).
  - `textfit.fit(text, box_w, box_h, sizes: {number}, measure: function(text, size) -> w, h) -> size, lines: {string}` : essaie chaque taille de la plus grande à la plus petite, d'abord sur une ligne puis coupée en deux lignes à l'espace le plus central ; renvoie la première qui tient. Sinon, la plus petite taille sur deux lignes.
  - Écrans : chacun expose `enter(app)`, `draw(app)`, `action(app, name)` et `update(app, dt)` (si besoin). `app` contient `lists`, `settings`, `deck`, `round`, `fonts`, `switch(screen_name)`.
  - `ui.lua` : mise à l'échelle 720×480, `ui.toLogical(x, y)`, couleurs des Global Constraints.

Dessin d'après la maquette validée : accueil (titre « De toi-même » + « tu sais » en rose, pastilles des catégories rose = cochée, contour `#555555` sinon, ligne chrono « aucun · 30 · 60 · 90 s » avec le choix actif en rose, bouton **Jouer** en bas à droite) ; jeu (mot centré en Clebard Tall, catégorie en haut à gauche en gris, chrono en haut à droite en rose `m:ss`, rappel des commandes en bas en gris, bouton retour en haut à gauche affiché seulement après un premier toucher d'écran (`app.touched = true`), catégorie alors décalée à sa droite) ; temps écoulé (« Temps écoulé » en rose, bouton **Rejouer**, « B : retour à l'accueil »). Navigation à l'accueil : la croix parcourt catégories → chrono → Jouer ; A coche/choisit.

- [ ] **Step 1: tests**
  - `test_round_no_timer` : `seconds = 0` → `update(999)` renvoie nil, `remaining == nil`.
  - `test_round_timer` : `seconds = 30` → `next()`, `update(29.9)` → nil, `update(0.2)` → `"timeup"`.
  - `test_round_timer_starts_on_first_word` : `update(100)` avant `next()` → nil.
  - `test_textfit_short` : mesure fictive `w = #text * size * 0.8`, `h = size` ; « Frigo » dans 680×300, tailles `{120, 96, 72, 56, 40}` → 120, 1 ligne.
  - `test_textfit_long_phrase` : « Brosse à dents électrique » → 2 lignes, et chaque ligne mesurée ≤ 680.
  - `test_textfit_single_long_word` : « Anticonstitutionnellement » → 1 ligne, taille plus petite, largeur ≤ 680 si une taille le permet.
- [ ] **Step 2:** tests → échecs.
- [ ] **Step 3:** écrire `round.lua` et `textfit.lua` ; tests → `ok`.
- [ ] **Step 4:** télécharger `Clebard.zip` depuis https://jonlekern.github.io/Fonts/clebard/, copier `Clebard-Tall.ttf` + licence ; copier Calebard + licence depuis le dossier local des polices Calebard.
- [ ] **Step 5:** écrire `ui.lua`, les trois écrans et le câblage dans `main.lua` (chargement des listes via `love.filesystem.read`, réglages lus au démarrage et écrits à chaque changement avec `love.filesystem.write("settings.txt", …)`).
- [ ] **Step 6:** vérifier les glyphes : un petit script `tools/glyphs.py` (fontTools via `python3 -m pip install --user fonttools`) liste les caractères de `words/*.txt` absents de `Clebard-Tall.ttf` → sortie vide attendue.
- [ ] **Step 7:** `love .` : parcourir les 3 écrans au clavier, comparer à la maquette, faire une capture de chaque écran et l'envoyer à Johnny.
- [ ] **Step 8:** commit `Add screens, round timer and text fitting`.

### Task 6: Commandes (`src/input.lua`)

**Files:**
- Create: `src/input.lua`, `tests/test_input.lua`
- Modify: `main.lua` (brancher `keypressed`, `gamepadpressed`, `touchpressed`, `mousepressed` sur `input`)

**Interfaces:**
- Produces: `input.new() -> input` ; `input:key(k)`, `input:button(b)`, `input:touch(x, y, t)`, `input:mouse(x, y, button, istouch, t)` renvoient une action ou nil. Actions : `"up"`, `"down"`, `"left"`, `"right"`, `"select"`, `"back"`, `"skip"`, `"mycats"`, `"rules"`, `"ok"`, `"erase"`, `"tap"` (avec `x, y` logiques). Correspondances : clavier flèches / `return` / `space` → select, `escape` → back, `p` → skip, `c` → mycats, `?` (et `/` avec Maj) → rules, `backspace` → erase ; manette `dpup…`, `a` → select, `b` → back, `x` → skip (et erase sur l'écran de saisie), `y` → mycats, `back` (SELECT) → rules, `start` → ok. Chaque écran décide quoi faire d'une action (par exemple `y` = supprimer dans l'éditeur). `t` est l'heure en secondes.

- [ ] **Step 1: tests**
  - `test_input_keys` : `return` et `space` → `"select"`, `escape` → `"back"`.
  - `test_input_pad` : `a` → `"select"`, `b` → `"back"`, `dpdown` → `"down"`, `x` → `"skip"`, `y` → `"mycats"`, `back` → `"rules"`, `start` → `"ok"`.
  - `test_input_touch_no_double` : `touch(10, 10, 5.00)` → `"tap"`, puis `mouse(10, 10, 1, true, 5.01)` → nil ; `mouse(10, 10, 1, false, 6)` → `"tap"`.
- [ ] **Step 2:** tests → échecs.
- [ ] **Step 3:** écrire `src/input.lua` et le brancher : dans le jeu, `select` et `tap` = mot suivant (sauf `tap` sur le bouton retour = back).
- [ ] **Step 4:** tests → `ok` ; `love .` : souris, clavier et manette (si une est branchée) font ce qui est prévu dans le tableau de la spec §5.
- [ ] **Step 5:** commit `Add input mapping for keys, gamepad and touch`.

### Task 7: Clapet (`src/lid.lua`)

**Files:**
- Create: `src/lid.lua`, `src/lid_thread.lua`, `tests/test_lid.lua`
- Modify: `main.lua` (démarrer le fil seulement si `love.system.getOS() == "Linux"` et un appareil est trouvé)

**Interfaces:**
- Produces:
  - `lid.find_device(text: string|nil) -> "/dev/input/eventN"|nil` et `lid.decode(bytes) -> {type, code, value}|nil` : même logique que `lidwatch/common/lid.lua` de LAFLEURMUSIC (bit SW_LID dans `B: SW=`, input_event aarch64 de 24 octets, little-endian).
  - `lid.tracker() -> tracker`, `tracker:feed(state: "open"|"closed") -> true|nil` : renvoie `true` seulement sur « open » qui suit un « closed ».
  - `src/lid_thread.lua` : reçoit le chemin, lit en boucle, pousse `"open"`/`"closed"` (ou `"error:…"`) sur le canal `"lid"`. `main.lua` lit le canal dans `love.update` ; `true` du tracker = action `"select"` sur l'écran jeu seulement.

- [ ] **Step 1: tests**
  - `test_lid_find_device` : extrait de `/proc/bus/input/devices` avec un bloc `B: SW=1` / `Handlers=event3` → `"/dev/input/event3"` ; sans bloc SW → nil.
  - `test_lid_decode` : 24 octets avec type 5, code 0, value 1 → `{type=5, code=0, value=1}` ; 10 octets → nil.
  - `test_lid_tracker_bounces` : `open` → nil ; `closed`, `closed` → nil ; `open` → true ; `open` → nil.
- [ ] **Step 2:** tests → échecs.
- [ ] **Step 3:** écrire `lid.lua`, `lid_thread.lua`, branchement dans `main.lua` ; en cas d'`error:` ou d'appareil absent, on écrit une ligne dans le journal et on continue sans clapet.
- [ ] **Step 4:** tests → `ok` ; `love .` sur le Mac → aucun message d'erreur, le jeu marche (pas de clapet).
- [ ] **Step 5:** commit `Add lid switch support for the RG SP`.

### Task 8: Passer un mot, statistiques et carré des règles

**Files:**
- Create: `src/stats.lua`, `src/screens/rules.lua`, `tests/test_stats.lua`
- Modify: `src/round.lua`, `tests/test_round.lua`, `src/screens/home.lua`, `src/screens/play.lua`, `main.lua`

**Interfaces:**
- Consumes: `round` (Task 5), `input` (Task 6).
- Produces:
  - `round.new(deck, seconds, on_done)` : `on_done(entry)` est appelé quand un mot quitte l'écran, avec `entry = {word, category_label|nil, result = "suivant"|"passé"|"fin"}`. `round:next()` → résultat `suivant` pour le mot affiché ; `round:skip()` → `passé` ; `round:finish()` (temps écoulé ou retour à l'accueil) → `fin`. Pas d'appel avant le premier mot.
  - `stats.line(entry, date: string) -> string` (date déjà formatée `AAAA-MM-JJ HH:MM`), `Mélange` si `category_label` est nil.
  - `main.lua` : sur la console (`love.system.getOS() == "Linux"`), `on_done` ajoute la ligne à `stats.txt` avec `love.filesystem.append` et `os.date("%Y-%m-%d %H:%M")` ; ailleurs, `on_done` ne fait rien.
  - Écran `rules` : carré par-dessus l'accueil avec le texte exact de la spec §4.4 ; `back` ou `tap` hors du carré le ferme. Le « ? » de l'accueil l'ouvre (`rules` ou `tap` dessus).

- [ ] **Step 1: tests**
  - `test_round_results` : `next()` (1er mot, pas d'appel), `next()` → `suivant`, `skip()` → `passé`, `finish()` → `fin` ; trois appels exactement, dans cet ordre.
  - `test_round_finish_before_start` : `finish()` sans mot affiché → aucun appel.
  - `test_stats_line` : `{word="Suçon", category_label="Soirée", result="passé"}`, `"2026-11-08 23:14"` → `"2026-11-08 23:14 · Soirée · Suçon · passé\n"` ; sans catégorie → `· Mélange ·`.
- [ ] **Step 2:** tests → échecs.
- [ ] **Step 3:** écrire `stats.lua`, compléter `round.lua`, l'écran `rules`, le « ? » et le rappel « SELECT : règles · Y : mes catégories » dans l'accueil, le bouton **Passer** sur écran tactile et le rappel « A : suivant · X : passer · clapet : suivant » dans le jeu (maquette validée).
- [ ] **Step 4:** tests → `ok` ; `love .` : P passe le mot, ? ouvre et Échap ferme les règles ; captures envoyées à Johnny.
- [ ] **Step 5:** commit `Add skip, word stats and rules card`.

### Task 9: Mes catégories

**Files:**
- Create: `src/custom.lua`, `src/keyboard.lua`, `src/screens/mycats.lua`, `src/screens/catwords.lua`, `src/screens/typing.lua`, `src/screens/confirm.lua`, `tests/test_custom.lua`, `tests/test_keyboard.lua`
- Modify: `src/screens/home.lua`, `main.lua`

**Interfaces:**
- Consumes: `words.load` (Task 2), `settings` (Task 3), `deck.new` (Task 4), `input` (Task 6).
- Produces:
  - `custom.parse(text|nil) -> { {name, words = {string}} }` ; format : une ligne `[Nom]` ouvre une catégorie, les lignes suivantes sont ses mots ; lignes illisibles ignorées. `custom.serialize(cats) -> string`.
  - `custom.valid_name(cats, name, ignore_index|nil) -> true | nil, reason` (`"vide"`, `"trop long"`, `"existe"`, `"réservé"`) ; `custom.add_word(cat, word) -> true | nil, reason` (`"vide"`, `"trop long"`, `"existe"`) ; noms et mots nettoyés (espaces en trop).
  - `custom.as_categories(cats) -> { {id = "perso:"..name, label = name, words} }` pour les catégories non vides ; `main.lua` les ajoute après les catégories de base dans `lists.categories`, et dans l'ensemble `known` passé à `settings.parse`.
  - `keyboard.new()` : grille AZERTY 4 rangées de la maquette (`a–p`, `q–m`, `w–n é è à ç`, `Maj espace ⌫ OK`) ; `kb:move(dir)` (bloqué aux bords), `kb:press() -> {type = "char", char} | {type = "shift"} | {type = "space"} | {type = "erase"} | {type = "ok"}`, `kb.shift` (majuscule pour la lettre suivante seulement).
  - Écran `typing` : sur la console, `keyboard` ; ailleurs, `love.keyboard.setTextInput(true)` et `love.textinput` ; `ok` valide avec les règles de `custom`, le message d'erreur (« Ce nom existe déjà », « Trop long », « Vide ») s'affiche en rose sous la saisie.
  - Écran `confirm` : « Sûr ? » A : oui · B : non.
  - `custom` est écrit dans `mes-mots.txt` à chaque changement ; supprimer une catégorie la retire aussi des réglages cochés et recrée la pioche.

- [ ] **Step 1: tests**
  - `test_custom_roundtrip` : deux catégories avec accents → serialize → parse → identiques.
  - `test_custom_damaged` : `"mot sans catégorie\n[A]\nx\n[\n"` → une catégorie `A` avec `{"x"}`.
  - `test_custom_names` : `""` → vide ; 25 caractères → trop long ; `"potes"` quand `"Potes"` existe → existe ; `"Soirée"` → réservé ; renommer `Potes` en `potes` (même index) → true.
  - `test_custom_words` : 41 caractères → trop long ; doublon → existe ; `"  Bac   de philo "` → ajouté comme `"Bac de philo"`.
  - `test_custom_as_categories` : une catégorie vide n'apparaît pas ; id `perso:Potes`.
  - `test_keyboard_edges` : depuis `a`, `left` puis `up` → reste sur `a` ; aller sur `OK` puis `press` → `{type="ok"}` ; `Maj` puis `a` → `"A"`, puis `a` → `"a"`.
- [ ] **Step 2:** tests → échecs.
- [ ] **Step 3:** écrire `custom.lua`, `keyboard.lua` ; tests → `ok`.
- [ ] **Step 4:** écrire les 4 écrans d'après la maquette validée (liste avec nombre de mots et « + Nouvelle catégorie », mots avec « + Ajouter un mot », clavier, confirmation) et l'entrée depuis l'accueil (Y / C / bouton tactile) ; catégories de Johnny en pastilles après les 6 de base.
- [ ] **Step 5:** `love .` : créer « Potes », ajouter 3 mots, la cocher, jouer et la voir sortir ; quitter et relancer → toujours là ; la supprimer → disparue de l'accueil. Captures envoyées à Johnny.
- [ ] **Step 6:** commit `Add in-game custom categories editor`.

### Task 10: Les vraies listes de mots

**Files:**
- Modify: `words/melange.txt` (environ 500), `words/maison.txt`, `words/bouffe.txt`, `words/transport.txt`, `words/boulot-ecole.txt`, `words/sante.txt`, `words/soiree.txt` (environ 60 chacun)

- [ ] **Step 1:** écrire les listes : mots et expressions courtes du quotidien en français, faciles à faire deviner par un souvenir, une majuscule en tête (« Frigo », « Gueule de bois »), 3 mots maximum par entrée, pas de nom de marque déposée sauf s'il est devenu un mot courant (« Doliprane » oui). `soiree` : osé mais pas insultant ni discriminant.
- [ ] **Step 2:** `luajit tests/run.lua` → `ok` ; petit contrôle `luajit -e` qui compte les mots par fichier et signale les doublons entre `melange` et les catégories (affichage seulement, les doublons sont permis).
- [ ] **Step 3:** relancer `tools/glyphs.py` → sortie vide.
- [ ] **Step 4:** envoyer les listes à Johnny et **attendre sa relecture** ; appliquer ses corrections.
- [ ] **Step 5:** commit `Add word lists`.

### Task 11: Sur la console (port PortMaster)

**Files:**
- Create: `port/De toi-meme tu sais.sh`, `tools/build_port.sh`, `tools/install_console.sh`

**Interfaces:**
- Produces: `tools/build_port.sh` crée `build/port/` = le lanceur `.sh` + un dossier `detoimeme/` (le jeu : `main.lua`, `conf.lua`, `src/`, `words/`, `assets/`) + `detoimeme/bin/` (binaire LÖVE aarch64 et ses `libs`, copiés depuis le port PortMaster « Spotify Connect » déjà sur la console, comme LAFLEURMUSIC, sans toucher à `lafleur-music`).

Lanceur (modèle : `LAFLEURMUSIC.sh`, lu sur la console) : `. /etc/profile` ; génère la table des manettes avec `/storage/.config/PortMaster/mapper.txt` vers `/tmp/detoimeme-gamecontrollerdb.txt` et exporte `SDL_GAMECONTROLLERCONFIG_FILE` ; `LD_LIBRARY_PATH="$GAME/bin/libs:/usr/lib/compat:$LD_LIBRARY_PATH"` ; `XDG_DATA_HOME="$GAME/conf"` ; `set_kill set "detoimeme"` ; lance `"$GAME/bin/detoimeme" "$GAME"` ; journal dans `$GAME/log.txt`.

- [ ] **Step 1:** écrire `build_port.sh` et le lanceur ; `tools/build_port.sh` → `build/port/` complet, sans `._*`.
- [ ] **Step 2:** écrire `tools/install_console.sh` en suivant `tools/install.sh` de LAFLEURMUSIC et les règles Samba des Global Constraints (vérifier la connexion par `nc -z -G 3 192.168.1.138 445`, monter `games-roms`, copier vers `/storage/roms/ports/`, `cmp` de chaque fichier, supprimer les `._*`, démonter).
- [ ] **Step 3:** **demander l'accord de Johnny**, lui dire si un redémarrage est nécessaire (normalement non ; il faudra peut-être rafraîchir la liste des jeux dans EmulationStation), puis lancer l'installation.
- [ ] **Step 4:** Johnny lance le jeu depuis « Ports ». Vérifier avec lui : les 3 écrans, A / B / START / croix, le clapet (fermer-rouvrir = nouveau mot), le chrono qui continue clapet fermé, X pour passer, SELECT pour les règles, Y et le clavier à l'écran pour créer une catégorie, puis la même chose avec LAFLEURMUSIC en arrière-plan. Récupérer `stats.txt` par le Wi-Fi et vérifier ses lignes. Lire `log.txt` sur la console pour les erreurs.
- [ ] **Step 5:** commit `Add PortMaster port and console install script`.

### Task 12: Version web

**Files:**
- Create: `tools/build_web.sh`, `web/index.html` (page d'accueil du jeu : fond `#1a1a1a`, plein écran, pas de texte en plus)

**Interfaces:**
- Produces: `tools/build_web.sh` crée `build/web/` avec love.js en mode compatibilité (`npx love.js -c -t "De toi-même tu sais" build/detoimeme.love build/web`), après avoir zippé le jeu en `build/detoimeme.love`. Le code du clapet n'est pas démarré sur le web (Task 7, condition sur l'OS).

- [ ] **Step 1:** installer Node (`brew install node`) ; écrire `build_web.sh` ; le lancer → `build/web/index.html` présent.
- [ ] **Step 2:** servir en local (`python3 -m http.server -d build/web 8000`) et ouvrir dans le navigateur : tous les écrans, clic et clavier, réglages et « Mes catégories » gardés après rechargement, aucun `stats.txt` écrit.
- [ ] **Step 3:** vérifier au doigt avec l'émulation mobile du navigateur intégré (375×812) : un toucher = un mot, boutons retour et Passer visibles, clavier du téléphone pour « Mes catégories », mot lisible.
- [ ] **Step 4:** demander à Johnny d'ouvrir l'adresse locale sur son iPhone et un Android du même Wi-Fi (adresse IP du Mac, port 8000) et de confirmer que ça charge et se joue.
- [ ] **Step 5:** commit `Add web build`.
- [ ] **Step 6:** la mise en ligne sur lafleurstudio.ch se fait **seulement après l'accord de Johnny**, une fois l'hébergement du site regardé ; elle n'est pas dans ce plan.
