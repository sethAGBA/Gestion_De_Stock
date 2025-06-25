import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'client_form_controller.dart';
import 'client_form_sections.dart';
import 'client_form_widgets.dart';

class AddClientPage extends StatefulWidget {
  const AddClientPage({super.key});

  @override
  State<AddClientPage> createState() => _AddClientPageState();
}

class _AddClientPageState extends State<AddClientPage> {
  final ClientFormController _controller = ClientFormController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.background,
                  Theme.of(context).colorScheme.background.withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  buildModernHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Form(
                        key: _controller.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            buildClientTypeSection(
                              context,
                              _controller,
                              (value) => setState(() => _controller.selectedClientType = value!),
                              (value) => setState(() => _controller.selectedGender = value!),
                              (values) => setState(() => _controller.selectedServices = values),
                            ),
                            const SizedBox(height: 24),
                            buildPersonalInfoSection(context, _controller, setState),
                            const SizedBox(height: 24),
                            buildDeliverySection(context, _controller),
                            const SizedBox(height: 24),
                            buildMeasurementsSection(context, _controller),
                            const SizedBox(height: 24),
                            buildNotesSection(context, _controller),
                            const SizedBox(height: 32),
                            buildFuturisticSaveButton(
                              context,
                              () {
                                try {
                                  final clientData = {
                                    'clientType': _controller.selectedClientType,
                                    'gender': _controller.selectedGender,
                                    'services': _controller.selectedServices.join(','),
                                    for (var entry in _controller.controllers.entries)
                                      entry.key: entry.value.text,
                                    'createdAt': DateTime.now().toIso8601String(),
                                    'status': 'active',
                                  };
                                  _controller.saveClient(context, clientData);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Erreur lors de l\'enregistrement: $e',
                                        style: TextStyle(fontFamily: GoogleFonts.roboto().fontFamily),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ).animate().fadeIn(delay: 200.ms),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 30),
              onPressed: () => Navigator.pop(context),
            ).animate().fadeIn(duration: 300.ms),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}