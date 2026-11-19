import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/api/graphql_client.dart';
import '../../../core/api/graphql_queries.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../widgets/app_back_button.dart';

/// Écran de discussion sécurisée (API : conversation / sendMessage)
class ChatConversationView extends StatefulWidget {
  final String conversationId;
  final String contactName;
  final String docTag;
  final bool isOfficial;

  const ChatConversationView({
    super.key,
    required this.conversationId,
    this.contactName = 'Citoyen',
    this.docTag = 'Document',
    this.isOfficial = false,
  });

  @override
  State<ChatConversationView> createState() => _ChatConversationViewState();
}

class _ChatConversationViewState extends State<ChatConversationView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollTimer;
  late String _contactName = widget.contactName;
  String? _otherUserId;
  String? _statut;

  @override
  void initState() {
    super.initState();
    _loadConversation(markRead: true);
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadConversation(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  static String _hhmm(String? iso) {
    final d = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadConversation({bool markRead = false}) async {
    final res = await FindsApiClient.query(
      GraphQLQueries.conversationQuery,
      variables: {'id': widget.conversationId},
    );
    if (!mounted) return;

    final conv = res.data?['conversation'] as Map<String, dynamic>?;
    if (conv == null) {
      setState(() => _isLoading = false);
      if (res.hasException) {
        debugPrint('[Chat] Erreur API : ${res.exception}');
      }
      return;
    }

    final myId = FindsApiClient.currentUser.value?['id'];
    final participants = conv['participants'] as List? ?? [];
    for (final p in participants) {
      if (p['userId'] != myId) {
        _otherUserId = p['userId'] as String?;
        final u = p['user'] as Map<String, dynamic>?;
        final name = '${u?['prenom'] ?? ''} ${u?['nom'] ?? ''}'.trim();
        if (name.isNotEmpty) _contactName = name;
      }
    }

    final previousCount = _messages.length;
    setState(() {
      _statut = conv['statut'] as String?;
      _messages = (conv['messages'] as List? ?? []).map((m) {
        return <String, dynamic>{
          'isMe': m['expediteurId'] == myId && m['estSysteme'] != true,
          'isSystem': m['estSysteme'] == true,
          'text': m['contenu'] as String? ?? '',
          'time': _hhmm(m['createdAt'] as String?),
          'date': DateTime.tryParse(m['createdAt'] as String? ?? '')?.toLocal(),
        };
      }).toList();
      _isLoading = false;
    });
    if (_messages.length != previousCount) _scrollToBottom();

    if (markRead) {
      FindsApiClient.mutate(
        GraphQLQueries.markConversationReadMutation,
        variables: {'conversationId': widget.conversationId},
      );
    }
  }

  static String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Aujourd\'hui';
    if (diff == 1) return 'Hier';
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    final label = '${d.day} ${months[d.month - 1]}';
    return d.year == now.year ? label : '$label ${d.year}';
  }

  Widget _withDateSeparator(int index, Widget message) {
    final date = _messages[index]['date'] as DateTime?;
    final prev = index > 0 ? _messages[index - 1]['date'] as DateTime? : null;
    final newDay =
        date != null &&
        (prev == null ||
            prev.year != date.year ||
            prev.month != date.month ||
            prev.day != date.day);
    if (!newDay) return message;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.chipBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _dayLabel(date),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBody,
                ),
              ),
            ),
          ),
        ),
        message,
      ],
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final now = DateTime.now().toIso8601String();
    setState(() {
      _isSending = true;
      _messages.add({
        'isMe': true,
        'text': text,
        'time': _hhmm(now),
        'date': DateTime.now(),
      });
      _messageController.clear();
    });
    _scrollToBottom();

    final res = await FindsApiClient.mutate(
      GraphQLQueries.sendMessageMutation,
      variables: {
        'input': {'conversationId': widget.conversationId, 'contenu': text},
      },
    );
    if (!mounted) return;
    _isSending = false;

    if (res.data?['sendMessage']?['success'] != true) {
      setState(() => _messages.removeLast());
      _messageController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            FindsApiClient.errorMessage(
              res.exception,
              fallback:
                  res.data?['sendMessage']?['message'] as String? ??
                  'Message non envoyé.',
            ),
          ),
        ),
      );
      return;
    }
    _loadConversation();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(),

            // Security relay reminder
            _buildSecurityRelayBanner(),

            // Messages List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) => _withDateSeparator(
                        index,
                        Builder(
                          builder: (context) {
                            final msg = _messages[index];
                            final isMe = msg['isMe'] as bool;

                            if (msg['isSystem'] == true) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  msg['text'] as String,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textSubtle,
                                  ),
                                ),
                              );
                            }

                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.78,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? AppColors.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg['text'] as String,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: isMe
                                            ? Colors.white
                                            : AppColors.textStrong,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          msg['time'] as String,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isMe
                                                ? Colors.white.withValues(
                                                    alpha: 0.8,
                                                  )
                                                : AppColors.textSubtle,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.done_all_rounded,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),

            if (_statut != null && _statut != 'RESOLUE' && _otherUserId != null)
              _buildResolutionButton(),

            // Bottom input bar
            if (_statut != 'RESOLUE' && _statut != 'FERMEE') _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: AppColors.pageBackground,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const AppBackButton(),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  _contactName.isEmpty
                      ? '?'
                      : _contactName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _contactName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textStrong,
                        ),
                      ),
                      if (widget.isOfficial) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        widget.docTag,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Vos coordonnées personnelles ne sont pas affichées dans la messagerie.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityRelayBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSizes.spaceMd,
        AppSizes.spaceXsm,
        AppSizes.spaceMd,
        AppSizes.spaceXxsm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spaceSm,
        vertical: AppSizes.spaceXsm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm - 2),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lock_rounded,
            size: AppSizes.iconXsm,
            color: AppColors.primary,
          ),
          SizedBox(width: AppSizes.spaceXsm),
          Expanded(
            child: Text(
              'Numéros et coordonnées personnelles masqués par sécurité Finds.',
              style: TextStyle(
                fontSize: AppSizes.fontXxsm + 1,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _openEvaluationSheet,
          icon: const Icon(
            Icons.task_alt_rounded,
            size: 18,
            color: AppColors.successDark,
          ),
          label: const Text(
            'Restitution effectuée : évaluer',
            style: TextStyle(
              color: AppColors.successDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            side: const BorderSide(color: AppColors.successDark),
          ),
        ),
      ),
    );
  }

  Future<void> _openEvaluationSheet() async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: _EvaluationSheet(
          conversationId: widget.conversationId,
          evalueId: _otherUserId!,
          contactName: _contactName,
        ),
      ),
    );
    if (done == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primary,
          content: Text('Merci ! Votre évaluation a été enregistrée.'),
        ),
      );
      _loadConversation();
    }
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spaceSm,
        vertical: AppSizes.spaceXsm,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceMd - 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              ),
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Écrire un message sécurisé…',
                  hintStyle: TextStyle(
                    fontSize: AppSizes.fontSm,
                    color: AppColors.textSubtle,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spaceXsm),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: AppSizes.iconSm,
              ),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationSheet extends StatefulWidget {
  final String conversationId;
  final String evalueId;
  final String contactName;

  const _EvaluationSheet({
    required this.conversationId,
    required this.evalueId,
    required this.contactName,
  });

  @override
  State<_EvaluationSheet> createState() => _EvaluationSheetState();
}

class _EvaluationSheetState extends State<_EvaluationSheet> {
  int _note = 0;
  bool _isSending = false;
  String? _error;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSending = true;
      _error = null;
    });
    final comment = _commentController.text.trim();
    final res = await FindsApiClient.mutate(
      GraphQLQueries.createEvaluationMutation,
      variables: {
        'input': {
          'conversationId': widget.conversationId,
          'evalueId': widget.evalueId,
          'note': _note,
          'commentaire': comment.isEmpty ? null : comment,
        },
      },
    );
    if (!mounted) return;
    final data = res.data?['createEvaluation'];
    if (data?['success'] == true) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSending = false;
      _error = FindsApiClient.errorMessage(
        res.exception,
        fallback: data?['message'] as String? ?? 'Évaluation impossible.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Évaluer la restitution',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Comment s\'est passé l\'échange avec ${widget.contactName} ?',
            style: const TextStyle(fontSize: 13, color: AppColors.textSubtle),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  iconSize: 36,
                  onPressed: () => setState(() => _note = i),
                  icon: Icon(
                    i <= _note ? Icons.star_rounded : Icons.star_border_rounded,
                    color: const Color(0xFFF5A623),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Commentaire (facultatif)',
              filled: true,
              fillColor: AppColors.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _note == 0 || _isSending ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Envoyer l\'évaluation'),
            ),
          ),
        ],
      ),
    );
  }
}
