import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'client_form_controller.dart';
import 'client_form_sections.dart';
import 'client_form_widgets.dart';
import 'clients_page.dart';

class EditClientPage extends StatefulWidget {
  final Client client;

  const EditClientPage({super.key, required this.client});

  @override
  State<EditClientPage> createState() => _EditClientPageState();
}

class _EditClientPageState extends State<EditClientPage> {
  late ClientFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ClientFormController();
    _controller.selectedClientType = widget.client.clientType ?? 'Adulte';
    _controller.selectedGender = widget.client.gender ?? 'Homme';
    _controller.selectedServices = widget.client.services;
    _controller.controllers['name']!.text = widget.client.name;
    _controller.controllers['phone']!.text = widget.client.phone;
    _controller.controllers['email']!.text = widget.client.email;
    _controller.controllers['address']!.text = widget.client.address;
    _controller.controllers['notes']!.text = widget.client.notes;
    _controller.controllers['profession']!.text = widget.client.profession;
    _controller.controllers['birthdate']!.text = widget.client.birthdate;
    _controller.controllers['photo']!.text = widget.client.photo;
    _controller.controllers['deliveryDate']!.text = widget.client.deliveryDate;
    for (var entry in widget.client.measurements.entries) {
      _controller.controllers[entry.key]?.text = entry.value?.toString() ?? '';
    }
  }

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
                  buildModernHeader(context, title: 'MODIFIER CLIENT'),
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
                                  _controller.saveClient(context, clientData, clientId: widget.client.id);
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