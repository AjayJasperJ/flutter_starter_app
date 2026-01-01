import 'package:flutter/material.dart';

bool _isDialogOpen = false;

void openDialog(BuildContext context) {
  if (_isDialogOpen) return;
  _isDialogOpen = true;

  showDialog(
    barrierColor: Colors.black.withValues(alpha: .1),
    context: context,
    barrierDismissible: false,
    useRootNavigator: false,
    builder: (BuildContext context) {
      return PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    },
  );
}

void closeDialog(BuildContext context) {
  if (_isDialogOpen) {
    Navigator.of(context, rootNavigator: true).pop();
    _isDialogOpen = false;
  }
}
