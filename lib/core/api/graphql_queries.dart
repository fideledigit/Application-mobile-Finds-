/// Définition centralisée de l'ensemble des requêtes et mutations GraphQL
/// pour l'API Finds / RetrouveTout (https://nye-agbale.vercel.app/api/graphql).
class GraphQLQueries {
  GraphQLQueries._();

  // ===================================================================
  // 1. AUTHENTIFICATION & UTILISATEUR
  // ===================================================================

  static const String loginMutation = r'''
    mutation Login($input: LoginInput!) {
      login(input: $input) {
        accessToken
        refreshToken
        expiresIn
        user {
          id
          email
          nom
          prenom
          role
        }
      }
    }
  ''';

  static const String registerMutation = r'''
    mutation Register($input: RegisterInput!) {
      register(input: $input) {
        accessToken
        refreshToken
        expiresIn
        user {
          id
          email
          nom
          prenom
          role
        }
      }
    }
  ''';

  static const String refreshTokenMutation = r'''
    mutation RefreshToken($input: RefreshTokenInput!) {
      refreshToken(input: $input) {
        accessToken
        refreshToken
        expiresIn
      }
    }
  ''';

  static const String resetPasswordMutation = r'''
    mutation ResetPassword($email: String!, $newPassword: String!) {
      resetPassword(email: $email, newPassword: $newPassword)
    }
  ''';

  static const String logoutMutation = r'''
    mutation Logout {
      logout {
        success
        message
      }
    }
  ''';

  static const String meQuery = r'''
    query Me {
      me {
        id
        nom
        prenom
        email
        telephone
        role
        scoreReputation
        badgeCitoyen
        nombreRestitutions
        estVerifie
        ville
      }
    }
  ''';

  // ===================================================================
  // 2. DÉCLARATIONS (PERTES & DÉCOUVERTES)
  // ===================================================================

  /// Mutation unifiée de création de déclaration (PERTE ou TROUVAILLE)
  static const String createDeclarationMutation = r'''
    mutation CreateDeclaration($input: CreateDeclarationInput!) {
      createDeclaration(input: $input) {
        success
        message
      }
    }
  ''';

  /// Récupération des déclarations de l'utilisateur connecté (paginées)
  static const String myDeclarationsQuery = r'''
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
          descriptionLibre
          ville
          quartier
          statut
          photoUrl
          photoFlouteeUrl
          pdfUrl
          matchesCount
          createdAt
          updatedAt
        }
        meta {
          page
          pageSize
          total
          totalPages
        }
      }
    }
  ''';

  /// Recherche publique de déclarations
  static const String searchDeclarationsQuery = r'''
    query SearchDeclarations(
      $filter: SearchDeclarationsFilterInput
      $pagination: PaginationInput
    ) {
      searchDeclarations(filter: $filter, pagination: $pagination) {
        data {
          id
          userId
          type
          typeDocument
          nomProprietaire
          prenomProprietaire
          numeroDocument
          descriptionLibre
          ville
          quartier
          statut
          photoUrl
          photoFlouteeUrl
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
  ''';

  /// Détail d'une déclaration par ID
  static const String declarationDetailQuery = r'''
    query Declaration($id: String!) {
      declaration(id: $id) {
        id
        type
        typeDocument
        nomProprietaire
        prenomProprietaire
        numeroDocument
        descriptionLibre
        ville
        quartier
        statut
        photoUrl
        photoFlouteeUrl
        pdfUrl
        matchesCount
        createdAt
        updatedAt
        user {
          id
          nom
          prenom
          email
          avatarUrl
        }
      }
    }
  ''';

  // ===================================================================
  // 3. RAPPROCHEMENTS & MATCHING (IA BULLMQ)
  // ===================================================================

  /// Matches associés à une déclaration spécifique
  static const String declarationMatchesQuery = r'''
    query DeclarationMatches($declarationId: String!) {
      declarationMatches(declarationId: $declarationId) {
        id
        perteId
        trouvailleId
        score
        scoreNom
        scoreType
        scoreNumero
        scoreVille
        statut
        confirmeParDeclarant
        confirmeParTrouveur
        createdAt
      }
    }
  ''';

  /// Liste de tous les matches paginés
  static const String matchesQuery = r'''
    query Matches($filter: MatchesFilterInput, $pagination: PaginationInput) {
      matches(filter: $filter, pagination: $pagination) {
        data {
          id
          perteId
          trouvailleId
          score
          scoreNom
          scoreType
          scoreNumero
          scoreVille
          statut
          confirmeParDeclarant
          confirmeParTrouveur
          createdAt
        }
      }
    }
  ''';

  /// Confirmation d'un rapprochement
  static const String confirmMatchMutation = r'''
    mutation ConfirmMatch($matchId: String!) {
      confirmMatch(matchId: $matchId) {
        success
        message
      }
    }
  ''';

  /// Rejet d'un rapprochement avec justification
  static const String rejectMatchMutation = r'''
    mutation RejectMatch($matchId: String!, $raison: String) {
      rejectMatch(matchId: $matchId, raison: $raison) {
        success
        message
      }
    }
  ''';

  /// Clôture d'une déclaration après restitution
  static const String resolveDeclarationMutation = r'''
    mutation ResolveDeclaration($id: String!) {
      resolveDeclaration(id: $id) {
        success
        message
      }
    }
  ''';

  // ===================================================================
  // 4. STATISTIQUES GLOBALES & CITOYENNES
  // ===================================================================

  static const String publicStatsQuery = r'''
    query PublicStats {
      publicStats {
        declarationsAujourdhui
        documentsRetrouves
        tauxRestitution
        utilisateursActifs
        villesCouvertes
      }
    }
  ''';

  // ===================================================================
  // 5. MESSAGERIE INTER-CITOYENS
  // ===================================================================

  static const String myConversationsQuery = r'''
    query MyConversations($pagination: PaginationInput) {
      myConversations(pagination: $pagination) {
        data {
          id
          matchId
          statut
          nombreMessages
          updatedAt
          participants {
            userId
            nombreNonLus
            user {
              id
              nom
              prenom
            }
          }
          messages {
            id
            contenu
            createdAt
            expediteurId
            estSysteme
          }
        }
        meta {
          total
          page
          totalPages
        }
      }
    }
  ''';

  static const String conversationQuery = r'''
    query Conversation($id: String!) {
      conversation(id: $id) {
        id
        matchId
        statut
        nombreMessages
        participants {
          userId
          nombreNonLus
          user {
            id
            nom
            prenom
          }
        }
        messages {
          id
          contenu
          createdAt
          expediteurId
          estSysteme
          typeSysteme
          expediteur {
            id
            nom
            prenom
          }
        }
      }
    }
  ''';

  static const String conversationByMatchIdQuery = r'''
    query ConversationByMatchId($matchId: String!) {
      conversationByMatchId(matchId: $matchId) {
        id
      }
    }
  ''';

  static const String sendMessageMutation = r'''
    mutation SendMessage($input: SendMessageInput!) {
      sendMessage(input: $input) {
        success
        message
      }
    }
  ''';

  static const String markConversationReadMutation = r'''
    mutation MarkConversationRead($conversationId: String!) {
      markConversationRead(conversationId: $conversationId) {
        success
      }
    }
  ''';

  // ===================================================================
  // 6. NOTIFICATIONS
  // ===================================================================

  static const String myNotificationsQuery = r'''
    query MyNotifications($pagination: PaginationInput) {
      myNotifications(pagination: $pagination) {
        data {
          id
          type
          statut
          titre
          corps
          createdAt
          lueAt
          donnees
        }
        meta {
          total
          page
          pageSize
          totalPages
        }
      }
    }
  ''';

  static const String markNotificationReadMutation = r'''
    mutation MarkNotificationRead($notificationId: String!) {
      markNotificationRead(notificationId: $notificationId) {
        success
        message
      }
    }
  ''';

  static const String markAllNotificationsReadMutation = r'''
    mutation MarkAllNotificationsRead {
      markAllNotificationsRead {
        success
        message
      }
    }
  ''';

  // ===================================================================
  // 7. PROFIL & COMPTE
  // ===================================================================

  static const String updateUserMutation = r'''
    mutation UpdateUser($input: UpdateUserInput!) {
      updateUser(input: $input) {
        success
        message
      }
    }
  ''';

  static const String changePasswordMutation = r'''
    mutation ChangePassword($input: ChangePasswordInput!) {
      changePassword(input: $input) {
        success
        message
      }
    }
  ''';

  // ===================================================================
  // 8. RÉFÉRENTIEL GÉOGRAPHIQUE
  // ===================================================================

  static const String villesQuery = r'''
    query Villes {
      villes {
        id
        nom
        quartiers {
          id
          nom
        }
      }
    }
  ''';

  // ===================================================================
  // 9. DÉTAIL MATCH & RÉSOLUTION
  // ===================================================================

  static const String matchQuery = r'''
    query Match($id: String!) {
      match(id: $id) {
        id
        perteId
        trouvailleId
        statut
      }
    }
  ''';

  static const String createEvaluationMutation = r'''
    mutation CreateEvaluation($input: CreateEvaluationInput!) {
      createEvaluation(input: $input) {
        success
        message
      }
    }
  ''';

  static const String markDeclarationResolvedMutation = r'''
    mutation MarkDeclarationResolved($declarationId: String!) {
      markDeclarationResolved(declarationId: $declarationId) {
        success
        message
      }
    }
  ''';
}
