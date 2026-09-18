# Architecture et étapes

## Frontières

- **SDK commun** : observation native, topologie orientée, connexions d'aiguilles, états et textures. Toute correction de lecture du jeu doit y être réalisée pour tous ses consommateurs.
- **Adaptateur** : convertir les observations en données métier, préserver les inconnues, identifier les changements de partie, invalider les données anciennes.
- **Moteur français** : calcul indépendant de l'affichage et de la ville ; configuration des équipements et des règles par installation, avec explication de chaque décision.
- **Présentation** : associer une indication calculée à un état de texture configuré. Un index de texture n'est pas une règle ferroviaire.
- **Diagnostic** : voir le signal, le chemin considéré, le train concerné, les observations manquantes et la raison de l'indication.

## Ordre de développement proposé

1. Inventaire observable et fixtures de capture. Le premier CLI fournit l'inventaire ; il reste à enregistrer la topologie, les réservations détaillées et leur chronologie pour le rejeu.
2. Établir quelles données permettent de distinguer un chemin possible, un itinéraire demandé et un itinéraire effectivement établi. Une ligne ou une destination commerciale ne prouve pas à elle seule le chemin engagé.
3. Définir un premier périmètre de signalisation, documenter ses règles avec des sources françaises de référence, puis construire des scénarios vérifiables avant le calcul des aspects.
4. Ajouter les annonces, restrictions de vitesse, TIV mobiles et indicateurs de direction progressivement, en fonction des informations d'itinéraire réellement disponibles.
5. Le catalogue de textures et le forçage visuel C++ expérimental existent maintenant pour des signaux indépendants stockés dans une table extensible. Valider le mapping des aspects et tester le rendu simultané en jeu. Cette substitution de rendu ne commande pas les autorisations de circulation.
6. Tester les croisements, voies uniques, bifurcations, dépôts, changements de ligne, de sens, d'heure et de partie, dans plusieurs réseaux.

## Points à établir avant les règles

Les réservations observées ne doivent pas être assimilées automatiquement à un enclenchement complet. Vérifier leur orientation, leur durée de validité et leur relation au train. L'occupation, la libération, l'immobilisation des aiguilles, les exceptions applicables au train et les commandes d'aspect restent à caractériser selon les capacités du SDK.

L'état initial du moteur est « indéterminé ». Il ne déduit pas une indication française d'un aspect natif numérique, d'un nom de ligne ou d'une texture sans mapping validé. Les règles simplifiées du visualiseur de graphe, notamment le passage d'un NoWay dès qu'il possède une exception, ne constituent pas des règles d'autorisation pour un train.

Les schémas de gare servent de tests de non-régression ; aucun nom de ville ni ID de signal ne doit être une condition dans les algorithmes communs.
