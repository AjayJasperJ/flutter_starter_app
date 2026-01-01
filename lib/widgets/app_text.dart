import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/dimensions.dart';

enum Decorate {
  underline(TextDecoration.underline),
  linethrough(TextDecoration.lineThrough),
  none(TextDecoration.none),
  overline(TextDecoration.overline);

  final TextDecoration value;
  const Decorate(this.value);
}

enum Font {
  black(FontWeight.w800),
  bold(FontWeight.w700),
  semibold(FontWeight.w600),
  regular(FontWeight.w400),
  medium(FontWeight.w500),
  lite(FontWeight.w300);

  final FontWeight value;
  const Font(this.value);
}

class Txt extends StatelessWidget {
  final String data;
  final int? maxlines;
  final Font weight;
  final TextStyle? textstyle;
  final double size;
  final Decorate decorate;
  final TextOverflow? overflow;
  final Color? color;
  final double? spacing;
  final double? height;
  final TextAlign? align;

  const Txt(
    this.data, {
    super.key,
    this.maxlines,
    this.textstyle,
    this.align,
    this.decorate = Decorate.none,
    this.overflow,
    this.size = 24,
    this.color,
    this.weight = Font.regular,
    this.spacing,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final deviceTheme = Theme.of(context);
    return Text(
      data,
      maxLines: maxlines,
      textAlign: align,

      style: (textstyle != null)
          ? textstyle
          : TextStyle(
              fontWeight: weight.value,
              fontSize: size,
              decoration: decorate.value,
              color: color ?? deviceTheme.colorScheme.onSurface,
              overflow: overflow,
              wordSpacing: spacing,
              height: height,
              fontFamily: "DMSans",
            ),
    );
  }
}

class Txtfield extends StatefulWidget {
  final Key? fieldkey;
  final TextEditingController? controller;
  final BorderRadius? radius;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? hintText;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction? textInputAction;
  final bool? isPrefix;
  final List<TextInputFormatter>? inputformat;
  final TextInputType? keyboardtype;
  final bool? hidepass;
  final GestureTapCallback? onTap;
  final bool? readonly;
  final void Function(String)? onSubmit;
  final void Function(String)? onChange;
  final AutovalidateMode? autoValid;
  final int? errorMaxLines;
  final EdgeInsets? contentPadding;

  const Txtfield({
    super.key,
    this.fieldkey,
    this.radius,
    this.onTap,
    this.contentPadding,
    this.controller,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.hintText,
    this.focusNode,
    this.nextFocusNode,
    this.textInputAction,
    this.isPrefix,
    this.inputformat,
    this.keyboardtype,
    this.hidepass,
    this.readonly,
    this.onSubmit,
    this.autoValid,
    this.errorMaxLines,
    this.onChange,
  });

  @override
  State<Txtfield> createState() => _TxtfieldState();
}

class _TxtfieldState extends State<Txtfield> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    if (_hasSubmitted) {
      _validate();
    }
  }

  void _validate() {
    if (widget.validator == null) return;
    widget.validator!(_controller.text);
  }

  String? _validator(String? value) {
    return widget.validator?.call(value);
  }

  void _handleSubmitted(String value) {
    setState(() => _hasSubmitted = true);
    _validate();

    if (widget.nextFocusNode != null) {
      widget.nextFocusNode!.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StatefulBuilder(
      builder: (context, setState) {
        return TextFormField(
          autocorrect: false,
          enableSuggestions: false,
          style: TextStyle(
            fontWeight: Font.medium.value,
            color: Colors.black,
            fontFamily: 'DMSans',
            fontSize: Dimen.s16,
          ),
          onChanged: widget.onChange,
          key: widget.fieldkey,
          obscureText: widget.hidepass ?? false,
          onTap: widget.onTap,
          controller: _controller,
          focusNode: _focusNode,
          textInputAction:
              widget.textInputAction ??
              (widget.nextFocusNode != null
                  ? TextInputAction.next
                  : TextInputAction.done),
          onFieldSubmitted:
              widget.onSubmit ??
              (value) {
                setState(() => _hasSubmitted = true);
                _handleSubmitted(value);
              },
          validator: _validator,
          readOnly: widget.readonly ?? false,
          inputFormatters: widget.inputformat,
          keyboardType: widget.keyboardtype,
          autovalidateMode: widget.autoValid ?? AutovalidateMode.onUnfocus,
          decoration: InputDecoration(
            isCollapsed: false,
            contentPadding:
                widget.contentPadding ??
                EdgeInsets.symmetric(
                  vertical: Dimen.h15,
                  horizontal: Dimen.w20,
                ),
            prefixIcon: (widget.prefixIcon != null)
                ? Container(
                    margin: EdgeInsets.only(left: 20, right: 5),
                    height: 25,
                    width: 25,
                    child: widget.prefixIcon,
                  )
                : null,
            suffixIcon: widget.suffixIcon,
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: Colors.grey,
              fontWeight: Font.medium.value,
              fontFamily: 'DMSans',
              fontSize: Dimen.s15,
            ),
            // Use a compact error style to avoid extra vertical padding
            errorStyle: TextStyle(
              fontSize: Dimen.s12,
              height: 1.0,
              color: Colors.redAccent,
              fontWeight: Font.medium.value,
            ),
            // Allow multi-line error text (default to 2 lines if not provided)
            errorMaxLines: widget.errorMaxLines ?? 3,
            focusedBorder: OutlineInputBorder(
              borderRadius: widget.radius ?? BorderRadius.circular(Dimen.r99),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: Dimen.s2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: widget.radius ?? BorderRadius.circular(Dimen.r99),
              borderSide: BorderSide(color: Colors.grey, width: Dimen.s1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: widget.radius ?? BorderRadius.circular(Dimen.r99),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: Dimen.s2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: widget.radius ?? BorderRadius.circular(Dimen.r99),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: Dimen.s1,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }
}

class Txtotpfield extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onCompleted;

  const Txtotpfield({super.key, this.length = 4, this.onCompleted});

  @override
  State<Txtotpfield> createState() => _TxtotpfieldState();
}

class _TxtotpfieldState extends State<Txtotpfield> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  String _otp = '';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (index) =>
          FocusNode(onKeyEvent: (node, event) => _handleKeyEvent(index, event)),
    );
  }

  KeyEventResult _handleKeyEvent(int index, KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        event is KeyDownEvent) {
      // Handle backspace for both empty and filled fields
      if (_controllers[index].text.isNotEmpty) {
        // If current field has text, clear it
        _controllers[index].clear();
        _updateOtp();
      } else if (index > 0) {
        // If current field is empty, move to previous field and clear it
        _controllers[index - 1].clear();
        _focusNodes[index - 1].requestFocus();
        _updateOtp();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _handleTextChange(int index, String value) {
    if (value.length > 1) {
      _handlePaste(index, value);
      return;
    }

    if (value.isNotEmpty) {
      final digit = value[value.length - 1];
      if (_controllers[index].text != digit) {
        _controllers[index]
          ..text = digit
          ..selection = const TextSelection.collapsed(offset: 1);
      }

      final nextEmpty = _controllers.indexWhere((c) => c.text.isEmpty);
      if (nextEmpty != -1) {
        _focusNodes[nextEmpty].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
    // Removed the else block that was calling _handleBackspace
    // Backspace is now only handled by _handleKeyEvent

    _updateOtp();
  }

  void _handlePaste(int startIndex, String digitsOnly) {
    if (digitsOnly.isEmpty) return;

    var targetIndex = startIndex;
    for (int i = 0; i < digitsOnly.length && targetIndex < widget.length; i++) {
      final digit = digitsOnly[i];
      if (_controllers[targetIndex].text != digit) {
        _controllers[targetIndex]
          ..text = digit
          ..selection = TextSelection.collapsed(offset: digit.length);
      }
      targetIndex++;
    }

    final nextEmpty = _controllers.indexWhere((c) => c.text.isEmpty);
    if (nextEmpty != -1) {
      _focusNodes[nextEmpty].requestFocus();
    } else if (widget.length > 0) {
      _focusNodes[widget.length - 1].unfocus();
    }

    _updateOtp();
  }

  void _updateOtp() {
    final newOtp = _controllers.map((c) => c.text).join();
    if (newOtp != _otp) {
      _otp = newOtp;
      widget.onCompleted?.call(_otp);
    }
  }

  void _handleTap(int index) {
    // Focus tapped field if empty, otherwise first empty field
    if (_controllers[index].text.isEmpty) {
      _focusNodes[index].requestFocus();
    } else {
      final firstEmptyIndex = _controllers.indexWhere((c) => c.text.isEmpty);
      if (firstEmptyIndex != -1) {
        _focusNodes[firstEmptyIndex].requestFocus();
      } else {
        _focusNodes[index].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.length * 2 - 1, (i) {
          if (i.isOdd) {
            return SizedBox(width: 12); // spacing between fields
          }
          final index = i ~/ 2;
          return Flexible(
            child: GestureDetector(
              onTap: () => _handleTap(index),
              child: TextFormField(
                style: TextStyle(
                  fontWeight: Font.medium.value,
                  fontSize: 25,
                  color: Theme.of(context).colorScheme.primary,
                ),
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _OtpPasteTextInputFormatter(
                    index: index,
                    onPaste: _handlePaste,
                  ),
                  LengthLimitingTextInputFormatter(1),
                ],
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 15),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: .5),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) => _handleTextChange(index, value),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}

class _OtpPasteTextInputFormatter extends TextInputFormatter {
  const _OtpPasteTextInputFormatter({
    required this.index,
    required this.onPaste,
  });

  final int index;
  final void Function(int startIndex, String pastedValue) onPaste;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length > 1) {
      final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
      onPaste(index, digitsOnly);
      final firstDigit = digitsOnly.isNotEmpty ? digitsOnly[0] : '';
      return TextEditingValue(
        text: firstDigit,
        selection: TextSelection.collapsed(offset: firstDigit.isEmpty ? 0 : 1),
      );
    }
    return newValue;
  }
}

SizedBox txtfieldicon(BuildContext context, String imagepath, {Color? color}) {
  return SizedBox(
    height: Dimen.h24,
    width: Dimen.w24,
    child: Center(
      child: Image.asset(imagepath, height: Dimen.h24, color: color),
    ),
  );
}
