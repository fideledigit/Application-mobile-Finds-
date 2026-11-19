import 'package:flutter/material.dart';
import '../../core/api/graphql_client.dart';
import '../../core/api/graphql_queries.dart';
import '../../core/constants/app_colors.dart';

List<Map<String, dynamic>>? _villesCache;

/// Ouvre la liste des villes/quartiers du backend.
/// Retourne « Ville » ou « Ville, Quartier », ou null si annulé.
Future<String?> showCityPickerSheet(BuildContext context, {String? title}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      top: false,
      child: _CityPickerSheet(title: title ?? 'Choisir un lieu'),
    ),
  );
}

class _CityPickerSheet extends StatefulWidget {
  final String title;
  const _CityPickerSheet({required this.title});

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  List<Map<String, dynamic>> _villes = _villesCache ?? [];
  bool _isLoading = _villesCache == null;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (_villesCache == null) _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final res = await FindsApiClient.query(GraphQLQueries.villesQuery);
    if (!mounted) return;
    final List raw = res.data?['villes'] as List? ?? [];
    final villes = raw.map((v) => Map<String, dynamic>.from(v as Map)).toList()
      ..sort(
        (a, b) =>
            (a['nom'] as String? ?? '').compareTo(b['nom'] as String? ?? ''),
      );
    if (villes.isNotEmpty) _villesCache = villes;
    setState(() {
      _villes = villes;
      _isLoading = false;
      _error = res.hasException
          ? FindsApiClient.errorMessage(res.exception)
          : null;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _villes;
    return _villes.where((v) {
      if ((v['nom'] as String? ?? '').toLowerCase().contains(q)) return true;
      final quartiers = v['quartiers'] as List? ?? [];
      return quartiers.any(
        (qt) => (qt['nom'] as String? ?? '').toLowerCase().contains(q),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.8;
    final villes = _filtered;
    final q = _query.trim().toLowerCase();

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Rechercher une ville ou un quartier…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.inputFill,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : villes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error ?? 'Aucune ville trouvée.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSubtle),
                          ),
                          if (_error != null)
                            TextButton(
                              onPressed: _load,
                              child: const Text('Réessayer'),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: villes.length,
                      itemBuilder: (context, i) {
                        final v = villes[i];
                        final nom = v['nom'] as String? ?? '';
                        final quartiers =
                            (v['quartiers'] as List? ?? [])
                                .map((e) => e['nom'] as String? ?? '')
                                .where((n) => n.isNotEmpty)
                                .toList()
                              ..sort();
                        final shownQuartiers =
                            q.isEmpty || nom.toLowerCase().contains(q)
                            ? quartiers
                            : quartiers
                                  .where((n) => n.toLowerCase().contains(q))
                                  .toList();

                        if (quartiers.isEmpty) {
                          return ListTile(
                            leading: const Icon(
                              Icons.location_city_rounded,
                              color: AppColors.primary,
                            ),
                            title: Text(nom),
                            onTap: () => Navigator.of(context).pop(nom),
                          );
                        }
                        return ExpansionTile(
                          initiallyExpanded:
                              q.isNotEmpty && !nom.toLowerCase().contains(q),
                          leading: const Icon(
                            Icons.location_city_rounded,
                            color: AppColors.primary,
                          ),
                          title: Text(nom),
                          subtitle: Text('${quartiers.length} quartiers'),
                          children: [
                            ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.only(
                                left: 56,
                                right: 16,
                              ),
                              title: Text(
                                'Toute la ville de $nom',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onTap: () => Navigator.of(context).pop(nom),
                            ),
                            for (final quartier in shownQuartiers)
                              ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.only(
                                  left: 56,
                                  right: 16,
                                ),
                                title: Text(quartier),
                                onTap: () => Navigator.of(
                                  context,
                                ).pop('$nom, $quartier'),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
