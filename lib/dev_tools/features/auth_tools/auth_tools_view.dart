import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/dimensions.dart';
import 'package:jwt_decode/jwt_decode.dart';

import '../../../data/token_storage.dart';

class AuthToolsView extends StatefulWidget {
  const AuthToolsView({super.key});

  @override
  State<AuthToolsView> createState() => _AuthToolsViewState();
}

class _AuthToolsViewState extends State<AuthToolsView> {
  final ValueNotifier<String?> _token = ValueNotifier<String?>(null);
  final ValueNotifier<Map<String, dynamic>?> _decodedToken =
      ValueNotifier<Map<String, dynamic>?>(null);
  final ValueNotifier<bool> _showFullToken = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await TokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final decoded = Jwt.parseJwt(token);
        _token.value = token;
        _decodedToken.value = decoded;
      } catch (e) {
        _token.value = token;
        _decodedToken.value = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(Dimen.w16),
      children: [
        Text(
          'AUTH TOKEN',
          style: TextStyle(
            color: Colors.white38,
            fontSize: Dimen.s11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: Dimen.h16),
        ValueListenableBuilder<String?>(
          valueListenable: _token,
          builder: (context, token, _) {
            if (token == null) {
              return Container(
                padding: EdgeInsets.all(Dimen.w24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(Dimen.r12),
                ),
                child: Center(
                  child: Text(
                    'No token stored',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: Dimen.s14,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: [
                _buildTokenCard(token),
                SizedBox(height: Dimen.h16),
                ValueListenableBuilder<Map<String, dynamic>?>(
                  valueListenable: _decodedToken,
                  builder: (context, decoded, _) {
                    if (decoded != null) return _buildDecodedTokenCard(decoded);
                    return const SizedBox.shrink();
                  },
                ),
              ],
            );
          },
        ),
        SizedBox(height: Dimen.h24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_token.value != null) {
                    Clipboard.setData(ClipboardData(text: _token.value!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Token copied')),
                    );
                  }
                },
                icon: Icon(Icons.copy, size: Dimen.h18),
                label: const Text('Copy Token'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(width: Dimen.w12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _loadToken,
                icon: Icon(Icons.refresh, size: Dimen.h18),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTokenCard(String token) {
    return ValueListenableBuilder<bool>(
      valueListenable: _showFullToken,
      builder: (context, showFull, _) {
        final displayToken = showFull
            ? token
            : '${token.substring(0, 20)}...${token.substring(token.length - 10)}';

        return Container(
          padding: EdgeInsets.all(Dimen.w16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(Dimen.r12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'JWT Token',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: Dimen.s11,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _expireToken,
                        child: Text(
                          'Expire',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: Dimen.s11,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _showEditTokenDialog,
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: Dimen.s11,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            _showFullToken.value = !_showFullToken.value,
                        child: Text(
                          showFull ? 'Hide' : 'Show Full',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: Dimen.s11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: Dimen.h8),
              SelectableText(
                displayToken,
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: Dimen.s11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _expireToken() async {
    final token = _token.value;
    if (token == null) return;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return;
      final String payloadStr = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final Map<String, dynamic> payload = jsonDecode(payloadStr);
      payload['exp'] = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 3600;
      final String newPayload = base64Url
          .encode(utf8.encode(jsonEncode(payload)))
          .replaceAll('=', '');
      final expiredToken = '${parts[0]}.$newPayload.${parts[2]}';
      final refreshToken = await TokenStorage.getRefreshToken() ?? '';
      await TokenStorage.saveToken(expiredToken, refreshToken);
      await _loadToken();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token expired (simulated)'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showEditTokenDialog() {
    final controller = TextEditingController(text: _token.value);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: Dimen.w280,
          padding: EdgeInsets.all(Dimen.w20),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(Dimen.r16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit JWT Token',
                style: TextStyle(color: Colors.white, fontSize: Dimen.s16),
              ),
              SizedBox(height: Dimen.h20),
              TextField(
                controller: controller,
                maxLines: 8,
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: Dimen.s12,
                  fontFamily: 'monospace',
                ),
                decoration: const InputDecoration(
                  hintText: 'Paste new JWT token',
                  hintStyle: TextStyle(color: Colors.white30),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
              ),
              SizedBox(height: Dimen.h24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                  SizedBox(width: Dimen.w8),
                  ElevatedButton(
                    onPressed: () async {
                      final newToken = controller.text.trim();
                      if (newToken.isNotEmpty) {
                        final refreshToken =
                            await TokenStorage.getRefreshToken() ?? '';
                        await TokenStorage.saveToken(newToken, refreshToken);
                        await _loadToken();
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecodedTokenCard(Map<String, dynamic> decoded) {
    final exp = decoded['exp'];
    final expiry = exp != null
        ? DateTime.fromMillisecondsSinceEpoch(exp * 1000)
        : null;
    final isExpired = expiry != null && expiry.isBefore(DateTime.now());

    return Container(
      padding: EdgeInsets.all(Dimen.w16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Dimen.r12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DECODED PAYLOAD',
            style: TextStyle(color: Colors.white38, fontSize: Dimen.s11),
          ),
          SizedBox(height: Dimen.h12),
          if (expiry != null) ...[
            _InfoRow(
              label: 'Expires',
              value: expiry.toLocal().toString().split('.').first,
              color: isExpired ? Colors.redAccent : Colors.greenAccent,
            ),
            _InfoRow(
              label: 'Status',
              value: isExpired ? 'EXPIRED' : 'Valid',
              color: isExpired ? Colors.redAccent : Colors.greenAccent,
            ),
            const Divider(color: Colors.white10),
          ],
          if (decoded['sub'] != null)
            _InfoRow(label: 'Subject', value: decoded['sub'].toString()),
          if (decoded['email'] != null)
            _InfoRow(label: 'Email', value: decoded['email'].toString()),
          if (decoded['role'] != null)
            _InfoRow(label: 'Role', value: decoded['role'].toString()),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.label,
    required this.value,
    this.color = Colors.blueAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Dimen.h4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: Dimen.s12),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: Dimen.s12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
