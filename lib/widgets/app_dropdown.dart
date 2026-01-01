import 'package:flutter/material.dart';
import '../../../core/constants/dimensions.dart';
import '../../../widgets/app_text.dart';

class DefaultDropdown<T> extends StatelessWidget {
  final T? value; // selected item
  final List<T> items; // list of items
  final String hint; // hint label
  final ValueChanged<T> onChanged;
  final double? buttonHeight;
  final double? buttonWidth;
  final EdgeInsets? margin;

  /// Required callback to convert T to text
  final String Function(T item) itemLabel;

  const DefaultDropdown({
    super.key,
    this.value,
    this.margin,
    this.buttonHeight,
    this.buttonWidth,
    required this.items,
    required this.hint,
    required this.onChanged,
    required this.itemLabel, // <-- important
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: buttonHeight,
      margin: margin,
      padding: EdgeInsets.symmetric(horizontal: Dimen.w15),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimen.r99),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          alignment: Alignment.centerLeft,
          borderRadius: BorderRadius.circular(Dimen.r10),
          value: items.contains(value) ? value : null,
          hint: Txt(hint, size: Dimen.s14, weight: Font.medium),
          isExpanded: true,
          enableFeedback: false,
          icon: Icon(Icons.keyboard_arrow_down_rounded),
          iconSize: Dimen.r18,
          onChanged: (v) => onChanged(v as T),
          style: TextStyle(fontSize: Dimen.s14, fontWeight: Font.medium.value),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Center(
                    child: Txt(
                      itemLabel(item), // display string
                      size: Dimen.s14,
                      weight: Font.semibold,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
