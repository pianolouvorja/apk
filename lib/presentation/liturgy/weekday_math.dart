/// Mapeamento do weekday do DateTime (seg=1..dom=7) para LiturgyWeekday.
///
/// liturgyDayTabOrder segue ordem dom, seg, ter, qua, qui, sex, sab —
/// ou seja, indice 0 = domingo. O correto e `wd % 7`:
/// seg(1)%7=1 -> monday ... sab(6)%7=6 -> saturday, dom(7)%7=0 -> sunday.
/// O bug historico usava `wd - 1`, que mapeava sabado -> friday.
library;

import '../../domain/entities/liturgy_item.dart';

/// Converte o [DateTime.weekday] (1=segunda .. 7=domingo) no enum do app.
LiturgyWeekday weekdayFromDart(int dartWeekday) {
  assert(dartWeekday >= 1 && dartWeekday <= 7, 'weekday invalido');
  return liturgyDayTabOrder[dartWeekday % 7];
}
