import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/service_model.dart';
import '../../../data/repositories/service_repository.dart';

class AddEditServiceScreen extends StatefulWidget {
  final ServiceModel? service;

  const AddEditServiceScreen({super.key, this.service});

  @override
  State<AddEditServiceScreen> createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends State<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceRepo = ServiceRepository();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _nameController.text = widget.service!.name;
      _priceController.text = widget.service!.price.toString();
      _durationController.text = widget.service!.duration.toString();
      _descriptionController.text = widget.service!.description;
    }
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate() || user == null) return;
    setState(() => _saving = true);

    try {
      final serviceData = ServiceModel(
        id: widget.service?.id ?? '',
        barberId: user!.uid,
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        duration: int.parse(_durationController.text),
        description: _descriptionController.text.trim(),
      );

      if (widget.service == null) {
        await _serviceRepo.addService(serviceData);
      } else {
        await _serviceRepo.updateService(widget.service!.id, serviceData.toMap());
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service saved successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Save service error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving service: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.service == null ? 'Add Service' : 'Edit Service'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Service Name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (USD)'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter price' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Duration (minutes)'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter duration' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              _saving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveService,
                      child: const Text('Save Service'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
