import 'package:easy_localization/easy_localization.dart';
import '../shared/widgets/placeholder_page.dart';

class SettingsPage extends PlaceholderPage {
  SettingsPage({super.key})
      : super(
          title: 'settings.title'.tr(),
          message: 'Temas, acentos, idioma e preferências — Fase 1.',
        );
}
