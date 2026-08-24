# BaseTemplate — base FiveM ESX pour la formation EsaiStudio

Base de serveur FiveM prête à démarrer, utilisée comme point de départ dans la
formation développement d'[EsaiStudio](https://discord.gg/esaistudio). Elle est
volontairement minimale : le framework, l'inventaire, la voix et l'apparence
sont en place, le reste des dossiers est vide et attend **vos** scripts.

## Ce qu'il y a dedans

| Brique | Resource | Version |
|---|---|---|
| Framework | `es_extended` | 1.13.4 |
| Base de données | `oxmysql` | 2.12.0 |
| Librairie | `ox_lib` | 3.30.6 |
| Inventaire | `ox_inventory` | 2.44.1 |
| Apparence / vêtements | `illenium-appearance` | — |
| Voix proximité | `pma-voice` | — |
| Identité, notifications, TextUI | `esx_identity`, `esx_notify`, `esx_textui` | — |
| Divers maison | `esai_core`, `esai_ipl` | — |

Game build imposé : **3258**.

## Prérequis

- **FXServer (artefacts)** — non inclus dans ce dépôt, ils pèsent ~190 Mo et
  changent en permanence. Téléchargez-les sur le site officiel :
  [Windows](https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/) ·
  [Linux](https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/)
- **MariaDB** ou **MySQL** (une base vide, par exemple `basetemplate`)
- Une **clé serveur** gratuite depuis le [portail Cfx.re](https://keymaster.fivem.net/)

## Installation

**1. Récupérer la base**

```bash
git clone https://github.com/Yuki1oo/BaseTemplate.git
cd BaseTemplate
```

Ou bouton vert **Code → Download ZIP** si vous préférez.

**2. Poser les artefacts**

Décompressez les artefacts FXServer dans un dossier `artefacts/` à la racine,
à côté de `resources/` et `server.cfg` :

```
BaseTemplate/
├── artefacts/      ← les binaires que vous venez de télécharger
├── resources/
└── server.cfg
```

**3. Importer la base de données**

Trois fichiers, et rien d'autre :

| Fichier | Ce qu'il crée |
|---|---|
| `resources/[SQL]/1.sql` | tables ESX : `users`, `jobs`, `job_grades`, `licenses`, `user_licenses`, `owned_vehicles`, `vehicle_categories`, `whitelist` |
| `resources/[SQL]/2.sql` | tables illenium-appearance : `playerskins`, `player_outfits`, `player_outfit_codes`, `management_outfits` |
| `resources/[SQL]/3.sql` | système VIP EsaiStudio |

> **N'importez pas les `.sql` livrés dans les resources elles-mêmes**
> (`es_extended/es_extended.sql`, `esx_identity/esx_identity.sql`,
> `illenium-appearance/sql/*.sql`) : leur contenu est déjà fusionné dans les
> trois fichiers ci-dessus. `esx_identity.sql` échouerait d'ailleurs sur un
> `Duplicate column name 'firstname'`, puisque `1.sql` crée déjà la table
> `users` avec les colonnes d'identité.

**4. Configurer `server.cfg`**

Deux lignes à remplir, elles sont volontairement vides dans le dépôt :

```cfg
sv_licenseKey "votre_clé_keymaster"
set mysql_connection_string "server=127.0.0.1;uid=root;database=basetemplate;password=votre_mdp;"
```

> ⚠️ **Ne commitez jamais ces deux valeurs.** Si vous travaillez sur un fork
> public, copiez le fichier en `server.local.cfg` (déjà couvert par le
> `.gitignore`) et lancez le serveur dessus.

**5. Démarrer**

```bash
# Windows
artefacts\FXServer.exe +exec server.cfg

# Linux
./artefacts/run.sh +exec server.cfg
```

Au premier lancement, les resources `yarn` et `webpack` reconstruisent
automatiquement les dépendances de `chat` — c'est normal que ce démarrage soit
plus long que les suivants.

## Structure des resources

Les dossiers sont numérotés pour imposer l'ordre de démarrage : FiveM charge
`ensure` dans l'ordre du `server.cfg`, et la numérotation garde la même logique
visuellement dans l'explorateur.

```
[0.DEFAULT]      resources par défaut de Cfx.re (chat, spawnmanager, builders…)
[1.ESX_MAIN]     cœur ESX — à ne pas toucher tant que vous débutez
[2.OX_MAIN]      oxmysql, ox_lib, ox_inventory
[3.MAIN]         apparence et voix
[4.HUNCHO]       resources maison EsaiStudio
[5.PAID_SCRIPT]  vos scripts payants          ← vide, à vous
[6.FREE_SCRIPT]  vos scripts gratuits         ← vide, à vous
[7.MLO]          les MLO / interiors
[8.WEAPONS]      armes custom                 ← vide, à vous
[9.CLOTCHES]     vêtements custom             ← vide, à vous
[10.BOUTIQUE]    boutique                     ← vide, à vous
[11.ADMIN]       outils d'administration      ← vide, à vous
[12.AUTRES]      fourre-tout                  ← vide, à vous
[13.POUBELLE]    resources désactivées
[14.CARS]        véhicules add-on             ← vide, à vous
[SQL]            schéma de base à importer
```

Chaque nouvelle resource doit être ajoutée avec `ensure <nom>` dans
`server.cfg`, dans la section correspondant à son dossier.

## Points à connaître

- **`esai_core` ne démarre pas tel quel** : son `fxmanifest.lua` et son `s.lua`
  sont vides dans cette version. Le code client (`c.lua` — noragdoll et gestion
  des contrôles) est complet, il ne lui manque que son manifeste. Bon premier
  exercice pour comprendre à quoi sert un `fxmanifest`.
- Le dossier `[13.POUBELLE]` sert à ranger ce que vous désactivez plutôt qu'à
  le supprimer. Pensez à retirer le `ensure` correspondant.
- `chat/dist` n'est pas versionné : il est régénéré au démarrage.

## Licences

Ce dépôt redistribue des resources tierces, chacune sous **sa propre licence**,
conservée dans son dossier :

| Resource | Licence | Source |
|---|---|---|
| `[0.DEFAULT]/*` | MIT | [citizenfx/cfx-server-data](https://github.com/citizenfx/cfx-server-data) |
| `es_extended`, `esx_*` | GPL-3.0 | [esx-framework](https://github.com/esx-framework) |
| `ox_inventory` | GPL-3.0 | [overextended](https://github.com/overextended) |
| `ox_lib`, `oxmysql` | LGPL-3.0 | [overextended](https://github.com/overextended) |
| `pma-voice` | MIT | [AvarianKnight/pma-voice](https://github.com/AvarianKnight/pma-voice) |
| `illenium-appearance` | GPL-3.0 | [iLLeniumStudios](https://github.com/iLLeniumStudios/illenium-appearance) |

Les fichiers `LICENSE` d'origine sont conservés. Toute redistribution doit les
conserver également.
