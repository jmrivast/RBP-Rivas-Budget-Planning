import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/license_key_codec.dart';

class KeygenToolScreen extends StatefulWidget {
  const KeygenToolScreen({super.key});

  @override
  State<KeygenToolScreen> createState() => _KeygenToolScreenState();
}

class _KeygenToolScreenState extends State<KeygenToolScreen> {
  final _machineIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _normalizedMachineId = '';
  String _licenseKey = '';

  @override
  void dispose() {
    _machineIdController.dispose();
    super.dispose();
  }

  void _generateKey() {
    if (!_formKey.currentState!.validate()) return;
    final machineId = LicenseKeyCodec.normalizeMachineId(_machineIdController.text);
    final key = LicenseKeyCodec.generateLicenseKey(machineId);
    setState(() {
      _normalizedMachineId = machineId;
      _licenseKey = key;
    });
  }

  Future<void> _copyMachineId() async {
    if (_normalizedMachineId.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _normalizedMachineId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Machine ID copiado')),
    );
  }

  Future<void> _copyKey() async {
    if (_licenseKey.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _licenseKey));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Clave copiada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RBP Keygen Tool'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Generador de licencia por Machine ID',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pega el Machine ID del cliente y genera la clave.',
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _machineIdController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Machine ID',
                      hintText: 'Ejemplo: AB12CD34EF56',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final normalized = LicenseKeyCodec.normalizeMachineId(value ?? '');
                      if (normalized.length < 6) {
                        return 'Machine ID invalido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _generateKey,
                    icon: const Icon(Icons.vpn_key_rounded),
                    label: const Text('Generar clave'),
                  ),
                  const SizedBox(height: 24),
                  if (_normalizedMachineId.isNotEmpty) ...[
                    _ResultField(
                      label: 'Machine ID normalizado',
                      value: _normalizedMachineId,
                      onCopy: _copyMachineId,
                    ),
                    const SizedBox(height: 12),
                    _ResultField(
                      label: 'Clave de licencia',
                      value: _licenseKey,
                      onCopy: _copyKey,
                      highlighted: true,
                    ),
                  ],
                  const Spacer(),
                  const Text(
                    'Nota: esta herramienta usa el mismo algoritmo y SALT de la app.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultField extends StatelessWidget {
  const _ResultField({
    required this.label,
    required this.value,
    required this.onCopy,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: highlighted ? const Color(0xFF1565C0) : Colors.black26),
        borderRadius: BorderRadius.circular(10),
        color: highlighted ? const Color(0xFFF1F7FF) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            tooltip: 'Copiar',
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
    );
  }
}
