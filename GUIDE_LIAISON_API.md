# GUIDE — Faire la liaison App Flutter ↔ API GraphQL soi-même

> **But de ce guide :** que tu puisses refaire, seul, le lien entre l'application
> Finds et son API, comprendre chaque étape, puis changer ce lien le jour du
> déploiement.
>
> **Ce qui a été fait pour toi :** le design de l'app, le client GraphQL de base,
> les requêtes, et une grosse partie des écrans. **Ce que tu vas faire :** la
> page **Accueil** a été volontairement débranchée. C'est ta page d'exercice.
>
> **Temps estimé :** 30 min pour lire, 1 h 30 pour rebrancher l'Accueil,
> 1/2 journée pour le déploiement complet.

> 🟢 **État au 09/11/2026 :** la liaison avec l'API est terminée pour tout le
> parcours citoyen. Voir § 5.7 et § 6.3 pour le détail et ce qui reste.

---

## Sommaire

1. [La carte du système](#1-la-carte-du-système)
2. [Où mettre le lien vers l'API](#2-où-mettre-le-lien-vers-lapi)
3. [Le trajet d'une donnée (théorie)](#3-le-trajet-dune-donnée-théorie)
4. [**TA PAGE RÉSERVÉE : l'Accueil**](#4-ta-page-réservée-laccueil)
5. [La même recette pour les autres pages](#5-la-même-recette-pour-les-autres-pages)
6. [Vérifier que TOUT est lié](#6-vérifier-que-tout-est-lié)
7. [Après le déploiement](#7-après-le-déploiement)
8. [Dépannage](#8-dépannage)
9. [Sécurité](#9-sécurité)
10. [Ma page — journal de liaison](#10-ma-page--journal-de-liaison)

---

## Niveaux de difficulté

| Niveau | Symbole | Ce que tu fais | Durée |
|---|---|---|---|
| 1 | ⭐ | Comprendre, changer l'URL, lancer l'API | 30 min |
| 2 | ⭐⭐ | Rebrancher l'Accueil (exercice principal) | 1 h – 1 h 30 |
| 3 | ⭐⭐⭐ | Brancher Notifications / Messages / Profil | 2 h – 4 h |
| 4 | ⭐⭐⭐⭐ | Déployer l'API et pointer l'app dessus | 1/2 journée |

Progression conseillée : **1 → 2 → vérifier → 3 → 4**. Ne saute pas le niveau 2 :
c'est le même mécanisme partout, et c'est celui que tu referas le plus souvent.

---

## 1. La carte du système

```
┌─────────────────────────────────┐         ┌─────────────────────────────────┐
│  APP FLUTTER (finds)            │         │  API CLOUD (nye-agbale / Vercel)│
│                                 │  HTTPS  │                                 │
│  écran (Widget)                 │ ──────► │  Next.js / GraphQL Route        │
│    │                            │  POST   │    │                            │
│    │ appelle                    │/api/    │    │ resolver (auth, declaration│
│    ▼                            │ graphql │    ▼              matches, chat)│
│  FindsApiClient                 │ ◄────── │  Prisma ORM + PostgreSQL        │
│    (lib/core/api/)              │  JSON   │    │                            │
│    │                            │         │    ▼                            │
│    │ URL depuis                 │         │  BullMQ + Redis (Matching IA)   │
│    ▼                            │         │    │                            │
│  ApiConfig                      │         │    ▼                            │
│  (lib/core/config/)             │         │  UploadThing (/api/upload-mobile│
│  = https://nye-agbale.vercel.app│         │                                 │
└─────────────────────────────────┘         └─────────────────────────────────┘
```

Trois choses seulement font « le lien » :

1. **Une URL de base** : `https://nye-agbale.vercel.app` (définie dans `ApiConfig`, que tu remplaceras par l'URL de ton propre serveur une fois déployé) ;
2. **Un token JWT d'accès** : renvoyé par `login` ou `register` (`accessToken`), ajouté automatiquement dans le header `Authorization: Bearer …`, et rafraîchi via `refreshToken` ;
3. **Des requêtes/mutations GraphQL** : centralisées dans `lib/core/api/graphql_queries.dart` selon le schéma officiel de RetrouveTout (`citizen-connect-mobile/graphql/schema.graphql`).

---

## 2. Où mettre le lien vers l'API

### 2.1 Le seul fichier à modifier

📄 **`lib/core/config/api_config.dart`**

C'est ici, et **nulle part ailleurs**, que se trouve l'adresse de l'API.
Aucun autre fichier ne doit contenir `http://` ou `https://`.

```dart
class ApiConfig {
  // 1) URL de base active → À REMPLACER après ton déploiement
  static const String defaultBaseUrl = 'https://nye-agbale.vercel.app';

  // 2) Surcharge possible au lancement ou en CI :
  // flutter run --dart-define=API_URL=https://mon-api.vercel.app
  static const String _envUrl = String.fromEnvironment('API_URL');

  static String get baseUrl => _envUrl.isNotEmpty ? _envUrl : defaultBaseUrl;

  // 3) Points d'accès déduits automatiquement :
  static String get graphqlEndpoint => '$baseUrl/api/graphql';
  static String get uploadEndpoint => '$baseUrl/api/upload-mobile';
}
```

### 2.2 Quelle URL pour quel cas ?

| Situation | URL de base | Pourquoi |
|---|---|---|
| **Actuellement (Prêt à l'emploi)** | `https://nye-agbale.vercel.app` | API cloud active immédiatement sur émulateur, téléphone et PC |
| **Après ton déploiement Vercel** | `https://ton-projet.vercel.app` | Remplace `defaultBaseUrl` dans `api_config.dart` |
| **Après ton déploiement VPS/Docker** | `https://api.tondomaine.com` | HTTPS obligatoire pour mobile |
| **En local (si tu lances l'API sur PC)** | `http://10.0.2.2:4000` (Android) ou `http://localhost:4000` | Machine hôte locale |

### 2.3 Comment faire la bascule après déploiement

Le jour où tu déploies ta propre API :
1. Ouvre `lib/core/config/api_config.dart` ;
2. Modifie la constante `defaultBaseUrl` :
   ```dart
   static const String defaultBaseUrl = 'https://ton-nouveau-serveur.com';
   ```
3. C'est tout ! L'ensemble de l'application (authentification, déclarations, matching, recherche, upload de photos) pointera instantanément sur ton nouveau serveur.

⚠️ `String.fromEnvironment` est une constante de compilation : un **hot reload**
ne suffit pas. Il faut relancer `flutter run` (ou refaire le build).

**C. Modifier `productionUrl`** — utile si tu veux un build release « par défaut »
sans passer d'option. Remplace la valeur, rebuild, terminé.

### 2.4 Comment vérifier que le lien est pris en compte

Au démarrage, la console Flutter affiche :

```
[FindsApiClient] Client GraphQL initialisé (debug) vers http://10.0.2.2:4000/graphql
```

C'est la ligne à regarder en priorité quand « rien ne marche ». Elle vient de
`lib/core/api/graphql_client.dart`.

### 2.5 Où le client est initialisé

📄 **`lib/main.dart`**

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FindsApiClient.initialize();   // ← lit ApiConfig et crée le client
  runApp(const FindsApp());
}
```

Le client (`lib/core/api/graphql_client.dart`) fait trois choses :

- il crée un `HttpLink(endpoint)` ;
- il ajoute un `AuthLink` qui met le token dans le header ;
- il expose deux fonctions pratiques : `FindsApiClient.query(...)` et
  `FindsApiClient.mutate(...)`.

---

## 3. Le trajet d'une donnée (théorie)

Pour l'écran Accueil, voici ce qui doit se passer **dans cet ordre** :

```
1. L'utilisateur se connecte
   LoginView → FindsApiClient.mutate(loginMutation)
   → l'API renvoie { token, user }
   → FindsApiClient.authToken.value = token        (gardé en mémoire)
   → FindsApiClient.currentUser.value = user

2. L'écran Accueil s'affiche
   initState() → _fetchDashboardData()

3. La requête part
   FindsApiClient.query(GraphQLQueries.dashboardQuery)
   → gql(...) transforme le texte en document GraphQL
   → AuthLink ajoute « Authorization: Bearer <token> »
   → POST http://…/graphql

4. L'API répond
   resolver dashboard → Prisma → PostgreSQL
   → JSON : { data: { dashboard: { … } } }

5. L'écran se met à jour
   setState(() { _declarationsCount = …; })
   → build() relancé
   → les KPI affichent les nouvelles valeurs
```

### Le token, points importants

- Il est gardé en mémoire dans `FindsApiClient.authToken` **et** sauvegardé sur
  le téléphone (`shared_preferences`, mêmes clés que citizen : `@auth_access_token`,
  `@auth_refresh_token`, `@auth_user`).
- Au démarrage, `FindsApiClient.restoreSession()` le recharge : l'utilisateur
  reste connecté.
- S'il expire, `FindsApiClient` appelle `refreshToken` puis rejoue la requête.
  Si le refresh échoue (ou `ACCOUNT_DISABLED`), la session est vidée et l'app
  revient sur `LoginView`.
- Après un login/register, toujours appeler `FindsApiClient.signIn(...)`.
  **On ne met jamais d'email/mot de passe en dur dans un écran.**

### Lire une réponse GraphQL

```dart
final res = await FindsApiClient.query(GraphQLQueries.dashboardQuery);

// 1. Erreur réseau ou GraphQL ?
if (res.hasException) {
  debugPrint('Erreur API : ${res.exception}');
  return;
}

// 2. Les données (toujours avec ? et ?? car le JSON peut être incomplet)
final data = res.data?['dashboard'];
if (data == null) return;

final int declarations = data['declarationsCount'] as int? ?? 0;
```

---

## 4. TA PAGE RÉSERVÉE : l'Accueil

> ✅ **Mise à jour 09/11/2026 :** l'Accueil est désormais branché (via
> `myDeclarations` + `myNotifications`, car `dashboard` n'existe pas dans l'API).
> Cette section reste comme support d'apprentissage du motif `token → query → setState`.

> **C'est ici que tu apprends.** J'ai retiré la liaison réseau de
> `HomeDashboardView`. Le design est intact, les données affichées sont des
> valeurs de démo. À toi de les remplacer par les vraies.

📄 **`lib/presentation/views/home/home_dashboard_view.dart`**
Fonction à remplir : `_fetchDashboardData()` (vers la ligne 60).
Requête à utiliser : `GraphQLQueries.dashboardQuery`
(`lib/core/api/graphql_queries.dart`).

### 4.1 Le contrat de l'API

```graphql
query Dashboard {
  dashboard {
    declarationsCount
    matchesCount
    restoredCount
    unreadNotificationsCount
    recentActivity {
      id
      type          # "match" | "message" | "restitution" | ...
      title
      subtitle
      tabTarget     # 1 = Déclarations, 2 = Matches, 3 = Messages
      createdAt
    }
  }
}
```

Réponse réelle de l'API de démo (vérifiée) :

```json
{
  "dashboard": {
    "declarationsCount": 5,
    "matchesCount": 5,
    "restoredCount": 1,
    "unreadNotificationsCount": 5,
    "recentActivity": [
      {
        "id": "6",
        "type": "match",
        "title": "Nouveau match trouvé pour votre CNI",
        "subtitle": "Correspondance à 100% — vérifiez le dossier",
        "tabTarget": 2,
        "createdAt": "2026-11-02T10:47:44.372Z"
      }
    ]
  }
}
```

### 4.2 Avant de coder : démarrer l'API

Niveau ⭐ — à faire une fois par session de travail.

```bash
# Terminal 1 — la base de données doit tourner
sudo service postgresql status

# Terminal 2 — l'API
cd ~/finds-api
npm run dev
# → 🚀 API Finds prête sur http://localhost:4000/graphql
```

Vérification rapide (dans un 3e terminal) :

```bash
curl -s http://localhost:4000/ 
# ✅ API Finds en ligne ! Endpoint GraphQL : /graphql

cd ~/finds-api && npm run test:api     # test complet de bout en bout
```

### 4.3 Étape 1 — Remettre les imports (⭐)

En haut de `home_dashboard_view.dart`, ajoute :

```dart
import '../../../core/api/graphql_client.dart';
import '../../../core/api/graphql_queries.dart';
```

### 4.4 Étape 2 — Vérifier l'authentification (⭐⭐)

Pas de login en dur. Si l'utilisateur n'est pas connecté, on ne tente pas la
requête : on le renvoie vers l'écran de connexion.

```dart
Future<void> _fetchDashboardData() async {
  if (FindsApiClient.authToken.value == null) {
    debugPrint('[Accueil] Pas de token : utilisateur non connecté.');
    // Option simple pour l'exercice : on garde les valeurs de démo.
    // Option propre (à faire au niveau 3) : rediriger vers LoginView.
    return;
  }

  // …
}
```

> 💡 Pourquoi c'est important : l'ancienne version faisait un « auto-login » avec
> un email et un mot de passe écrits en clair dans 5 fichiers. C'est pratique en
> démo, **dangereux en vrai**. Voir § 9.

### 4.5 Étape 3 — Lancer la requête et remplir les KPI (⭐⭐)

```dart
  setState(() => _isLoading = true);   // ajoute ce booléen si tu veux un spinner

  try {
    final res = await FindsApiClient.query(GraphQLQueries.dashboardQuery);

    if (res.hasException) {
      debugPrint('[Accueil] Erreur API : ${res.exception}');
      return;
    }

    final d = res.data?['dashboard'];
    if (d == null) return;

    if (!mounted) return;              // l'écran a pu être fermé pendant l'appel
    setState(() {
      _declarationsCount = d['declarationsCount'] as int? ?? 0;
      _matchesCount      = d['matchesCount']      as int? ?? 0;
      _restoredCount     = d['restoredCount']     as int? ?? 0;
      _isLoading = false;
    });
  } catch (e) {
    debugPrint('[Accueil] Exception : $e');
    if (mounted) setState(() => _isLoading = false);
  }
```

Déclare `bool _isLoading = false;` dans le `State` si tu utilises le spinner.
Tu peux aussi l'utiliser dans les KPI (`_isLoading ? '…' : '$_declarationsCount'`).

**Point de contrôle :** relance l'app, connecte-toi, l'Accueil doit afficher
**5 / 5 / 1** (et non plus 2 / 3 / 1).

### 4.6 Étape 4 — L'activité récente depuis l'API (⭐⭐)

Aujourd'hui, `_buildPopulatedActivityList()` contient 3 cartes écrites en dur.
Objectif : une liste générée depuis `recentActivity`.

**a)** Ajoute un champ dans le `State` :

```dart
List<Map<String, dynamic>> _activities = [];
```

**b)** Dans le `setState` de l'étape 3 :

```dart
_activities = List<Map<String, dynamic>>.from(d['recentActivity'] ?? []);
```

**c)** Transforme la liste en widgets. Le composant `_buildActivityItem(...)`
existe déjà et accepte : `icon`, `iconBg`, `iconColor`, `title`, `subtitle`,
`time`, `timeColor`, `hasNotificationDot`, `onTap`.

```dart
Widget _buildPopulatedActivityList() {
  return Column(
    children: [
      for (int i = 0; i < _activities.length; i++) ...[
        if (i > 0) const SizedBox(height: 10),
        _buildActivityItem(
          icon: _iconForType(_activities[i]['type'] as String?),
          iconBg: const Color(0xFFE8F5E9),
          iconColor: AppColors.primary,
          title: _activities[i]['title'] as String? ?? '',
          subtitle: _activities[i]['subtitle'] as String? ?? '',
          time: _relativeTime(_activities[i]['createdAt'] as String?),
          onTap: () => widget.onNavigateToTab
              ?.call(_activities[i]['tabTarget'] as int? ?? 0),
        ),
      ],
    ],
  );
}
```

**d)** Deux petites fonctions à écrire (niveau ⭐⭐) :

```dart
IconData _iconForType(String? type) {
  switch (type) {
    case 'message':     return Icons.chat_bubble_outline_rounded;
    case 'restitution': return Icons.task_alt_rounded;
    case 'match':
    default:            return Icons.find_in_page_rounded;
  }
}

String _relativeTime(String? iso) {
  if (iso == null) return '';
  final date = DateTime.tryParse(iso);
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
  if (diff.inHours   < 24) return 'Il y a ${diff.inHours} h';
  return 'Il y a ${diff.inDays} j';
}
```

### 4.7 Étape 5 — Le vrai état vide (⭐⭐)

Le booléen `_showEmptyState` ne sert qu'à la démo (le petit switch en haut de
l'écran). Dans une vraie app, l'état vide se déduit des données :

```dart
// Remplace :
if (_showEmptyState) _buildEmptyActivityState() else _buildPopulatedActivityList(),

// Par :
if (_activities.isEmpty) _buildEmptyActivityState() else _buildPopulatedActivityList(),
```

Ensuite, **supprime le switch de démo** (`_buildDemoStateToggle()` et son appel
dans `build`) : il n'a plus de raison d'être en production.

Pour tester l'état vide : connecte-toi avec le compte
`ama.koffi@mail.fr` / `Password123` (`recentActivity` est vide pour ce compte)
ou commente temporairement `_activities = …`.

### 4.8 Étape 6 — Les cas d'erreur (⭐⭐)

Trois états à gérer, pas seulement « ça marche » :

| État | Ce que l'utilisateur voit |
|---|---|
| chargement | les KPI affichent `…` ou un petit spinner |
| succès | les chiffres réels |
| erreur réseau | valeurs de démo + message discret, ou bouton « Réessayer » |

Teste en coupant l'API (`Ctrl+C` dans le terminal `npm run dev`) puis en
relançant l'app : **elle ne doit pas planter**.

### 4.9 Critères de réussite de l'exercice

- [ ] `flutter analyze` ne renvoie aucune erreur.
- [ ] Les KPI affichent **5 / 5 / 1** avec l'API de démo.
- [ ] L'activité récente vient de `recentActivity` (plus de texte en dur).
- [ ] Cliquer une activité ouvre le bon onglet (`tabTarget`).
- [ ] La liste vide affiche `_buildEmptyActivityState()`.
- [ ] API coupée → aucun crash, message dans la console.
- [ ] Aucun email/mot de passe en dur dans le fichier.

> ✅ Quand tout est vert, tu maîtrises le motif `token → query → data → setState`.
> C'est **exactement** le même pour les 4 autres pages.

---

## 5. La même recette pour les autres pages

Toutes les requêtes existent déjà dans `lib/core/api/graphql_queries.dart`, mais
toutes ne sont pas encore branchées côté app. Voici la recette, par difficulté.

### 5.1 Notifications — ⭐⭐ (30–45 min)

📄 `lib/presentation/views/notifications/notifications_list_view.dart`
La liste `_notifications` est en dur. L'API est prête.

1. Ajoute `import '../../../core/api/graphql_client.dart';` et `graphql_queries.dart`.
2. Ajoute la requête dans `graphql_queries.dart` :

```graphql
query Notifications {
  notifications {
    id
    category      # MATCH | MESSAGE | RESTITUTION | ALERT
    title
    description
    badge
    tabTarget
    isRead
    createdAt
  }
}
```

3. Dans `initState`, appelle `_fetchNotifications()`.
4. Mappe chaque item vers ton `Map<String, dynamic>` actuel
   (`category` en minuscules, `time` calculé depuis `createdAt`…).
5. « Tout marquer comme lu » → `markAllNotificationsRead` (mutation) au lieu de
   modifier la liste locale.
6. Le badge de la cloche de l'Accueil (`badgeCount: 2`) doit venir de
   `dashboard.unreadNotificationsCount`.

### 5.2 Messages / Chat — ⭐⭐⭐ (1–2 h)

📄 `conversations_list_view.dart` et `chat_conversation_view.dart`.
Tout est mock. L'API fournit `conversations`, `conversation(id)`, `sendMessage`,
et même un abonnement temps réel `messageSent`.

1. `conversations { id unreadCount lastMessage { text createdAt } participants { fullName } }`
2. Au clic → `ChatConversationView(conversationId: …)`.
3. Envoyer → mutation `sendMessage(conversationId, text)`.
4. Temps réel (bonus) : `Subscription` GraphQL via `graphql_flutter`.

### 5.3 Profil — ⭐⭐ (45 min)

📄 `profile_view.dart` / `edit_profile_view.dart`. Les infos sont codées en dur
(`Bénédicte DOFOR`). L'API fournit `me` et `updateProfile`.

1. Remplis l'en-tête depuis `FindsApiClient.currentUser.value` (déjà disponible
   après le login) ou `query me`.
2. « Enregistrer » → `mutation updateProfile(input: …)` puis mets à jour
   `FindsApiClient.currentUser.value`.
3. Les stats (2 / 3 / 1) doivent venir de `dashboard`.
4. « Se déconnecter » doit appeler `FindsApiClient.logout()` **avant** de
   naviguer vers `LoginView` (ce n'est pas fait aujourd'hui).

### 5.4 Matches — ⭐⭐ (45 min)

📄 `matches_list_view.dart`. La liste est branchée ✅, mais les actions sont
fictives (simple `SnackBar`) :

- « Valider restitution » → `mutation validateRestitution(matchId)` ;
- « Écarter » → `mutation rejectMatch(matchId)` ;
- recharge la liste après succès (`_fetchMatches()`).

### 5.5 Recherche — ⭐⭐ (30 min)

📄 `document_search_view.dart`. La recherche est branchée ✅. Il manque
`reportDocument(declarationId)` pour le bouton « C'est mon document ».

### 5.6 Mot de passe oublié — ⭐⭐⭐ (backend à compléter)

📄 `forgot_password_view.dart` : `_handleSendLink()` fait juste un
`Future.delayed` (simulation). L'API n'a **pas** de mutation « envoyer un lien ».
Il faut d'abord l'ajouter côté `finds-api` (nouveau champ + envoi d'email), puis
brancher l'écran. C'est un exercice full-stack.

### 5.7 Récapitulatif (mis à jour le 09/11/2026)

| Fonctionnalité | Côté API | Côté app | Requête(s) |
|---|---|---|---|
| Login / Register | ✅ | ✅ | `login`, `register` |
| Session persistée + refresh token | ✅ | ✅ | `refreshToken` |
| Déconnexion serveur | ✅ | ✅ | `logout` |
| Accueil (KPI, badge, activité) | ✅ | ✅ | `myDeclarations`, `myNotifications` |
| Déclarations (liste, restitution) | ✅ | ✅ | `myDeclarations`, `markDeclarationResolved` |
| Créer perdu / trouvé (+ photo, ville/quartier) | ✅ | ✅ | `createDeclaration`, `/api/upload-mobile`, `villes` |
| Recherche (toutes les pages, numéros masqués) | ✅ | ✅ | `searchDeclarations` |
| « C'est mon document / Je l'ai » | ✅ | ✅ | ouvre la déclaration inverse pré-remplie (matching serveur) |
| Matches : liste, confirmer, rejeter | ✅ | ✅ | `declarationMatches`, `confirmMatch`, `rejectMatch` |
| Messagerie / chat | ✅ | ✅ | `myConversations`, `conversation`, `sendMessage`, `markConversationRead` |
| Évaluation après restitution | ✅ | ✅ | `createEvaluation` |
| Notifications | ✅ | ✅ | `myNotifications`, `markNotificationRead`, `markAllNotificationsRead` |
| Profil / modifier / mot de passe | ✅ | ✅ | `me`, `updateUser`, `changePassword` |
| Mode hors-ligne (dernières réponses) | — | ✅ | cache local `shared_preferences` |
| Mot de passe oublié | ❌ | ❌ (simulé) | mutation à créer côté serveur |
| Connexion Google / Apple | ❌ | retirée | à créer côté serveur |
| Notifications push | ✅ | ❌ | `registerPushToken` + Firebase à configurer |
| Temps réel (subscription) | ✅ | ❌ (polling 10 s dans le chat) | — |

> ⚠️ La requête `matches` est **réservée aux admins** et `dashboard` **n'existe pas**
> dans le schéma : ne pas les utiliser côté citoyen.

## 6. Vérifier que TOUT est lié

### 6.1 Les commandes de vérification

```bash
# Dans ~/finds (l'app)
flutter analyze          # 0 erreur attendue
flutter test             # tests d'interface

# Dans ~/finds-api (l'API)
npm run check:schema     # cohérence schéma ↔ resolvers
npm run test:api         # vrais appels GraphQL de bout en bout
```

### 6.2 Test manuel complet (10 min)

1. API démarrée, base seedée (`npm run db:seed` si besoin).
2. Lancer l'app, se connecter avec `dofor.benedicte@gmail.com` / `Password123`.
3. Accueil : KPI = 5 / 5 / 1 (après ton exercice).
4. Déclarations : la liste vient de l'API (5 éléments).
5. Recherche : taper « CNI » → résultats de l'API.
6. Matches : la liste vient de l'API.
7. Couper l'API → l'app ne plante pas, messages d'erreur propres.
8. Regarder la console : l'URL affichée est la bonne.

### 6.3 Résultat de l'audit (mis à jour le 09/11/2026)

**Branché sur l'API :** tout le parcours citoyen (voir tableau § 5.7).
Les 30 requêtes de `graphql_queries.dart` sont validées contre
`citizen-connect-mobile/graphql/schema.graphql`, sauf `resetPasswordMutation`
(la mutation n'existe pas côté serveur).

**Corrigé depuis la première version :**

- auto-login avec mot de passe en dur supprimé ;
- les erreurs de création de déclaration sont affichées (plus de faux « succès ») ;
- le token est persisté et restauré au démarrage, puis rafraîchi automatiquement ;
- la déconnexion appelle `logout` et vide session + cache ;
- badges et compteurs viennent de l'API ;
- les numéros de document sont masqués à l'affichage (`maskDocumentNumber`).

**Reste à faire (dépend du serveur ou d'un service externe) :**

- ❌ mot de passe oublié : ajouter une mutation + envoi d'e-mail dans l'API ;
- ❌ connexion Google / Apple : à implémenter côté API ;
- ❌ notifications push : créer un projet Firebase, ajouter `firebase_messaging`,
  puis appeler `registerPushToken` après le login ;
- ⚠️ masquage des numéros : fait dans l'app seulement ; pour une vraie
  confidentialité, l'API `searchDeclarations` devrait renvoyer le numéro déjà masqué.

## 7. Après le déploiement

> Niveau ⭐⭐⭐⭐. Objectif : l'API tourne sur un serveur public en HTTPS, et
> l'app installée sur un téléphone parle à cette API.

### 7.1 Déployer l'API (côté serveur)

Prérequis : un VPS Ubuntu, un nom de domaine (ex. `api.tondomaine.com`), Node 20+,
PostgreSQL.

```bash
# 1. Récupérer le code
cd /var/www
git clone <ton-depot> finds-api
cd finds-api

# 2. Dépendances
npm ci

# 3. Configuration : créer .env à partir du modèle
cp .env.example .env
nano .env
```

Contenu **production** du `.env` :

```ini
DATABASE_URL="postgresql://finds:MotDePasseFort@127.0.0.1:5432/findsdb?schema=public"
JWT_SECRET="<openssl rand -hex 32>"
JWT_EXPIRES_IN="7d"
PORT=4000
CORS_ORIGIN="https://app.tondomaine.com"
```

Générer le secret :

```bash
openssl rand -hex 32
```

Puis :

```bash
# 4. Base de données
npx prisma generate
npm run db:push          # 1er déploiement (le projet n'a pas encore de migrations)
# Plus tard, quand tu auras des migrations : npm run db:deploy

# 5. Compiler et démarrer
npm run build
NODE_ENV=production npm start
```

> 💡 Pour que l'API reste allumée après ta déconnexion SSH, utilise **pm2** :
>
> ```bash
> npm i -g pm2
> pm2 start dist/src/main.js --name finds-api
> pm2 save && pm2 startup
> ```
>
> ou un service `systemd` (plus « système ») :
>
> ```ini
> [Unit]
> Description=Finds API
> After=network.target postgresql.service
>
> [Service]
> WorkingDirectory=/var/www/finds-api
> EnvironmentFile=/var/www/finds-api/.env
> ExecStart=/usr/bin/npm start
> Restart=always
> User=www-data
>
> [Install]
> WantedBy=multi-user.target
> ```

### 7.2 Mettre du HTTPS (obligatoire)

Android et iOS **bloquent le HTTP en release**. Il faut un reverse proxy Nginx +
un certificat.

```nginx
# /etc/nginx/sites-available/finds-api
server {
    server_name api.tondomaine.com;

    location /graphql {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Upgrade $http_upgrade;      # WebSocket (chat)
        proxy_set_header Connection "upgrade";
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/finds-api /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d api.tondomaine.com   # HTTPS + renouvellement auto
```

Pare-feu : n'ouvre que 22, 80 et 443. Le port 4000 reste **interne**.

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

Vérification depuis n'importe où :

```bash
curl https://api.tondomaine.com/
# ✅ API Finds en ligne ! Endpoint GraphQL : /graphql
```

### 7.3 Pointer l'app vers l'API en ligne

Deux options (choisis-en une) :

**Option A — recommandée : au moment du build**

```bash
flutter build apk --release \
  --dart-define=API_URL=https://api.tondomaine.com/graphql

flutter build appbundle --release \
  --dart-define=API_URL=https://api.tondomaine.com/graphql

flutter build ios --release \
  --dart-define=API_URL=https://api.tondomaine.com/graphql

flutter build web --release \
  --dart-define=API_URL=https://api.tondomaine.com/graphql
```

**Option B — en dur dans le code**

Modifie `productionUrl` dans `lib/core/config/api_config.dart`, puis build normal.
Rappelle-toi : en **release**, c'est cette URL qui est utilisée automatiquement.

> ⚠️ Ne teste pas avec `flutter run --release` en oubliant `--dart-define` : tu
> pointerais vers `productionUrl`, qui est un domaine d'exemple.

### 7.4 Les pièges de plateforme (déjà anticipés)

| Plateforme | Problème | Solution |
|---|---|---|
| Android release | pas de permission Internet → toutes les requêtes échouent | ✅ **déjà corrigé** : `<uses-permission android:name="android.permission.INTERNET"/>` ajouté dans `android/app/src/main/AndroidManifest.xml` |
| Android 9+ | HTTP bloqué | HTTPS en prod ; en debug local, `usesCleartextTraffic` est activé dans `android/app/src/debug/AndroidManifest.xml` |
| iOS | ATS bloque le HTTP | HTTPS en prod ; pour tester en local, ajoute `NSAllowsLocalNetworking` dans `ios/Runner/Info.plist` |
| Web | erreur CORS | mets `CORS_ORIGIN="https://app.tondomaine.com"` côté API (ou `*` en test) |
| Téléphone réel | `localhost` = le téléphone | utilise l'IP du PC (debug) ou le domaine public (prod) |

### 7.5 Checklist du jour J

**API**

- [ ] `curl https://api.tondomaine.com/` répond ✅
- [ ] `JWT_SECRET` changé (pas celui du dépôt)
- [ ] `DATABASE_URL` pointe sur la base de prod
- [ ] base migrée / seedée si démo
- [ ] `CORS_ORIGIN` configuré
- [ ] Nginx + HTTPS OK (cadenas)
- [ ] API relancée automatiquement (pm2/systemd)
- [ ] sauvegarde PostgreSQL planifiée

**App**

- [ ] `--dart-define=API_URL=https://…` passé au build
- [ ] `flutter analyze` = 0 erreur
- [ ] login réel testé sur un téléphone **en 4G** (pas seulement Wi-Fi)
- [ ] Accueil, Déclarations, Recherche, Matches OK
- [ ] API coupée → message propre, pas de crash
- [ ] version `pubspec.yaml` incrémentée
- [ ] APK/AAB signé (keystore de release)
- [ ] test d'installation depuis le store (ou l'APK) sur un appareil vierge

### 7.6 Que se passe-t-il si je change d'URL plus tard ?

Trois endroits seulement peuvent contenir l'URL :

1. `lib/core/config/api_config.dart` → `productionUrl` (si tu l'utilises) ;
2. la commande de build `--dart-define=API_URL=…` ;
3. la variable `CORS_ORIGIN` côté serveur (ce n'est pas l'URL de l'app, mais
   elle doit autoriser le domaine de l'app web).

Un changement d'URL = **un nouveau build** de l'app. On ne peut pas modifier
l'URL d'une app déjà installée sans passer par le store (sauf si tu ajoutes un
écran de configuration ou un fichier de config distant — exercice avancé).

---

## 8. Dépannage

| Symptôme | Cause probable | Solution |
|---|---|---|
| `Serveur API inaccessible` | API pas démarrée / mauvaise URL | `cd ~/finds-api && npm run dev`, vérifier le log `[FindsApiClient] … vers …` |
| `Connection refused` sur émulateur | URL `localhost` au lieu de `10.0.2.2` | laisser l'auto-config, ou `--dart-define` avec `10.0.2.2` |
| `Connection refused` sur téléphone | `localhost` ou mauvaise IP | IP du PC + même Wi-Fi + `ufw allow 4000/tcp` en test |
| `Non authentifié` | token absent/expiré | se reconnecter ; vérifier `FindsApiClient.authToken.value` |
| `Erreur CORS` (web) | origine non autorisée | `CORS_ORIGIN` côté API |
| Écran figé sur « chargement » | `setState` jamais appelé / exception avalée | regarder la console, ajouter `debugPrint` |
| Données vides alors que l'API répond | mauvaise clé (`data['x']` au lieu de `data['dashboard']['x']`) | relire le contrat § 4.1 |
| `flutter analyze` râle après ton code | import inutilisé / `BuildContext` après `await` | `if (!mounted) return;`, supprimer les imports |
| L'app affiche encore les données de démo | tu as oublié `setState` ou l'appel dans `initState` | vérifier `_fetchDashboardData()` |
| Release Android sans réseau | permission Internet manquante | ✅ déjà corrigé (vérifier le manifeste merged) |

---

## 9. Sécurité

Les 6 règles à respecter dès que tu touches à la liaison :

1. **Jamais d'identifiants en dur dans l'app.** Aujourd'hui, `Password123` est
   écrit dans 4 écrans (auto-login de secours). Supprime ces blocs : le login
   normal remplit déjà `authToken`. Un APK se décompile très facilement.
2. **Aucun secret dans le code Flutter.** Clé JWT, mot de passe DB, clés d'API :
   uniquement côté serveur (`.env`, jamais commité). Le `.env` de `finds-api` est
   déjà dans `.gitignore`.
3. **HTTPS partout en production.** HTTP = token lisible sur le réseau.
4. **Stocker le token proprement.** Aujourd'hui il est en mémoire (perdu au
   redémarrage). Pour la prod : `flutter_secure_storage`, puis restauration
   silencieuse au démarrage et rafraîchissement du token.
5. **Valider côté serveur.** Ne jamais faire confiance au client : l'API doit
   vérifier les droits (`isMine`, propriétaire de la déclaration, etc.).
6. **Messages d'erreur utiles mais sobres.** En prod, ne renvoie pas la stack
   trace au client (`includeStacktraceInErrorResponses` est déjà conditionné à
   `NODE_ENV`).

---

## 10. Ma page — journal de liaison

> Cette page est **à toi**. Écris ce que tu as fait, ce qui a bloqué, et la
> solution. C'est ce qui te fera progresser le plus vite.

### Mon objectif

- [ ] Niveau 1 : je sais où est l'URL et je sais la changer.
- [ ] Niveau 2 : j'ai rebranché l'Accueil seul(e).
- [ ] Niveau 3 : j'ai branché une 2e page (notifications ou profil).
- [ ] Niveau 4 : l'app installée parle à l'API en ligne.

### Mes notes

| Date | Ce que j'ai fait | Ce qui a bloqué | Solution trouvée |
|---|---|---|---|
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |

### Mes questions ouvertes

1.
2.
3.

### Ma commande de build de production (à recopier ici)

```bash
flutter build appbundle --release \
  --dart-define=API_URL=
```

---

## Annexe A — Les fichiers clés

| Fichier | Rôle |
|---|---|
| `lib/core/config/api_config.dart` | **L'URL de l'API** (le seul endroit) |
| `lib/core/api/graphql_client.dart` | Client GraphQL + token + `query()` / `mutate()` |
| `lib/core/api/graphql_queries.dart` | Toutes les requêtes/mutations GraphQL |
| `lib/main.dart` | `FindsApiClient.initialize()` au démarrage |
| `lib/presentation/views/home/home_dashboard_view.dart` | **Ta page réservée** (exercice § 4) |
| `lib/presentation/views/auth/login_view.dart` | Exemple complet : mutation + token + erreurs |
| `lib/presentation/views/declarations/declarations_list_view.dart` | Exemple complet : query + mapping + liste |
| `../finds-api/src/**/*.typedefs.ts` | Le schéma GraphQL côté serveur |
| `../finds-api/GUIDE_API.md` | Guide détaillé du backend |

## Annexe B — Lexique

- **GraphQL** : langage de requête où le client demande exactement les champs
  qu'il veut, en un seul appel (`POST /graphql`).
- **Query** : lecture de données (`dashboard`, `myDeclarations`…).
- **Mutation** : écriture de données (`login`, `createLostDeclaration`…).
- **Resolver** : fonction serveur qui produit la réponse d'un champ.
- **JWT** : jeton signé qui prouve « je suis connecté » ; envoyé dans
  `Authorization: Bearer <token>`.
- **CORS** : règle du navigateur qui autorise (ou non) le web à appeler une
  autre origine.
- **`--dart-define`** : façon de passer une valeur au moment de la compilation
  Flutter (ici, l'URL de l'API).

---

*Bonne liaison. Si tu bloques plus de 20 minutes sur une étape, relis la section
correspondante du guide avant de changer le code au hasard.*
