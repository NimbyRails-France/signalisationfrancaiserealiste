# Signalisation française réaliste

Mod C++ chargé automatiquement par le NRF Loader installé avec le Hub.
La DLL s'appelle **SignalisationFrancaiseRealisteMod.dll**.
Cette version nécessite le **SDK 0.7.2** et le **Hub 0.2.3** pour l'installation gérée.

## Afficher une texture

Le mod utilise l'API de haut niveau du SDK :

```cpp
#include <nimby/signal_textures.hpp>

auto textures = nimby::SignalTextures::inGame();
textures.show(signalId, {"sfr_bal_a_cpp_v1", "imgs/ca/sem_bal/tex00.svg"});
textures.restore(signalId);
```

Le SDK retrouve l'index du fichier dans le catalogue chargé et initialise le pont
visuel si nécessaire. Le mod n'a pas à gérer de PID, de hook ou de mémoire du jeu.
La partie et les ressources doivent être chargées avant d'appeler `show`.
Une commande acceptée ne prouve pas à elle seule que le GPU a affiché le fichier.

`src/mod.cpp` décrit les actions de la DLL. Le mod ne produit
pas d'exécutable autonome ; seuls les tests ont leurs propres exécutables.

Le fichier implémente simplement `nimby::createMod()` avec ses actions C++.
La cible `NimbyRailsFranceSDK::Mod` ajoute l'adaptateur du SDK lors de la
compilation : exports du loader, initialisation, arrêt et conversion des erreurs.
Il n'y a pas de `extern "C"`, de `DllMain` ni de gestion Windows à écrire dans le mod.

L'affichage reste forcé jusqu'à restauration ou changement de session. Les
permissions des trains ne sont pas modifiées. Le mod ne choisit pas encore
quel signal doit recevoir quelle image : aucune règle française ni correspondance
arbitraire entre les fichiers et les indications n'est ajoutée.

## Compilation et tests

Le SDK local mis à jour doit être installé dans `../sdk/install/development`.
Les profils CLion Debug/Release utilisent MinGW comme le SDK.

```powershell
cmake --preset Debug
cmake --build --preset Debug
ctest --preset Debug
```

Les tests vérifient les onze SVG BAL type A et le chargement de la DLL par le
loader. La configuration CLion `SFR - Verification textures` vérifie les assets.
[Catalogue des textures](docs/textures-bal-a.html).

## Hub et installation locale

Le paquet contient `SignalisationFrancaiseRealisteMod.dll`, `nrf-mod.ini`,
`mod.txt` et `imgs/`. Le manifeste Hub déclare `loaderApi: 1` et
`module: SignalisationFrancaiseRealisteMod.dll`. Le loader lit le nom de DLL
indiqué dans `nrf-mod.ini`, section `[NRFMod]`, clé `library`.

Le Hub crée une jonction pour les textures dans les mods NIMBY Rails et une
jonction `<jeu>/NRFMods/signalisationfrancaiserealiste` vers le projet installé.
Le loader initialise le mod après SDL et le SDK. L'activation des textures dans
le jeu reste nécessaire.

Après compilation Release :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/package-hub.ps1
```

Le ZIP et `dist/project.json` sont des artefacts locaux, non publiés.
Après compilation des projets voisins `sdk` et `hub`, fermer le jeu, le TCO et
quitter le Hub depuis son icône de notification, puis lancer :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/install-hub-local.ps1
```

Ce script installe le SDK/loader mis à jour avec son pont de textures, le mod et
le Hub local. Les sauvegardes sont conservées sous `build/local-install-*`.
`-PrepareOnly` prépare le paquet sans modifier l'installation. Le journal du
loader est `%LOCALAPPDATA%/NimbyRailsFranceSDK/proxy.log`.
