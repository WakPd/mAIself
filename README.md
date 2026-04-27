# mAIself

mAIself est une application Flutter orientee prevention sante qui vise a rendre visible l'impact des repas sur l'energie, le sommeil et la concentration, avec une experience simple et ludique.

## Objectifs du projet

- Donner un feedback rapide apres un repas (photo ou texte)
- Aider l'utilisateur a comprendre les effets a court terme (fatigue, energie)
- Proposer des recommandations actionnables et progressives
- Construire un MVP solide, evolutif vers un assistant nutrition + activite

## Etat actuel (MVP)

Le projet est en cours de structuration. L'architecture applicative est en place, avec routing, providers, ecrans principaux et integration de base Supabase/Gemini.

## Fonctionnalites disponibles aujourd'hui

- Auth flow (structure): ecrans Login, Register, Profile Setup
- Navigation via GoRouter:
	- /login
	- /register
	- /profile-setup
	- /home
	- /scan
	- /result
	- /sport
	- /history
- Dashboard de base avec avatar et bouton de scan
- Ecran Scan avec parcours vers un ecran de resultat
- Providers Riverpod initialises (auth, dashboard, scan)
- Initialisation Supabase via variables d'environnement
- Service Gemini present (placeholder, pret a brancher)

## Fonctionnalités ajoutées / Dernières Mises à Jour (v1.1)

- **Persistance Cloud (Supabase)** : Les métriques journalières (repas, jauges) sont désormais sauvegardées sur le Cloud via `Supabase.instance.client` au lieu du stockage local, ce qui garantit une synchronisation parfaite en temps réel entre toutes les plateformes (ex: Chrome Web et Android Mobile).
- **Rétrocompatibilité Base de Données** : Ajout de tables SQL sécurisées (`daily_metrics`, `user_settings`) n'impactant pas les versions plus anciennes de l'application en cours de test.
- **Onboarding Enrichi** : Un parcours guidé complet (3 pages) posant 5 questions essentielles (niveau de stress, sommeil, régimes) pour calibrer mathématiquement et sur-mesure les barres d'énergie, de concentration et de sommeil dès la création du jumeau numérique.
- **Menu Profil et Paramétrages Avancés** : Écran `/profile` intégré permettant la mise à jour des paramètres biométriques (qui se synchronisent avec la base de données) et ajout de *sliders dynamiques* pour régler avec précision ses objectifs : Calories, Hydratation, Nombre de repas.
- **UI / UX Professionnelle** : Les anciens "emojis textuels" ont été entièrement remplacés par des **Material Icons** de haute qualité (⚡, 🎯, 😴 deviennent des composants Flutter). L'avatar holographique dispose également de nouveaux états clairs ("En pleine forme", "Équilibré", "Fatigué", "Déterminé").
- Navigation via GoRouter finalisée incluant `/profile`.

## Fonctionnalités en cours / prochaines itérations

- Score métabo dynamique complet (selon analyses poussées)
- Recommandations sport et nutrition personnalisées côté backend
- Optimisation des temps de chargement IA (Gemini)

## Stack technique

- Flutter (Dart)
- Riverpod (state management)
- GoRouter (navigation)
- Supabase (backend/auth/data)
- Gemini (analyse IA, a brancher)
- flutter_dotenv (configuration secrete locale)

## Structure de projet

```
lib/
	core/
		config/
		providers/
		router/
		services/
		theme/
	features/
		auth/
		dashboard/
		scan/
		history/
		sport/
	shared/
		services/
		widgets/
```

## Configuration locale

Creer un fichier .env a la racine du projet avec:

```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
GEMINI_API_KEY=...
```

## Installation

1. Installer Flutter SDK (version compatible Dart >= 3.3.0)
2. Recuperer les dependances:

```
flutter pub get
```

## Lancer le projet

### Web (Chrome)

```
flutter run -d chrome
```

### Mobile (emulateur/appareil)

```
flutter run
```

## Verification qualite

```
flutter analyze
flutter test
```

## Vision produit

Le positionnement mAIself repose sur trois piliers:

- Clarte immediate: comprendre l'impact d'un repas sans friction
- Motivation durable: rendre le suivi engageant et actionnable
- Personnalisation IA: transformer les donnees individuelles en conseils utiles

## Notes

- Le repository contient deja les bases multiplateformes Flutter (android, ios, web, desktop).
- Certaines briques sont volontairement en placeholder pour accelerer l'iteration MVP.