import 'package:easy_localization/easy_localization.dart';
import '../shared/widgets/placeholder_page.dart';

class BiblePage extends PlaceholderPage {
  BiblePage({super.key})
      : super(
          title: 'bible.title'.tr(),
          message: 'Livros, capítulos e versículos — Fase 3.',
        );
}
