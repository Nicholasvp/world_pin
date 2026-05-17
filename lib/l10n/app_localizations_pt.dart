// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'World Pin';

  @override
  String get tagline => 'Marque suas aventuras pelo mundo';

  @override
  String get login => 'Entrar';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Senha';

  @override
  String get confirmPassword => 'Confirmar senha';

  @override
  String get forgotPassword => 'Esqueci a senha';

  @override
  String get enter => 'Entrar';

  @override
  String get noAccount => 'Não tem conta?';

  @override
  String get createAccount => 'Criar Conta';

  @override
  String get name => 'Nome';

  @override
  String get alreadyHaveAccount => 'Já tem conta?';

  @override
  String get myTrips => 'MINHAS VIAGENS';

  @override
  String get visited => 'Visitados';

  @override
  String get wishlist => 'Desejos';

  @override
  String get markCountry => 'Marcar País';

  @override
  String get searchCountry => 'Para onde você foi?';

  @override
  String get noCountriesFound => 'Nenhum país encontrado.';

  @override
  String get clickToSelect => 'Clique para selecionar';

  @override
  String selectDestination(Object country) {
    return 'O que deseja marcar para $country?';
  }

  @override
  String get alreadyVisited => 'Já visitei';

  @override
  String get wantToGo => 'Desejo ir';

  @override
  String get removeCountry => 'Remover País';

  @override
  String confirmRemove(Object country) {
    return 'Deseja remover $country da sua lista?';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get remove => 'Remover';

  @override
  String removed(Object country) {
    return '$country removido';
  }

  @override
  String error(Object message) {
    return 'Erro: $message';
  }

  @override
  String get emptyVisited => 'Você ainda não marcou nenhum país visitado.';

  @override
  String get emptyWishlist => 'Sua lista de desejos está vazia.';

  @override
  String get logout => 'Sair';

  @override
  String get logoutConfirmTitle => 'Sair da Conta';

  @override
  String get logoutConfirmMessage =>
      'Tem certeza que deseja sair da sua conta?';

  @override
  String get profile => 'Perfil';

  @override
  String get visitedCountriesLabel => 'Países visitados:';
}
