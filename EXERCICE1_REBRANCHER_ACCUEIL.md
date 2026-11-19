# 🟡 EXERCICE N°1 — Rebrancher l'Accueil sur l'API

> **Objectif :** remplacer les valeurs de démo de la page Accueil par les
> vraies données de l'API GraphQL.
> **Durée estimée :** 1 h – 1 h 30
> **Référence complète :** `GUIDE_LIAISON_API.md` § 4 (le détail et le
> dépannage sont là-bas, § 8 pour les erreurs)

---

## 1. Où travailler

| | |
|---|---|
| **Fichier à modifier** | `lib/presentation/views/home/home_dashboard_view.dart` |
| **Fonction à remplir** | `_fetchDashboardData()` — **ligne 93** (bloc vide `// TODO(toi)`) |
| **Requête déjà écrite** | `GraphQLQueries.dashboardQuery` dans `lib/core/api/graphql_queries.dart` |
| **Client GraphQL** | `FindsApiClient` dans `lib/core/api/graphql_client.dart` |

> 💡 Le bloc de commentaires **lignes 64-92** du fichier te rappelle les
> 4 étapes en résumé. Ce fichier-ci te donne le code détaillé.

---

## 2. Prérequis — démarrer l'API (1 fois par session)

```bash
# Terminal 1 — la base de données
sudo service postgresql status

# Terminal 2 — l'API
cd ~/finds-api
npm run dev
# → 🚀 API Finds prête sur http://localhost:4000/graphql

# Vérification (Terminal 3)
curl -s http://localhost:4000/
# ✅ API Finds en ligne ! Endpoint GraphQL : /graphql
```

Puis lance l'app :

```bash
cd ~/finds
flutter run
```

---

## 3. Contrat de l'API

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

**Point de contrôle :** une fois branché, l'Accueil doit afficher **5 / 5 / 1**
(et non plus 2 / 3 / 1).

---

## 4. Les 6 étapes

### Étape 1 — Remettre les imports ⭐

En haut de `home_dashboard_view.dart` :

```dart
import '../../../core/api/graphql_client.dart';
import '../../../core/api/graphql_queries.dart';
```

### Étape 2 — Vérifier l'authentification ⭐⭐

Pas de login en dur. Sans token, on ne tente pas la requête :

```dart
Future<void> _fetchDashboardData() async {
  if (FindsApiClient.authToken.value == null) {
    debugPrint('[Accueil] Pas de token : utilisateur non connecté.');
    // Option simple : on garde les valeurs de démo.
    // Option propre (niveau 3) : rediriger vers LoginView.
    return;
  }

  // …la suite ci-dessous
}
```

> ⚠️ L'ancienne version faisait un « auto-login » avec email/mot de passe en
> clair dans 5 fichiers. Pratique en démo, **dangereux en vrai** → voir guide § 9.

### Étape 3 — Lancer la requête et remplir les KPI ⭐⭐

```dart
  setState(() => _isLoading = true);   // ajoute `bool _isLoading = false;` dans le State

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
}
```

Tu peux afficher `…` dans les KPI pendant le chargement :
`_isLoading ? '…' : '$_declarationsCount'`.

### Étape 4 — L'activité récente depuis l'API ⭐⭐

Aujourd'hui `_buildPopulatedActivityList()` contient 3 cartes en dur.
Objectif : une liste générée depuis `recentActivity`.

**a)** Champ dans le `State` :

```dart
List<Map<String, dynamic>> _activities = [];
```

**b)** Dans le `setState` de l'étape 3 :

```dart
_activities = List<Map<String, dynamic>>.from(d['recentActivity'] ?? []);
```

**c)** Remplace le contenu de `_buildPopulatedActivityList()` :

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

**d)** Deux petites fonctions à écrire :

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

### Étape 5 — Le vrai état vide ⭐⭐

Le booléen `_showEmptyState` ne sert qu'à la démo (le switch en haut de
l'écran). Dans la vraie app, l'état vide se déduit des données :

```dart
// Remplace :
if (_showEmptyState) _buildEmptyActivityState() else _buildPopulatedActivityList(),

// Par :
if (_activities.isEmpty) _buildEmptyActivityState() else _buildPopulatedActivityList(),
```

Ensuite, **supprime le switch de démo** (`_buildDemoStateToggle()` + son
appel dans `build`) : il n'a plus de raison d'être en production.

Pour tester l'état vide : connecte-toi avec
`ama.koffi@mail.fr` / `Password123` (`recentActivity` est vide pour ce compte).

### Étape 6 — Les cas d'erreur ⭐⭐

Trois états à gérer, pas seulement « ça marche » :

| État | Ce que l'utilisateur voit |
|---|---|
| chargement | les KPI affichent `…` ou un petit spinner |
| succès | les chiffres réels |
| erreur réseau | valeurs de démo + message discret, ou bouton « Réessayer » |

Teste en coupant l'API (`Ctrl+C` dans le terminal `npm run dev`) puis en
relançant l'app : **elle ne doit pas planter**.

---

## 5. Critères de réussite ☑️

- [ ] `flutter analyze` ne renvoie aucune erreur.
- [ ] Les KPI affichent **5 / 5 / 1** avec l'API de démo.
- [ ] L'activité récente vient de `recentActivity` (plus de texte en dur).
- [ ] Cliquer une activité ouvre le bon onglet (`tabTarget`).
- [ ] La liste vide affiche `_buildEmptyActivityState()`.
- [ ] API coupée → aucun crash, message dans la console.
- [ ] Aucun email/mot de passe en dur dans le fichier.

> ✅ Quand tout est vert, tu maîtrises le motif
> **`token → query → data → setState`**.
> C'est **exactement** le même pour les 4 autres pages (guide § 5).

---

## 6. Dépannage rapide

| Problème | Piste |
|---|---|
| `Connection refused` | L'API n'est pas lancée → `cd ~/finds-api && npm run dev` |
| KPI à 0 tout le temps | Pas connecté → connecte-toi d'abord dans l'app |
| `10.0.2.2` sur émulateur Android | C'est normal : « localhost du PC » vu de l'émulateur |
| L'app plante | Tu as probablement oublié `if (!mounted) return;` ou le `try/catch` |
| Erreur CORS (web) | Voir guide § 7.4 |

> Blocue depuis plus de 20 minutes ? Relis la section correspondante de
> `GUIDE_LIAISON_API.md` (§ 8 = dépannage complet) avant de changer le code au hasard.
