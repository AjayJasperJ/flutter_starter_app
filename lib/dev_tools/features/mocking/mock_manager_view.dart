import 'package:flutter/material.dart';
import '../../../core/constants/dimensions.dart';
import '../feature_flags/feature_flag_controller.dart';
import 'mock_controller.dart';

class MockManagerView extends StatefulWidget {
  const MockManagerView({super.key});

  @override
  State<MockManagerView> createState() => _MockManagerViewState();
}

class _MockManagerViewState extends State<MockManagerView> {
  final MockController _mockController = MockController();
  final FeatureFlagController _flagController = FeatureFlagController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ValueListenableBuilder<List<MockRule>>(
            valueListenable: _mockController.rules,
            builder: (context, rules, _) {
              if (rules.isEmpty) {
                return _buildEmptyState();
              }
              return ListView.separated(
                padding: EdgeInsets.all(Dimen.w16),
                itemCount: rules.length,
                separatorBuilder: (_, _) => SizedBox(height: Dimen.h12),
                itemBuilder: (context, index) => _MockRuleCard(
                  rule: rules[index],
                  onToggle: () => _mockController.toggleRule(rules[index].id),
                  onDelete: () => _mockController.deleteRule(rules[index].id),
                  onEdit: () => _showRuleDialog(rules[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(Dimen.w16),
      decoration: BoxDecoration(
        // color: const Color(0xFF0D1117),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'API Mocking Engine',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Dimen.s16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Intercept and override network responses',
                  style: TextStyle(color: Colors.white60, fontSize: Dimen.s11),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<Map<String, bool>>(
            valueListenable: _flagController.flags,
            builder: (context, flags, _) {
              final isEnabled = flags['Mock API Responses'] ?? false;
              return Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: isEnabled,
                  activeThumbColor: Colors.blueAccent,
                  onChanged: (val) =>
                      _flagController.setFlag('Mock API Responses', val),
                ),
              );
            },
          ),
          SizedBox(width: Dimen.w8),
          IconButton(
            icon: Icon(Icons.add_circle, color: Colors.blueAccent, size: 28),
            onPressed: () => _showRuleDialog(null),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Icon(Icons.terminal, size: 48, color: Colors.white10));
  }

  void _showRuleDialog(MockRule? rule) {
    showDialog(
      context: context,
      builder: (context) => _RuleEditDialog(
        rule: rule,
        onSave: (newRule) {
          if (rule == null) {
            _mockController.addRule(newRule);
          } else {
            _mockController.updateRule(newRule);
          }
        },
      ),
    );
  }
}

class _MockRuleCard extends StatelessWidget {
  final MockRule rule;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _MockRuleCard({
    required this.rule,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final methodColor = _getMethodColor(rule.method);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2329),
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: methodColor, width: 4)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rule.pathPattern,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: Dimen.s12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Dimen.h4),
                  Row(
                    children: [
                      Text(
                        rule.method,
                        style: TextStyle(
                          color: methodColor,
                          fontSize: Dimen.s10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '•',
                          style: TextStyle(color: Colors.white24),
                        ),
                      ),
                      Text(
                        '${rule.statusCode}',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: Dimen.s10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (rule.useRegex) ...[
                        SizedBox(width: Dimen.w8),
                        _buildBadge('REGEX', Colors.orange),
                      ],
                      if (rule.requestBodyPattern.isNotEmpty) ...[
                        SizedBox(width: Dimen.w8),
                        _buildBadge('BODY', Colors.purpleAccent),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionIcon(Icons.edit, onEdit),
                SizedBox(width: Dimen.w8),
                _buildActionIcon(Icons.delete_outline, onDelete),
                SizedBox(width: Dimen.w12),
                Theme(
                  data: ThemeData(unselectedWidgetColor: Colors.white24),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: rule.isEnabled,
                      onChanged: (_) => onToggle(),
                      activeColor: methodColor,
                      checkColor: const Color(0xFF1E2329),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: CircleBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: Colors.white54),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'GET':
        return Colors.greenAccent;
      case 'POST':
        return Colors.blueAccent;
      case 'PUT':
        return Colors.orangeAccent;
      case 'DELETE':
        return Colors.redAccent;
      default:
        return Colors.white60;
    }
  }
}

class _RuleEditDialog extends StatefulWidget {
  final MockRule? rule;
  final Function(MockRule) onSave;

  const _RuleEditDialog({this.rule, required this.onSave});

  @override
  State<_RuleEditDialog> createState() => _RuleEditDialogState();
}

class _RuleEditDialogState extends State<_RuleEditDialog> {
  late TextEditingController _patternController;
  late TextEditingController _requestBodyPatternController;
  late TextEditingController _statusCodeController;
  late TextEditingController _bodyController;
  late String _method;
  late int _statusCode;
  late bool _useRegex;

  @override
  void initState() {
    super.initState();
    _patternController = TextEditingController(
      text: widget.rule?.pathPattern ?? '',
    );
    _requestBodyPatternController = TextEditingController(
      text: widget.rule?.requestBodyPattern ?? '',
    );
    _statusCode = widget.rule?.statusCode ?? 200;
    _statusCodeController = TextEditingController(text: _statusCode.toString());
    _bodyController = TextEditingController(
      text: widget.rule?.responseBody ?? '{}',
    );
    _method = widget.rule?.method ?? 'GET';
    _useRegex = widget.rule?.useRegex ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: Dimen.w280,
        padding: EdgeInsets.all(Dimen.w15),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(Dimen.r16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.rule == null ? 'Add Mock Rule' : 'Edit Mock Rule',
              style: TextStyle(
                color: Colors.white,
                fontSize: Dimen.s16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Dimen.h20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _method,
                      dropdownColor: const Color(0xFF161B22),
                      items: ['ANY', 'GET', 'POST', 'PUT', 'DELETE']
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                m,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                  fontSize: Dimen.s11,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _method = val!),
                      decoration: InputDecoration(
                        labelText: 'HTTP Method',
                        labelStyle: TextStyle(color: Colors.white60),
                      ),
                    ),
                    SizedBox(height: Dimen.h12),
                    TextField(
                      controller: _patternController,
                      cursorColor: Colors.blueAccent,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: Dimen.s11,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Path Pattern',
                        labelStyle: TextStyle(
                          color: Colors.white60,
                          fontFamily: 'monospace',
                          fontSize: Dimen.s12,
                        ),
                        hintText: '/api/v1/resource',
                        hintStyle: TextStyle(
                          color: Colors.white24,
                          fontFamily: 'monospace',
                          fontSize: Dimen.s11,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _useRegex,
                          onChanged: (val) => setState(() => _useRegex = val!),
                          activeColor: Colors.blueAccent,
                        ),
                        Text(
                          'Use Regular Expression',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: Dimen.s11,
                          ),
                        ),
                      ],
                    ),
                    if (['POST', 'PUT', 'DELETE', 'PATCH'].contains(_method) ||
                        _method == 'ANY') ...[
                      SizedBox(height: Dimen.h12),
                      TextField(
                        controller: _requestBodyPatternController,
                        cursorColor: Colors.blueAccent,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: Dimen.s11, // Reduced font size
                        ),
                        decoration: InputDecoration(
                          labelText: 'Request Body Match (Optional)',
                          labelStyle: TextStyle(
                            color: Colors.white60,
                            fontSize: Dimen.s12, // Reduced label size
                          ),
                          hintText: '"userId": 123',
                          hintStyle: TextStyle(
                            color: Colors.white24,
                            fontSize: Dimen.s11, // Reduced hint size
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: Dimen.h12),

                    TextField(
                      controller: _statusCodeController,
                      keyboardType: TextInputType.number,
                      cursorColor: Colors.blueAccent,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: Dimen.s11,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Status Code',
                        labelStyle: TextStyle(color: Colors.white60),
                      ),
                      onChanged: (val) =>
                          _statusCode = int.tryParse(val) ?? 200,
                    ),
                    SizedBox(height: Dimen.h12),
                    Text(
                      'Response Body (JSON)',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: Dimen.s11,
                      ),
                    ),
                    SizedBox(height: Dimen.h4),
                    TextField(
                      controller: _bodyController,
                      maxLines: 8,
                      cursorColor: Colors.blueAccent,
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontSize: Dimen.s12,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: Dimen.h24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                SizedBox(width: Dimen.w8),
                ElevatedButton(
                  onPressed: () {
                    final newRule = MockRule(
                      id:
                          widget.rule?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      pathPattern: _patternController.text,
                      method: _method,
                      statusCode: _statusCode,
                      responseBody: _bodyController.text,
                      requestBodyPattern: _requestBodyPatternController.text,
                      useRegex: _useRegex,
                      isEnabled:
                          widget.rule?.isEnabled ??
                          true, // Changed from isActive to isEnabled
                    );
                    widget.onSave(newRule);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: Text(
                    'Save Rule',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
