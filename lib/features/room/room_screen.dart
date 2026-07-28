import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/room_provider.dart';
import '../../providers/api_provider.dart';

class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({super.key});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  final _aliasController = TextEditingController();
  final _codeController = TextEditingController();
  final _serverController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _aliasController.dispose();
    _codeController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  void _showServerConfig() {
    ref.read(apiServiceProvider).getBaseUrl().then((url) {
      _serverController.text = url;
    });
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Servidor'),
        content: TextField(
          controller: _serverController,
          decoration: const InputDecoration(
            labelText: 'URL del backend',
            hintText: 'http://192.168.1.x:3000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final url = _serverController.text.trim();
              if (url.isNotEmpty) {
                ref.read(apiClientProvider).setBaseUrl(url);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    final isConnectionError = roomState.error != null &&
        (roomState.error!.toLowerCase().contains('connection') ||
         roomState.error!.toLowerCase().contains('timeout') ||
         roomState.error!.toLowerCase().contains('socketexception'));

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: _showServerConfig,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.blue, AppColors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 50),
                ),
                const SizedBox(height: 24),
                Text(
                  'Cash Management',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Controla tus finanzas en pareja',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _aliasController,
                  decoration: const InputDecoration(
                    labelText: 'Tu nombre',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 24),
                if (roomState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Text(
                          roomState.error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        if (isConnectionError) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _showServerConfig,
                            icon: const Icon(Icons.wifi, size: 16),
                            label: const Text('Configurar servidor'),
                          ),
                        ],
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: roomState.isLoading
                        ? null
                        : () {
                            if (_aliasController.text.trim().isEmpty) return;
                            ref
                                .read(roomProvider.notifier)
                                .createRoom(_aliasController.text.trim());
                          },
                    child: roomState.isLoading && !_isJoining
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Crear Sala'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.textSecondary.withValues(alpha: 0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('o', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                    ),
                    Expanded(child: Divider(color: AppColors.textSecondary.withValues(alpha: 0.3))),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Código de sala',
                    prefixIcon: Icon(Icons.group),
                    hintText: 'Ej: A3B2C1',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: roomState.isLoading
                        ? null
                        : () {
                            if (_aliasController.text.trim().isEmpty ||
                                _codeController.text.trim().isEmpty) { return; }
                            setState(() => _isJoining = true);
                            ref
                                .read(roomProvider.notifier)
                                .joinRoom(_codeController.text.trim(), _aliasController.text.trim())
                                .then((v) { setState(() => _isJoining = false); return v; });
                          },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.purple),
                      foregroundColor: AppColors.purple,
                    ),
                    child: roomState.isLoading && _isJoining
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Unirse a Sala'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
