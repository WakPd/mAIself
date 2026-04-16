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

## Fonctionnalites en cours / prochaines iterations

- Authentification reelle Supabase (login/register/signout)
- Analyse IA des repas (texte/image) via Gemini
- Stockage historique des analyses dans Supabase
- Score metabo dynamique (energie/sommeil/concentration)
- Recommandations sport et nutrition personnalisees
- UX mobile/web plus aboutie (etat loading, erreurs, empty states)

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