import 'app_texts_en.dart';

/// Portuguese (Brazil) text implementation.
///
/// This class inherits all base strings from English and overrides
/// high-priority UI keys used across the app.
class AppTextsPt extends AppTextsEn {
  // ========================================
  // Common
  // ========================================
  @override
  String get appName => 'GoShopping';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get delete => 'Excluir';

  @override
  String get edit => 'Editar';

  @override
  String get close => 'Fechar';

  @override
  String get back => 'Voltar';

  @override
  String get next => 'Próximo';

  @override
  String get done => 'Concluído';

  @override
  String get loading => 'Carregando...';

  @override
  String get error => 'Erro';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get confirm => 'Confirmar';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  // ========================================
  // Authentication
  // ========================================
  @override
  String get signIn => 'Entrar';

  @override
  String get signUp => 'Cadastrar';

  @override
  String get signOut => 'Sair';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Senha';

  @override
  String get displayName => 'Nome de exibição';

  @override
  String get createAccount => 'Criar conta';

  @override
  String get alreadyHaveAccount => 'Já tem uma conta?';

  @override
  String get dontHaveAccount => 'Ainda não tem uma conta?';

  @override
  String get forgotPassword => 'Esqueceu a senha?';

  @override
  String get emailRequired => 'Digite seu e-mail';

  @override
  String get passwordRequired => 'Digite sua senha';

  @override
  String get displayNameRequired => 'Digite seu nome de exibição';

  @override
  String get invalidEmail => 'Digite um e-mail válido';

  @override
  String get passwordTooShort => 'A senha deve ter pelo menos 6 caracteres';

  // ========================================
  // Group
  // ========================================
  @override
  String get group => 'Grupo';

  @override
  String get groups => 'Grupos';

  @override
  String get createGroup => 'Criar grupo';

  @override
  String get editGroup => 'Editar grupo';

  @override
  String get deleteGroup => 'Excluir grupo';

  @override
  String get groupName => 'Nome do grupo';

  @override
  String get groupMembers => 'Membros';

  @override
  String get addMember => 'Adicionar membro';

  @override
  String get removeMember => 'Remover membro';

  @override
  String get owner => 'Proprietário';

  @override
  String get member => 'Membro';

  @override
  String get leaveGroup => 'Sair do grupo';

  @override
  String get selectGroup => 'Selecionar grupo';

  @override
  String get noGroups => 'Sem grupos';

  @override
  String get groupCreated => 'Grupo criado';

  @override
  String get groupDeleted => 'Grupo excluído';

  @override
  String get groupUpdated => 'Grupo atualizado';

  @override
  String get groupNameRequired => 'Digite um nome de grupo';

  @override
  String get duplicateGroupName => 'Esse nome de grupo já está em uso';

  @override
  String get confirmDeleteGroup =>
      'Tem certeza de que deseja excluir este grupo?';

  @override
  String get current => 'Atual';

  @override
  String get noCurrentGroup => 'Nenhum grupo selecionado';

  @override
  String get loadingGroups => 'Carregando grupos...';

  @override
  String get preparingGroup => 'Preparando grupo...';

  @override
  String get groupLoadFailed => 'Falha ao carregar grupos';

  @override
  String get createFirstGroupHint =>
      'Crie seu primeiro grupo ou\nescaneie um QR code para entrar';

  @override
  String get createGroupHint => 'Toque no botão + para criar um grupo';

  @override
  String initialSetupDesc(String listName) =>
      'Compartilhe $listName com seu grupo.\nPrimeiro, crie um grupo\nou entre em um grupo existente.';

  @override
  String get createFirstGroup => 'Criar primeiro grupo';

  @override
  String get joinGroupByQR => 'Entrar no grupo por QR code';

  @override
  String get createGroupFailed => 'Falha ao criar grupo';

  @override
  String get deleteGroupWarning =>
      'Esta ação não pode ser desfeita.\nTodos os dados do grupo serão excluídos.';

  @override
  String get leavingGroup => 'Saindo do grupo...';

  @override
  String get creatingGroup => 'Criando grupo...';

  @override
  String get manager => 'Gerente';

  @override
  String get partner => 'Parceiro';

  // ========================================
  // List
  // ========================================
  @override
  String get list => 'Lista';

  @override
  String get lists => 'Listas';

  @override
  String get createList => 'Criar lista';

  @override
  String get editList => 'Editar lista';

  @override
  String get deleteList => 'Excluir lista';

  @override
  String get listName => 'Nome da lista';

  @override
  String get sharedList => 'Lista compartilhada';

  @override
  String get selectList => 'Selecionar lista';

  @override
  String get noLists => 'Sem listas';

  @override
  String get listCreated => 'Lista criada';

  @override
  String get listDeleted => 'Lista excluída';

  @override
  String get listUpdated => 'Lista atualizada';

  @override
  String get listNameRequired => 'Digite um nome de lista';

  @override
  String get duplicateListName => 'Esse nome de lista já está em uso';

  @override
  String get confirmDeleteList =>
      'Tem certeza de que deseja excluir esta lista?';

  @override
  String get defaultShoppingListName => 'Lista de compras';

  // ========================================
  // Item
  // ========================================
  @override
  String get item => 'Item';

  @override
  String get items => 'Itens';

  @override
  String get addItem => 'Adicionar item';

  @override
  String get editItem => 'Editar item';

  @override
  String get deleteItem => 'Excluir item';

  @override
  String get itemName => 'Nome do item';

  @override
  String get quantity => 'Quantidade';

  @override
  String get purchased => 'Comprado';

  @override
  String get notPurchased => 'Não comprado';

  @override
  String get noItems => 'Sem itens';

  @override
  String get itemAdded => 'Item adicionado';

  @override
  String get itemDeleted => 'Item excluído';

  @override
  String get itemUpdated => 'Item atualizado';

  @override
  String get itemNameRequired => 'Digite o nome do item';

  @override
  String get confirmDeleteItem =>
      'Tem certeza de que deseja excluir este item?';

  @override
  String get markAsPurchased => 'Marcar como comprado';

  @override
  String get markAsNotPurchased => 'Marcar como não comprado';

  @override
  String get addShoppingItem => 'Adicionar item de compra';

  @override
  String get productName => 'Nome do produto';

  @override
  String get quantityRequired => 'Digite uma quantidade';

  @override
  String get quantityInvalid => 'Digite uma quantidade válida (1 ou mais)';

  // ========================================
  // QR / Invitation
  // ========================================
  @override
  String get invitation => 'Convite';

  @override
  String get inviteMembers => 'Convidar membros';

  @override
  String get scanQRCode => 'Escanear QR code';

  @override
  String get generateQRCode => 'Gerar QR code';

  @override
  String get acceptInvitation => 'Aceitar convite';

  @override
  String get invitationAccepted => 'Convite aceito';

  @override
  String get invitationExpired => 'O convite expirou';

  @override
  String get invitationInvalid => 'Convite inválido';

  @override
  String get alreadyMember => 'Já é membro';

  @override
  String get scanningQRCode => 'Escaneando QR code...';

  @override
  String get qrCodeGenerated => 'QR code gerado';

  @override
  String get qrCodeInvite => 'Convite por QR code';

  @override
  String get processingInvitation => 'Processando convite...';

  @override
  String get cannotScanOwnCode => 'Você não pode escanear seu próprio convite';

  // ========================================
  // Settings / Notifications / Whiteboard
  // ========================================
  @override
  String get settings => 'Configurações';

  @override
  String get profile => 'Perfil';

  @override
  String get notifications => 'Notificações';

  @override
  String get language => 'Idioma';

  @override
  String get theme => 'Tema';

  @override
  String get about => 'Sobre';

  @override
  String get version => 'Versão';

  @override
  String get privacyPolicy => 'Política de privacidade';

  @override
  String get termsOfService => 'Termos de serviço';

  @override
  String get logout => 'Sair';

  @override
  String get deleteAccount => 'Excluir conta';

  @override
  String get confirmDeleteAccount =>
      'Tem certeza de que deseja excluir sua conta? Esta ação não pode ser desfeita.';

  @override
  String get notification => 'Notificação';

  @override
  String get notificationHistory => 'Histórico de notificações';

  @override
  String get markAsRead => 'Marcar como lido';

  @override
  String get deleteNotification => 'Excluir notificação';

  @override
  String get noNotifications => 'Sem notificações';

  @override
  String get whiteboard => 'Quadro branco';

  @override
  String get drawingMode => 'Modo desenho';

  @override
  String get scrollMode => 'Modo rolagem';

  @override
  String get penColor => 'Cor da caneta';

  @override
  String get penWidth => 'Espessura da caneta';

  @override
  String get eraseAll => 'Apagar tudo';

  @override
  String get undo => 'Desfazer';

  @override
  String get redo => 'Refazer';

  // ========================================
  // Sync / Errors / Date
  // ========================================
  @override
  String get sync => 'Sincronizar';

  @override
  String get syncing => 'Sincronizando...';

  @override
  String get syncCompleted => 'Sincronização concluída';

  @override
  String get syncFailed => 'Falha na sincronização';

  @override
  String get manualSync => 'Sincronização manual';

  @override
  String get lastSyncTime => 'Última sincronização';

  @override
  String get offlineMode => 'Modo offline';

  @override
  String get onlineMode => 'Modo online';

  @override
  String get networkError => 'Ocorreu um erro de rede';

  @override
  String get serverError => 'Ocorreu um erro no servidor';

  @override
  String get unknownError => 'Ocorreu um erro desconhecido';

  @override
  String get permissionDenied => 'Permissão negada';

  @override
  String get authenticationRequired => 'Autenticação necessária';

  @override
  String get operationFailed => 'Falha na operação';

  @override
  String get tryAgainLater => 'Tente novamente mais tarde';

  @override
  String get today => 'Hoje';

  @override
  String get yesterday => 'Ontem';

  @override
  String get daysAgo => 'dias atrás';

  @override
  String get hoursAgo => 'horas atrás';

  @override
  String get minutesAgo => 'minutos atrás';

  @override
  String get justNow => 'Agora mesmo';

  @override
  String get person => 'pessoa';

  @override
  String get people => 'pessoas';

  @override
  String get areYouSure => 'Tem certeza?';

  @override
  String get cannotBeUndone => 'Esta ação não pode ser desfeita';

  @override
  String get continueAction => 'Continuar';

  @override
  String get cancelAction => 'Cancelar';

  // ========================================
  // Home / Auth helpers
  // ========================================
  @override
  String get home => 'Início';

  @override
  String get signedOut => 'Sessão encerrada';

  @override
  String get signOutError => 'Erro ao sair';

  @override
  String get displayNameHint => 'Ex.: Taro';

  @override
  String get displayNameHelper =>
      'Esse nome será exibido para os membros do grupo';

  @override
  String get passwordHint => '6 caracteres ou mais';

  @override
  String welcomeUser(String name) => 'Conta criada! Bem-vindo(a), $name';

  @override
  String featureRequiresSignUp(String feature) => 'Para usar $feature';

  @override
  String get signUpRequiredMsg => 'É necessário cadastro';

  @override
  String get welcomeToGoShop => 'Bem-vindo ao GoShopping!';

  @override
  String get welcomeSubtitle =>
      'Compartilhe listas com família e grupos\npara gerenciar com mais facilidade';

  @override
  String get availableFeatures => '✨ Recursos disponíveis';

  @override
  String personalListCreate(String listType) => 'Criar $listType pessoal';

  @override
  String get signUpPromptBody =>
      'É necessário criar uma conta para usar este recurso.\n'
      'Ao se cadastrar, você pode usar:\n\n'
      '• Listas compartilhadas em grupo\n'
      '• Convites fáceis por QR code\n'
      '• Gerenciamento de membros\n'
      '• Backup e sincronização de dados';

  // ========================================
  // Sync / status icons
  // ========================================
  @override
  String get syncManagement => 'Gerenciamento de sincronização';

  @override
  String get syncingFirestore => 'Sincronizar do Firestore';

  @override
  String get clearCache => 'Limpar cache';

  @override
  String get clearCacheTitle => 'Limpar cache';

  @override
  String get clearCacheConfirm =>
      'Limpar o cache local?\nOs dados serão baixados novamente do Firestore na próxima inicialização.';

  @override
  String get clearCacheSuccess => 'Cache limpo';

  @override
  String get debugLabel => 'Depuração';

  @override
  String get onlineStatus => 'Status de conexão';

  @override
  String get connected => 'Conectado';

  @override
  String get offline => 'Offline';

  @override
  String get localModeNoSync => 'Modo local (sem sincronização)';

  @override
  String get syncStatusSynced => 'Sincronizado';

  @override
  String get syncStatusSyncing => 'Sincronizando...';

  @override
  String get syncStatusOffline => 'Desconectado';

  @override
  String get syncStatusNotLoggedIn => 'Não autenticado';

  @override
  String get networkOfflineStatus => 'Falha de rede';

  @override
  String get checkingConnectionStatus => 'Verificando conexão...';

  @override
  String get notSignedIn => 'Não conectado';

  // ========================================
  // Invitation / QR
  // ========================================
  @override
  String get qrCodeReader => 'Leitor de QR code';

  @override
  String get manualInput => 'Entrada manual';

  @override
  String get enter8CharCode => 'Digite o código alfanumérico de 8 caracteres';

  @override
  String get invalidQRFormat => 'Formato de QR code inválido';

  @override
  String get checkCameraPermission => 'Verifique a permissão da câmera';

  @override
  String get inviteType => 'Tipo de convite';

  @override
  String get inviteByQRTitle => 'Convidar por QR code';

  @override
  String get scanQRToJoinDesc => 'Escaneie este QR code para entrar no grupo';

  @override
  String maxInviteCount(int n) => 'Máximo de convidados: $n';

  @override
  String get qrScanInstruction => 'Alinhe o QR code dentro da moldura';

  @override
  String get qrScanButton => 'Escanear QR code';

  @override
  String get checkingInviteCode => 'Verificando código de convite...';

  @override
  String get tooltipManualInput => 'Inserir código manualmente';

  // ========================================
  // Help / menus
  // ========================================
  @override
  String get help => 'Ajuda';

  @override
  String get helpTitle => 'Ajuda';

  @override
  String get errorHistory => 'Histórico de erros';

  @override
  String get versionInfo => 'Informações da versão';

  @override
  String get legalTitle => 'Informações legais';

  @override
  String get versionInfoTitle => 'Informações da versão';

  @override
  String get versionLabel => 'Versão';

  @override
  String get buildNumberLabel => 'Número da build';

  @override
  String get packageNameLabel => 'Nome do pacote';

  @override
  String get appFooterSubtitle => 'App de compartilhamento';

  @override
  String get displayLanguageTitle => 'Idioma de exibição / Display Language';

  @override
  String get displayLanguageDesc =>
      'Selecione o idioma do app (reinicie para aplicar totalmente)';

  @override
  String get languageJa => 'Japonês';

  @override
  String get languageChangedEn =>
      'Idioma alterado para Português. Reinicie para aplicar totalmente.';

  @override
  String get languageChangedJa =>
      'Idioma alterado para Japonês. Reinicie para aplicar totalmente.';

  @override
  String get settingsPagePlaceholder => 'Página de configurações (provisória)';

  @override
  String get goShopSettingsLabel => 'Configurações do Go Shop';

  @override
  String get checkingAuthStatus => 'Verificando status de autenticação...';

  @override
  String get errorOccurredTitle => 'Ocorreu um erro';

  @override
  String get appModeTitle => 'Modo do aplicativo';

  @override
  String get appModeDesc =>
      'Selecione entre lista de compras e compartilhamento de tarefas';

  @override
  String get shoppingListMode => 'Modo Lista de Compras';

  @override
  String get todoShareMode => 'Modo Compartilhar Tarefas';

  @override
  String modeChanged(String modeName) => 'Modo alterado para: $modeName';

  @override
  String get switchedToMultiMode => 'Alternado para modo múltiplo';

  @override
  String get selectGroupBeforeSwitch => 'Selecione um grupo antes de alternar';

  @override
  String get selectListBeforeSwitch => 'Selecione uma lista antes de alternar';

  @override
  String get switchedToSingleMode => 'Alternado para modo único';

  @override
  String get whiteboardSettingsTitle => 'Configurações do quadro branco';

  @override
  String get customColorSettingsTitle => 'Configuração de cores personalizadas';

  @override
  String get customColorSettingsDesc =>
      'Além de 4 cores básicas (preto, vermelho, verde, amarelo), você pode definir 2 cores personalizadas';

  @override
  String colorSlot(int n) => 'Cor $n: ';

  @override
  String get errorWithPrefix => 'Erro';

  @override
  String get notificationSettings => 'Configurações de notificações';

  @override
  String get listChangeNotificationSettings =>
      'Configurações de notificação de alterações da lista';

  @override
  String get listChangeNotification => 'Notificação de alteração da lista';

  @override
  String get listChangeNotificationDesc =>
      'Receba notificações quando itens da lista forem alterados';

  @override
  String get listNotificationOn => 'Notificação ativada';

  @override
  String get listNotificationOff => 'Notificação desativada';

  @override
  String get viewNotificationHistory => 'Ver histórico de notificações';

  @override
  String get feedbackSectionTitle => 'Enviar feedback';

  @override
  String get feedbackSectionDesc => 'Conte-nos sua opinião';

  @override
  String get feedbackSectionSubDesc =>
      'Ajude a melhorar a versão beta. Leva cerca de 1 minuto.';

  @override
  String get feedbackButton => 'Responder pesquisa';

  @override
  String get feedbackThanks => 'Obrigado pelo seu feedback!';

  @override
  String get formOpenFailed => 'Não foi possível abrir o formulário';

  @override
  String get reauthRequired => 'Reautenticação necessária';

  @override
  String get reauthDescription =>
      'Para excluir a conta, digite sua senha atual.';

  @override
  String get finalConfirmation => 'Confirmação final';

  @override
  String get deleteCompletely => 'Excluir permanentemente';

  @override
  String get deletingAccount => 'Excluindo conta...';

  @override
  String get deletingAccountProgress =>
      'Removendo dados da conta. Aguarde um momento.';

  @override
  String get authError => 'Erro de autenticação';

  @override
  String get wrongPassword => 'Senha incorreta';

  @override
  String get authFailed => 'Falha na autenticação';

  @override
  String get deletionComplete => 'Exclusão concluída';

  @override
  String get deletionFailed => 'Falha na exclusão';

  @override
  String get deleteAccountAndData => 'Excluir conta e dados';

  @override
  String get cannotUndoWarning => 'Esta ação não pode ser desfeita';

  @override
  String deleteAccountWarningBody(String listName) =>
      '⚠️ Esta operação não pode ser desfeita\n\nOs dados a seguir serão excluídos permanentemente:\n• Informações da conta\n• Todas as $listName\n• Grupos que você possui\n• Dados do quadro branco\n• Histórico de notificações\n\nTem certeza?';

  @override
  String finalConfirmationBody(String email) =>
      'E-mail: $email\n\nTem certeza de que deseja excluir esta conta?\n\nEsta ação não pode ser desfeita.';

  @override
  String get deletionCompleteBody =>
      'Sua conta e todos os dados foram excluídos.\n\nObrigado por usar o Go Shop.';

  @override
  String deletionFailedBody(String e) =>
      'Ocorreu um erro ao excluir a conta.\n\nErro:\n$e\n\nEntre em contato com o desenvolvedor.';

  // ========================================
  // Notification templates
  // ========================================
  @override
  String notifListCreated(String name, String list) => '$name criou "$list"';

  @override
  String notifListDeleted(String name, String list) => '$name excluiu "$list"';

  @override
  String notifRenamed(String name, String oldName, String newName) =>
      '$name renomeou "$oldName" para "$newName"';

  @override
  String notifMemberJoined(String name, String group) =>
      '$name entrou em "$group"';

  @override
  String notifMembershipApproved(String group) =>
      group.isNotEmpty ? 'Você entrou em "$group"' : 'Sua entrada foi aprovada';

  @override
  String notifGroupDeleted(String name, String group) =>
      '$name excluiu "$group"';

  @override
  String notifMemberLeft(String name, String group) => '$name saiu de "$group"';

  @override
  String notifYouLeft(String group) => 'Você saiu de "$group"';

  @override
  String notifItemAdded(String name, String item, String list) =>
      '$name adicionou "$item" em "$list"';

  @override
  String notifItemRemoved(String name, String item, String list) =>
      '$name removeu "$item" de "$list"';

  @override
  String notifItemPurchased(String name, String item, String list) =>
      '$name comprou "$item" em "$list"';

  @override
  String notifWhiteboardUpdated(String name) =>
      '$name atualizou o quadro branco';

  @override
  String notifWhiteboardEditStarted(String name) =>
      '$name começou a desenhar no quadro branco';

  @override
  String notifWhiteboardEditEnded(String name) =>
      '$name terminou de desenhar no quadro branco';

  // ========================================
  // Operation labels
  // ========================================
  @override
  String get opSignIn => 'Entrar';

  @override
  String get opCreateAccount => 'Criar conta';

  @override
  String get opSaveUserName => 'Salvar nome de usuário';

  @override
  String get opResetPassword => 'Redefinir senha';

  @override
  String get opSignUp => 'Cadastrar';

  @override
  String get opAddMember => 'Adicionar membro';

  @override
  String get opUpdateGroupName => 'Atualizar nome do grupo';

  @override
  String get opSaveWhiteboard => 'Salvar quadro branco';

  @override
  String get opClearWhiteboard => 'Limpar quadro branco';

  @override
  String get opUpdatePurchaseStatus => 'Atualizar status de compra';

  @override
  String get opUpdateGroupMember => 'Atualizar membro do grupo';

  @override
  String get opSendNotification => 'Enviar notificação';

  @override
  String get opLoadUserName => 'Carregar nome de usuário';

  @override
  String get opUpdateAllGroupUserNames =>
      'Atualizar todos os nomes de usuários do grupo';

  @override
  String get opGetGroupUserName => 'Obter nome de usuário do grupo';

  @override
  String get opGetGroupMembers => 'Obter membros do grupo';

  @override
  String get opSignOutClear => 'Limpar ao sair';

  @override
  String get opGetFirestoreUserName => 'Obter nome no Firestore';

  @override
  String get opSaveFirestoreUserName => 'Salvar nome no Firestore';

  @override
  String get opDeleteFirestoreUserName => 'Excluir nome no Firestore';

  @override
  String get opCreateUserProfile => 'Criar perfil de usuário';

  @override
  String get opSaveBillingType => 'Salvar tipo de cobrança';

  @override
  String get opSearchInvitableGroups => 'Buscar grupos convidáveis';

  @override
  String get opSendInvite => 'Enviar convite';

  @override
  String get opAcceptInvitation => 'Aceitar convite';

  @override
  String get opSearchPendingInvitations => 'Buscar convites pendentes';

  @override
  String get opRecordInvitation => 'Registrar convite';

  @override
  String get opGetPendingInvitations => 'Obter convites pendentes';

  @override
  String get opMarkInvitationProcessed => 'Marcar convite como processado';

  @override
  String get opDeleteInvitation => 'Excluir convite';

  @override
  String get opCreateQrInvite => 'Criar convite QR';

  @override
  String get opDecodeQrCode => 'Decodificar QR code';

  @override
  String get opGetQrInviteDetails => 'Obter detalhes do convite QR';

  @override
  String get opAcceptQrInvite => 'Aceitar convite QR';

  // ========================================
  // Tips / help
  // ========================================
  @override
  String get tipsLabel => 'Dicas';

  @override
  String get tipTapTitle => 'Básico: Toque';

  @override
  String get tipTapBody =>
      'Toque para alternar o status do item, selecionar o grupo atual e mais.';

  @override
  String get tipDoubleTapTitle => 'Dica: Toque duplo';

  @override
  String get tipDoubleTapBody =>
      'Toque duplo para editar itens, ver quadro branco de membros e mais.';

  @override
  String get tipLongPressTitle => 'Ação segura: Toque longo';

  @override
  String get tipLongPressBody =>
      'Use toque longo para ações destrutivas como excluir itens ou sair de grupos.';

  @override
  String get tipGroupScreenTitle => 'Tela de grupos';

  @override
  String get tipGroupScreenBody =>
      'Toque -> selecionar atual, toque duplo -> gerenciar membros, toque longo -> excluir/sair.';

  @override
  String get tipMemberScreenTitle => 'Tela de membros';

  @override
  String get tipMemberScreenBody =>
      'Toque -> alterar função (dono) ou ver info, toque duplo -> quadro branco.';

  @override
  String get helpBasicUsage => 'Uso básico';

  @override
  String helpBasicUsagePoint(int n) {
    const points = [
      'Crie um grupo e convide membros',
      'Compartilhe listas e sincronize em tempo real',
      'Adicione itens e marque como comprados',
    ];
    return n >= 1 && n <= points.length ? points[n - 1] : '';
  }

  @override
  String get helpGroupInvite => 'Convite de grupo';

  @override
  String helpGroupInvitePoint(int n) {
    const points = [
      'Mostre um QR code para convidar membros',
      'Escaneie um QR code para entrar em um grupo',
      'Convites valem por 24 horas, até 5 membros',
    ];
    return n >= 1 && n <= points.length ? points[n - 1] : '';
  }

  @override
  String get helpSyncIcons => 'Ícones de status de sincronização';

  @override
  String helpSyncIconPoint(int n) {
    const points = [
      '🟢 Verde: Sincronizado',
      '🟠 Laranja: Sincronizando',
      '🔴 Vermelho: Desconectado',
      '⚪ Cinza: Não autenticado',
    ];
    return n >= 1 && n <= points.length ? points[n - 1] : '';
  }

  @override
  String get howToInviteTitle => 'Como convidar';

  @override
  String get howToInviteDesc =>
      '1. Peça para a outra pessoa escanear o QR code\n'
      '2. Ela será adicionada automaticamente após aceitar no app\n'
      '3. Verifique o grupo quando receber a notificação de aceitação';

  // ========================================
  // Error / notification history details
  // ========================================
  @override
  String get noErrorHistory => 'Sem histórico de erros';

  @override
  String get markReadAndClose => 'Marcar como lido e fechar';

  @override
  String get markedAsRead => 'Marcado como lido';

  @override
  String get deleteReadErrors => 'Excluir erros lidos';

  @override
  String get deleteReadErrorsConfirm =>
      'Excluir todos os logs de erro lidos?\nEsta ação não pode ser desfeita.';

  @override
  String get noReadNotifications => 'Sem notificações lidas';

  @override
  String markedReadFailed(String e) => 'Falha ao marcar como lido: $e';

  @override
  String deletedErrorLogs(int count) => '$count log(s) de erro excluído(s)';

  @override
  String deleteErrorLogFailed(String e) => 'Falha ao excluir logs de erro: $e';

  @override
  String deletedReadNotifications(int count) =>
      '$count notificação(ões) lida(s) excluída(s)';

  // ========================================
  // Invitation accept / member management
  // ========================================
  @override
  String get inviteAcceptTitle => 'Aceitar convite';

  @override
  String get inviteAcceptDesc =>
      'Foi convidado para um grupo?\nEscaneie um QR code ou insira um código de convite.';

  @override
  String get invalidQRCodeMsg => 'Formato de QR code inválido';

  @override
  String get cameraErrorPrefix => 'Erro da câmera:';

  @override
  String get unknownGroup => 'Grupo desconhecido';

  @override
  String invitationPendingApproval(String groupName) =>
      'Aguardando aprovação de $groupName';

  @override
  String get groupInfo => 'Informações do grupo';

  @override
  String get inviteOnlyForAdmins =>
      'Somente proprietário, admins e parceiros podem convidar membros';

  @override
  String get selectInviteMethod => 'Selecione o método de convite';

  @override
  String get noMembers => 'Sem membros';

  @override
  String get inviteMemberHint =>
      'Use o botão + no canto superior direito\npara convidar membros';

  @override
  String get memberListLabel => 'Lista de membros';

  @override
  String get recommendPortrait => 'Recomendado usar modo retrato';

  @override
  String memberCount(int count) => 'Membros: $count';

  @override
  String ownerDisplay(String name) => 'Proprietário: $name';

  @override
  String syncErrorMessage(String error) => 'Erro de sincronização: $error';

  // ========================================
  // Misc helper labels
  // ========================================
  @override
  String get currentPrefix => 'Atual';

  @override
  String get saving => 'Salvando...';

  @override
  String get saveUserName => 'Salvar nome de usuário';

  @override
  String get userNameSaved => 'Nome de usuário salvo';

  @override
  String saveFailed(Object e) => 'Falha ao salvar: $e';

  // ========================================
  // Additional auth / onboarding
  // ========================================
  @override
  String get loginOrRegister => 'Entrar / Cadastrar';

  @override
  String get login => 'Entrar';

  @override
  String get register => 'Cadastrar';

  @override
  String get saveEmail => 'Salvar e-mail';

  @override
  String get enterUserName => 'Digite o nome de usuário';

  @override
  String get signUpFailed => 'Falha ao criar conta';

  @override
  String get emailAlreadyInUse => 'Este e-mail já está em uso';

  @override
  String get weakPassword => 'A senha é muito fraca';

  @override
  String get signInFailed => 'Falha ao entrar';

  @override
  String get userNotFoundSignIn =>
      'Usuário não encontrado. Crie uma conta primeiro';

  @override
  String get wrongEmailOrPassword => 'E-mail ou senha incorretos';

  @override
  String get switchToSignIn => 'Mudar para Entrar';

  @override
  String get switchToCreateAccount => 'Mudar para Criar Conta';

  @override
  String get resetPassword => 'Redefinir senha';

  @override
  String get rememberEmail => 'Lembrar e-mail';

  @override
  String get forNewUsers => 'Para novos usuários';

  @override
  String get howToUse => 'Como usar';

  @override
  String get noTasks => 'Sem tarefas';

  @override
  String get noShoppingItems => 'Sem itens de compra';

  @override
  String get privacyAbout => 'Sobre privacidade';

  @override
  String get forNewUsersDesc =>
      'Crie uma conta ou entre com e-mail e senha.\nSe já tiver conta, entre com as mesmas credenciais.';

  @override
  String howToUsePoint(int n) {
    const points = [
      'Gerencie grupos na aba "Grupos" na parte inferior',
      'Selecione um grupo para ver suas listas',
      'Convide família e amigos com QR code',
      'Configure o app na aba "Configurações"',
    ];
    return n >= 1 && n <= points.length ? points[n - 1] : '';
  }

  @override
  String get privacyPoint1 =>
      'Inicialmente, apenas login e nome de exibição são compartilhados';

  @override
  String get privacyPoint2 =>
      'Listas só são compartilhadas com quem você permitir';

  @override
  String get privacyPoint3 =>
      'Usuários que entram no seu grupo seguem a mesma política';

  @override
  String get privacyPoint4 =>
      'Uma conta Firebase é necessária para usar o aplicativo';

  // ========================================
  // Additional mode / list-item helpers
  // ========================================
  @override
  String get create => 'Criar';

  @override
  String get update => 'Atualizar';

  @override
  String get add => 'Adicionar';

  @override
  String get leave => 'Sair';

  @override
  String get managementMode => 'Modo de gerenciamento';

  @override
  String get singleModeLabel => 'Único';

  @override
  String get multiModeLabel => 'Múltiplo';

  @override
  String get singleModeDesc => 'Modo único: um grupo e uma lista';

  @override
  String get multiModeDesc => 'Modo múltiplo: vários grupos e listas';

  @override
  String get switchToSingleMode => 'Mudar para modo único';

  @override
  String get switchToSingleModeBody =>
      'Apenas o grupo e lista atuais serão exibidos.\nSeus outros dados não serão apagados.';

  @override
  String get doSwitch => 'Alternar';

  @override
  String get selectGroupFirst => 'Selecione um grupo primeiro';

  @override
  String get noGroupSelected => 'Nenhum grupo selecionado';

  @override
  String get descriptionOptional => 'Descrição (opcional)';

  @override
  String get editTask => 'Editar tarefa';

  @override
  String get addTask => 'Adicionar tarefa';

  @override
  String get purchaseIntervalOptional => 'Intervalo de compra (opcional)';

  @override
  String get perDay => 'Por dia';

  @override
  String get perWeek => 'Por semana';

  @override
  String get perMonth => 'Por mês';

  @override
  String get noRepeatPurchase => 'Sem repetição';

  @override
  String get selectDeadlineOptional => 'Definir prazo (opcional)';

  @override
  String get deadlineMustBeFuture => 'O prazo deve ser hoje ou depois';

  // ========================================
  // Additional news / feedback
  // ========================================
  @override
  String get newsPanelTitle => '📰 Notícias e anúncios';

  @override
  String get newsCardTitle => 'Notícias';

  @override
  String get newsLoading => 'Carregando notícias...';

  @override
  String get thankYou => 'Obrigado pelo feedback!';

  @override
  String get surveyAction => 'Responder pesquisa';

  @override
  String get remindLater => 'Lembrar depois';

  @override
  String get premiumPlan => 'Plano Premium';

  @override
  String get remindTomorrow => 'Lembrar amanhã';

  @override
  String get cannotOpenLink => 'Não foi possível abrir o link';

  @override
  String get invalidLink => 'Link inválido';

  @override
  String get thanks => 'Obrigado!';

  @override
  String cannotOpenForm(String e) => 'Não foi possível abrir o formulário: $e';

  // ========================================
  // Notification/error history detail labels
  // ========================================
  @override
  String get weeksAgo => ' semanas atrás';

  @override
  String get monthsAgo => ' meses atrás';

  @override
  String get yearsAgo => ' anos atrás';

  @override
  String get timeUnknown => 'Hora desconhecida';

  @override
  String get unread => 'Não lido';

  @override
  String get tooltipMarkRead => 'Marcar como lido';

  @override
  String get tooltipDeleteRead => 'Excluir notificações lidas';

  @override
  String get tooltipReload => 'Recarregar';

  @override
  String get firestoreIndexRequired => 'Índice do Firestore necessário';

  @override
  String get firestoreIndexDesc =>
      'Crie um índice composto no Console do Firebase';

  @override
  String get errorWithDetail => 'Ocorreu um erro: ';

  @override
  String get unknownOperation => 'Operação desconhecida';

  @override
  String get noErrorDetailMsg => 'Sem detalhes de erro';

  @override
  String get permissionErrorLabel => 'Erro de permissão';

  @override
  String get networkErrorLabel => 'Erro de rede';

  @override
  String get syncErrorLabel => 'Erro de sincronização';

  @override
  String get validationErrorLabel => 'Erro de validação';

  @override
  String get operationErrorLabel => 'Erro de operação';

  @override
  String get unknownErrorLabel => 'Erro desconhecido';

  @override
  String get operationLabel => 'Operação';

  @override
  String get messageLabel => 'Mensagem';

  @override
  String get occurredAtLabel => 'Ocorrido em';

  @override
  String get contextLabel => 'Contexto';

  @override
  String get stackTraceLabel => 'Stack trace:';

  // ========================================
  // Group details / copy members
  // ========================================
  @override
  String get aboutGroups => 'Sobre grupos';

  @override
  String get aboutGroupsDesc => '• Compartilhe listas dentro do grupo\n'
      '• Crie grupos para família, amigos e trabalho\n'
      '• Convide e entre facilmente com QR code';

  @override
  String get copyMembersFrom => 'Copiar membros de grupo existente (opcional):';

  @override
  String get selectGroupHint => 'Selecione um grupo...';

  @override
  String get newGroupNoMembers => 'Novo grupo (sem membros)';

  @override
  String get selectMembersToCopy => 'Selecione membros e funções para copiar:';

  @override
  String get noMembersInGroup => 'Não há membros no grupo selecionado';

  @override
  String get selectGroupToCopyMembers =>
      'Selecione um grupo existente para copiar os membros';

  @override
  String get leaveGroupWarning =>
      'Suas informações serão removidas deste grupo.\nSerá necessário novo convite para retornar.';

  @override
  String get leaveRequestSent =>
      'Solicitação de saída enviada. O grupo desaparecerá após o processamento.';

  @override
  String get deletingGroup => 'Excluindo grupo...';

  @override
  String get groupNameHint => 'Ex.: Família, Amigos, Trabalho';

  // ========================================
  // Invitation methods / member management
  // ========================================
  @override
  String get inviteByQR => 'Convidar por QR code';

  @override
  String get inviteByQRDesc => 'Gere um QR code para a outra pessoa escanear';

  @override
  String get inviteByEmail => 'Convidar por e-mail';

  @override
  String get inviteByEmailDesc =>
      'Envie um convite para um endereço de e-mail específico';

  @override
  String get addMemberManually => 'Adicionar membro manualmente';

  @override
  String get addMemberManuallyDesc => 'Insira os dados do membro diretamente';

  @override
  String get enterEmailToInvite => 'Digite o e-mail para convite';

  @override
  String get sendInvitation => 'Enviar convite';

  @override
  String get emailInviteUnavailable =>
      'Convite por e-mail indisponível. Use convite por QR.';

  @override
  String get enterGroupName => 'Digite um nome de grupo';

  @override
  String get generateInviteCode => 'Gerar novo código de convite';

  @override
  String get inviteManagement => 'Gerenciamento de convites';

  @override
  String get activeInviteCodes => 'Códigos de convite ativos';

  @override
  String get noActiveInvites => 'Não há códigos de convite ativos';

  @override
  String get deleteInviteCode => 'Excluir convite';

  @override
  String get deleteInviteCodeConfirm => 'Excluir este código de convite?';

  @override
  String get copy => 'Copiar';

  @override
  String get selectFromPool => 'Selecionar do pool';

  @override
  String get newMember => 'Novo membro';

  @override
  String get noMembersInPool => 'Não há membros no pool';

  @override
  String get promoteToAdmin => 'Promover para admin';

  @override
  String get demoteToMember => 'Rebaixar para membro';

  @override
  String get promote => 'Promover';

  @override
  String get demote => 'Rebaixar';

  @override
  String get invitationResults => 'Resultados do convite';

  @override
  String get errorDetails => 'Detalhes do erro:';

  @override
  String promotedToAdmin(String name) => '$name promovido a admin';

  @override
  String demotedToMember(String name) => '$name rebaixado para membro';

  @override
  String sendInvitationsCount(int count) => 'Enviar convites ($count)';

  @override
  String get checkingInvitations => 'Verificando convites...';

  @override
  String get processAll => 'Processar tudo';

  @override
  String get rejectInvitation => 'Rejeitar convite';

  @override
  String get reject => 'Rejeitar';

  @override
  String get invitationStats => 'Estatísticas de convite';

  @override
  String get joinGroup => 'Entrar no grupo';

  @override
  String get joinGroupQuestion => 'Entrar no grupo abaixo?';

  @override
  String get join => 'Entrar';

  @override
  String joinAsRole(String role) => 'Entrar como $role';

  @override
  String approvedJoin(String name) => 'Aprovou entrada de $name';

  @override
  String rejectConfirm(String name) =>
      'Rejeitar solicitação de entrada de $name?';

  @override
  String rejectedInvite(String name) => 'Convite de $name rejeitado';

  @override
  String alreadyJoinedGroup(String name) => 'Já é membro de "$name"';

  // ========================================
  // Premium / migration / mode-dependent names
  // ========================================
  @override
  String get trialStarted => 'Teste grátis iniciado';

  @override
  String get startTrial => 'Iniciar teste';

  @override
  String get resetToFree => 'Voltar ao plano gratuito';

  @override
  String get selectPlan => 'Selecionar';

  @override
  String get upgradedToAnnualPlan => 'Atualizado para plano anual!';

  @override
  String get upgradedTo3YearPlan => 'Atualizado para plano de 3 anos!';

  @override
  String get groupManagement => 'Gerenciamento de grupos';

  @override
  String get noGroupData => 'Sem dados de grupo';

  @override
  String get featureInProgress => 'Recurso em desenvolvimento';

  @override
  String get addGroupInProgress =>
      'A funcionalidade de adicionar grupo está em desenvolvimento.';

  @override
  String get toPremium => 'Ir para Premium';

  @override
  String get premiumBenefits => '✨ Benefícios Premium';

  @override
  String get benefitNoAds => '• Sem anúncios';

  @override
  String get benefitPremiumSupport => '• Suporte premium';

  @override
  String get benefitEarlyAccess => '• Acesso antecipado a novos recursos';

  @override
  String get pricePlan => 'Preços';

  @override
  String get userChangedDetected => 'Mudança de usuário detectada';

  @override
  String get differentUserLoggedIn => 'Um usuário diferente entrou.';

  @override
  String userPrevious(String user) => 'Anterior: $user';

  @override
  String userCurrent(String user) => 'Atual: $user';

  @override
  String get whatToDoWithOldData => 'O que fazer com os dados anteriores?';

  @override
  String get dataMigrationDescription =>
      '• Manter: grupos e listas existentes serão transferidos\n'
      '• Limpar: começar do zero para o novo usuário';

  @override
  String get clearData => 'Limpar';

  @override
  String get keepData => 'Manter';

  @override
  String get secretModeEnabled => 'Modo secreto ativado';

  @override
  String get groupDataRequiresLogin => 'Faça login para ver dados de grupo';

  @override
  String get newGroup => 'Novo grupo';

  @override
  String signInToUseGroup(String groupName) =>
      'Faça login para usar recursos de $groupName';

  @override
  String get noSharedList => 'Sem listas';

  @override
  String createNewSharedList(String listName) => 'Criar novo(a) $listName';

  @override
  String duplicateListNameAlert(String name) => 'Já existe uma lista "$name"';

  @override
  String deleteListConfirm(String name) => 'Excluir "$name"?';

  @override
  String get listCreateHint => 'Ex.: Compras do fim de semana';

  @override
  String sharedListNameForMode(bool isShopping) =>
      isShopping ? 'Lista de compras' : 'Lista de tarefas';

  @override
  String groupNameForMode(bool isShopping) => isShopping ? 'Grupo' : 'Equipe';

  // ========================================
  // Final remaining keys
  // ========================================
  @override
  String get ok => 'OK';

  @override
  String get initPreparingApp => 'Preparando aplicativo...';

  @override
  String get initCheckingData => 'Verificando dados...';

  @override
  String get initPreparingUser => 'Preparando perfil do usuário...';

  @override
  String get initReady => 'Pronto';

  @override
  String get initErrorButContinue =>
      'Ocorreu um erro na inicialização, mas continuando...';

  @override
  String get initPreparingService => 'Preparando serviços...';

  @override
  String get initSyncingGroups => 'Sincronizando dados dos grupos...';

  @override
  String get pieces => '';

  @override
  String get dataMaintenance => 'Manutenção de dados';

  @override
  String get cleanupData => 'Limpar dados';

  @override
  String get enableNotifications => 'Ativar notificações';

  @override
  String get createWhiteboard => 'Criar quadro branco';

  @override
  String get editWhiteboard => 'Editar quadro branco';

  @override
  String get deleteWhiteboard => 'Excluir quadro branco';

  @override
  String get whiteboards => 'Quadros brancos';

  @override
  String get whiteboardName => 'Nome do quadro branco';

  @override
  String get zoom => 'Zoom';

  @override
  String get appDescription =>
      'Aplicativo para compartilhar listas de compras com família e grupos.';

  @override
  String get mainFeatures => 'Principais recursos:';

  @override
  String get featureGroupSharing => '• Listas compartilhadas em grupo';

  @override
  String get featureRealtimeSync => '• Sincronização em tempo real';

  @override
  String get featureOfflineSupport => '• Suporte offline';

  @override
  String get featureMemberManagement => '• Gerenciamento de membros';

  @override
  String get accountNotFound => 'Conta não encontrada';

  @override
  String get createNew => 'Criar novo';

  @override
  String get accountCreated => 'Conta criada';

  @override
  String get accountCreationFailed => 'Falha ao criar conta';

  @override
  String accountNotFoundBody(String email) =>
      'Nenhuma conta encontrada para $email.\nCriar uma nova conta?';

  @override
  String get signUpRequiredTitle => 'Cadastro necessário';

  @override
  String get signUpToUseAll => 'Cadastre-se para usar todos os recursos';

  @override
  String get later => 'Depois';

  @override
  String get scanQRRequiresSignUp => 'Escanear QR (requer cadastro)';

  @override
  String get inviteRequiresSignUp => 'Convidar (requer cadastro)';

  @override
  String get inviteMemberLabel => 'Convidar membro';

  @override
  String get groupListSharing => 'Compartilhamento de listas em grupo';

  @override
  String get qrInviteFeature => 'Recurso de convite por QR code';

  @override
  String get groupInvitation => 'Convite para grupo';

  @override
  String get accept => 'Aceitar';

  @override
  String get signInRequired => 'É necessário entrar';

  @override
  String get signInRequiredForInvite =>
      'Você precisa entrar para aceitar o convite do grupo.';

  @override
  String get invitationSavedForLater =>
      'Convite salvo.\nSerá processado automaticamente após o login.';

  @override
  String get copyData => 'Copiar dados';

  @override
  String get share => 'Compartilhar';

  @override
  String get enterInviteCode => 'Digite o código de convite';

  @override
  String inviteCodeRecognized(String code) =>
      'Código de convite "$code" reconhecido';

  @override
  String inviteToGroup(String groupName) => 'Convite para "$groupName"';

  @override
  String get friendInvite => 'Convite de amigo';

  @override
  String get friendInviteDesc => 'Acesso a todos os seus grupos';

  @override
  String get individualGroupInvite => 'Convite individual de grupo';

  @override
  String get individualGroupInviteDesc => 'Acesso apenas a este grupo';

  @override
  String get qrScanDialogTitle => 'Convite por QR code';

  @override
  String get qrScanDialogContent =>
      'Escaneie o QR code de convite do grupo\npara entrar no grupo';

  @override
  String get qrManualInputHint =>
      'Se não conseguir escanear o QR code, use o ícone de teclado no canto superior direito para inserir o código manualmente.';

  @override
  String get inviteGenFailed => 'Falha ao gerar convite: ';

  @override
  String get qrCodeHereOverlay => 'Posicione o QR code aqui';

  @override
  String get sharedListAppSubtitle => 'App de listas compartilhadas';

  @override
  String get userNameSetting => 'Configurações de nome de usuário';

  @override
  String get userNameSettingDesc => 'Defina o nome exibido no aplicativo';

  @override
  String get userNameLabel => 'Nome de usuário';

  @override
  String get userNameHint => 'Digite seu nome de exibição';

  @override
  String get userNameRequired => 'Digite um nome de usuário';

  @override
  String get userNameTooShort => 'Nome deve ter pelo menos 2 caracteres';

  @override
  String get userNameTooLong => 'Nome deve ter no máximo 20 caracteres';

  @override
  String get itemNameHintMilk => 'Ex.: Leite';

  @override
  String get intervalNone => '0 (nenhum)';

  @override
  String intervalDaysSuffix(int days) => 'A cada $days dia(s)';

  @override
  String intervalDisplay(int days) => 'A cada ${days}d';

  @override
  String deadlineDisplay(String date) => 'Prazo: $date';

  @override
  String quantityDisplay(int quantity) => 'Qtd: $quantity';

  @override
  String itemDeletedName(String name) => '"$name" excluído';

  @override
  String itemDeleteFailed(String e) => 'Falha ao excluir: $e';

  @override
  String itemDeleteConfirm(String name) => 'Excluir "$name"?';

  @override
  String get errorOccurred => 'Ocorreu um erro';

  @override
  String get copyGroupTooltip => 'Copiar grupo e criar novo';

  @override
  String get createAccountFailed => 'Falha ao criar conta';

  @override
  String groupNameChangedMsg(String name) =>
      'Nome do grupo alterado para "$name"';

  @override
  String get groupNameUpdateFailed => 'Falha ao atualizar nome do grupo';

  @override
  String memberAddedMsg(String name) => '$name adicionado';

  @override
  String get memberAddFailed => 'Falha ao adicionar membro';

  @override
  String currentRoleLabel(String role) => 'Função atual: $role';

  @override
  String get promoteToManager => 'Promover para gerente';

  @override
  String get demoteToMemberAction => 'Rebaixar para membro';

  @override
  String get promoteToManagerDesc =>
      'Promover a gerente permite convidar membros e editar listas.';

  @override
  String get demoteToMemberDesc =>
      'Rebaixar para membro removerá permissões de gerenciamento.';

  @override
  String promotedToManager(String name) => '$name promovido a gerente';

  @override
  String demotedToMemberMsg(String name) => '$name rebaixado para membro';

  @override
  String get doubleTapWhiteboardHint => 'Toque duplo para ver o quadro branco';

  @override
  String get doubleTapToOpen => 'Toque duplo para abrir';

  @override
  String get doubleTapToView => 'Toque duplo para visualizar';

  @override
  String get inviteFromPlusButton =>
      'Use o botão + no canto superior direito\npara convidar membros';
}
