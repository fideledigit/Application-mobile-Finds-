# Finds — application mobile

Application Flutter de mise en relation entre documents perdus et documents
trouvés (projet Finds / FindMyDoc).

## Démarrer

```bash
flutter pub get
flutter run
```

L'application a besoin de l'API GraphQL (`../finds-api`). Sans elle, les écrans
branchés restent vides mais l'interface fonctionne (données de démo).

```bash
cd ../finds-api
npm run dev          # http://localhost:4000/graphql
```

## 📘 Guide de liaison API

**Tout est expliqué dans [`GUIDE_LIAISON_API.md`](GUIDE_LIAISON_API.md).**

- § 2 : où mettre l'URL de l'API → `lib/core/config/api_config.dart`
- § 4 : **ta page réservée** → rebrancher l'écran Accueil toi-même
- § 6 : vérifier ce qui est branché et ce qui reste à faire
- § 7 : déploiement (API en HTTPS + app pointée dessus)

> 🟡 La liaison API de la page **Accueil** a été volontairement retirée :
> c'est l'exercice principal du guide.

## Structure rapide

```
lib/
├── core/
│   ├── api/          # client GraphQL + toutes les requêtes
│   ├── config/       # ← URL de l'API (api_config.dart)
│   ├── constants/    # couleurs, tailles, textes
│   └── theme/
└── presentation/
    └── views/        # écrans (accueil, auth, déclarations, matches…)
```

## Vérifier le projet

```bash
flutter analyze
flutter test
```
