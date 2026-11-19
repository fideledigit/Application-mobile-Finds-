# 📄 GUIDE & EXERCICE : Lier la Page Déclaration à l'API RetrouveTout

> **Objectif :** Maîtriser le fonctionnement complet de la **Page Déclaration**, comprendre comment une déclaration passe du formulaire Flutter au serveur GraphQL `https://nye-agbale.vercel.app`, et savoir le refaire vous-même pas à pas.

---

## 1. La Carte du Flux Déclaration

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PARCOURS UTILISATEUR                            │
└────────────────────────────────────────────────────────────────────────┘
                                 │
                 ┌───────────────┴───────────────┐
                 ▼                               ▼
       [1. Onglet Déclarations]        [2. Nouveau Formulaire]
        DeclarationsListView            DeclarationTypeChoiceView
                 │                               │
                 ▼                               ▼
          Query GraphQL                  LostDocumentStep1View (Type doc)
        `myDeclarations`                         │
                 │                               ▼
                 ▼                       LostDocumentStep2View (Identité, lieu)
     Liste des cartes & filtres                  │
                                                 ▼
                                         LostDocumentStep3View (Récapitulatif)
                                                 │
                                                 ▼
                                          Mutation GraphQL
                                        `createDeclaration`
                                                 │
                                                 ▼
                                    Serveur API (nye-agbale)
                                    Stockage DB + Matching BullMQ
                                                 │
                                                 ▼
                                    `declarationsRevision++`
                                                 │
                                                 ▼
                                    Auto-refresh dans l'onglet !
```

---

## 2. Le Contrat GraphQL de l'API (`nye-agbale`)

### A. La mutation de création (`createDeclaration`)

Contrairement à l'ancienne API qui avait deux mutations séparées, la nouvelle API utilise **une seule mutation universelle** :

```graphql
mutation CreateDeclaration($input: CreateDeclarationInput!) {
  createDeclaration(input: $input) {
    success
    message
  }
}
```

#### Les paramètres obligatoires (`CreateDeclarationInput`) :
| Champ | Type | Description / Exemple |
|---|---|---|
| `type` | `TypeDeclaration!` | `PERTE` ou `TROUVAILLE` |
| `typeDocument` | `TypeDocument!` | `CNI`, `PASSEPORT`, `PERMIS_CONDUIRE`, `CARTE_GRISE`, `CARTE_ETUDIANT`, etc. |
| `nomProprietaire` | `String!` | Nom de famille inscrit sur la pièce |
| `prenomProprietaire` | `String!` | Prénom(s) inscrit(s) sur la pièce |
| `ville` | `String!` | Ville de perte / découverte (ex: `"Lomé"`) |
| `source` | `SourceDeclaration` | `"MOBILE"` (indique que la déclaration vient de l'app Flutter) |
| `numeroDocument` | `String` | Numéro de la pièce (optionnel ou masqué) |
| `descriptionLibre` | `String` | Circonstances particulières |
| `photoUrl` | `String` | URL CDN issue de `POST /api/upload-mobile` |

---

### B. La requête de lecture (`myDeclarations`)

```graphql
query MyDeclarations(
  $pagination: PaginationInput
  $statut: StatutDeclaration
  $type: TypeDeclaration
) {
  myDeclarations(
    pagination: $pagination
    statut: $statut
    type: $type
  ) {
    data {
      id
      type
      typeDocument
      nomProprietaire
      prenomProprietaire
      numeroDocument
      ville
      quartier
      statut
      photoUrl
      pdfUrl
      matchesCount
      createdAt
    }
    meta {
      page
      pageSize
      total
      totalPages
    }
  }
}
```

---

## 3. Exercice Pratique : Coder la liaison soi-même

### Défi 1 (Niveau Débutant) : Appeler la requête dans `DeclarationsListView`

Dans [`lib/presentation/views/declarations/declarations_list_view.dart`](file:///home/k-b17/finds/lib/presentation/views/declarations/declarations_list_view.dart) :

1. Repérez la méthode `_fetchDeclarations()` :
```dart
Future<void> _fetchDeclarations() async {
  // 1. Vérifiez que l'utilisateur est authentifié
  if (FindsApiClient.authToken.value == null) return;

  setState(() => _isLoading = true);

  // 2. Exécutez la requête GraphQL
  final res = await FindsApiClient.query(
    GraphQLQueries.myDeclarationsQuery,
    variables: const {
      'pagination': {'page': 1, 'pageSize': 50},
    },
  );

  // 3. Récupérez la liste de données
  final myDec = res.data?['myDeclarations'];
  final List list = myDec is Map ? (myDec['data'] as List? ?? []) : [];

  // 4. Transformez chaque élément en Map UI pour l'affichage
  ...
}
```

---

### Défi 2 (Niveau Intermédiaire) : Valider la création dans `LostDocumentStep3View`

Dans [`lib/presentation/views/declaration/lost_document_step3_view.dart`](file:///home/k-b17/finds/lib/presentation/views/declaration/lost_document_step3_view.dart) :

1. Construisez l'input GraphQL à partir des données de l'étape 1 et 2 :
```dart
final result = await FindsApiClient.mutate(
  GraphQLQueries.createDeclarationMutation,
  variables: {
    'input': {
      'type': 'PERTE',
      'typeDocument': 'CNI', // ou normalisé via votre fonction
      'nomProprietaire': dec.lastName,
      'prenomProprietaire': dec.firstName,
      'numeroDocument': dec.documentNumber,
      'ville': dec.lossLocation.isNotEmpty ? dec.lossLocation : 'Lomé',
      'source': 'MOBILE',
    },
  },
);
```

2. Déclenchez l'actualisation automatique :
```dart
// Dès que la mutation réussit :
FindsApiClient.declarationsRevision.value++;
```
Grâce à ce `ValueNotifier`, l'onglet **Mes Déclarations** se rafraîchit immédiatement sans recharger l'app !

---

### Défi 3 (Niveau Avancé) : Téléverser la photo avant la déclaration

Si l'utilisateur a pris une photo à l'étape 2 :
1. Envoyez l'image via [`PhotoUploadService`](file:///home/k-b17/finds/lib/core/services/photo_upload_service.dart) :
```dart
String? uploadedPhotoUrl;
if (dec.photoFile != null) {
  uploadedPhotoUrl = await PhotoUploadService.uploadImageFile(dec.photoFile!);
}
```
2. Injectez `uploadedPhotoUrl` dans le champ `photoUrl` de `CreateDeclarationInput`.

---

## 4. Comment tester vos modifications ?

Lancez la suite de tests automatique pour vérifier que votre code dialogue sans erreur avec l'API :

```bash
cd /home/k-b17/finds
flutter test test/api_live_connection_test.dart
```

Ce test effectue une véritable requête HTTPS vers `https://nye-agbale.vercel.app/api/graphql` et confirme la réponse du serveur.

---

## 5. Le jour du déploiement

Lorsque vous aurez déployé votre propre instance de l'API :
1. Ouvrez [`lib/core/config/api_config.dart`](file:///home/k-b17/finds/lib/core/config/api_config.dart) ;
2. Remplacez :
```dart
static const String defaultBaseUrl = 'https://votre-domaine.com';
```
Toutes vos déclarations seront alors automatiquement envoyées sur votre propre infrastructure !
