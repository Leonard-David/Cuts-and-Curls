import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/service_model.dart';
import '../../../features/auth/controllers/auth_provider.dart';
import 'package:sheersync/core/constants/colors.dart'; // ADD IMPORT

class AddEditServiceScreen extends StatefulWidget {
  final ServiceModel? service; // If provided, we're editing. If null, we're adding.

  const AddEditServiceScreen({super.key, this.service});

  @override
  State<AddEditServiceScreen> createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends State<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  bool _isLoading = false;
  bool _isActive = true;

  // Common service categories
  final List<String> _categories = [
    'Haircut',
    'Beard Trim',
    'Hair Wash',
    'Styling',
    'Coloring',
    'Treatment',
    'Shave',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill form if editing existing service
    if (widget.service != null) {
      _nameController.text = widget.service!.name;
      _descriptionController.text = widget.service!.description;
      _priceController.text = widget.service!.price.toString();
      _durationController.text = widget.service!.duration.toString();
      _categoryController.text = widget.service!.category ?? '';
      _isActive = widget.service!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final barberId = authProvider.user?.id;

    if (barberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to save services'),
          backgroundColor: AppColors.error, // USE THEME COLOR
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final service = ServiceModel(
        id: widget.service?.id ?? 'service_${DateTime.now().millisecondsSinceEpoch}',
        barberId: barberId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        duration: int.parse(_durationController.text),
        isActive: _isActive,
        createdAt: widget.service?.createdAt ?? DateTime.now(),
        category: _categoryController.text.trim().isEmpty 
            ? null 
            : _categoryController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('services')
          .doc(service.id)
          .set(service.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.service != null 
                ? 'Service updated successfully!' 
                : 'Service added successfully!'
          ),
          backgroundColor: AppColors.success, // USE THEME COLOR
        ),
      );

      Navigator.pop(context); // Return to previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save service: $e'),
          backgroundColor: AppColors.error, // USE THEME COLOR
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteService() async {
    if (widget.service == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: const Text('Are you sure you want to delete this service? This action cannot be undone.'),
        backgroundColor: AppColors.background, // USE THEME COLOR
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary), // USE THEME COLOR
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.error), // USE THEME COLOR
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.service!.id)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Service deleted successfully!'),
          backgroundColor: AppColors.success, // USE THEME COLOR
        ),
      );

      Navigator.pop(context); // Return to previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete service: $e'),
          backgroundColor: AppColors.error, // USE THEME COLOR
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service != null ? 'Edit Service' : 'Add New Service'),
        backgroundColor: AppColors.background, // USE THEME COLOR
        foregroundColor: AppColors.text, // USE THEME COLOR
        elevation: 1,
        actions: [
          if (widget.service != null) // Show delete button only when editing
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteService,
              color: AppColors.error, // USE THEME COLOR
            ),
        ],
      ),
      backgroundColor: AppColors.background, // USE THEME COLOR
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Service Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Service Name *',
                        hintText: 'e.g., Classic Haircut',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a service name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe your service...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Price and Duration in row
                    Row(
                      children: [
                        // Price
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Price (N\$) *',
                              hintText: '0.00',
                              border: OutlineInputBorder(),
                              prefixText: 'N\$',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a price';
                              }
                              final price = double.tryParse(value);
                              if (price == null || price <= 0) {
                                return 'Please enter a valid price';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Duration
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            decoration: const InputDecoration(
                              labelText: 'Duration (minutes) *',
                              hintText: '30',
                              border: OutlineInputBorder(),
                              suffixText: 'min',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter duration';
                              }
                              final duration = int.tryParse(value);
                              if (duration == null || duration <= 0) {
                                return 'Please enter valid duration';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _categoryController.text.isEmpty 
                          ? null 
                          : _categoryController.text,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _categoryController.text = value ?? '';
                        });
                      },
                      hint: const Text('Select a category'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Active Switch
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Service Active',
                              style: TextStyle(fontSize: 16),
                            ),
                            Switch(
                              value: _isActive,
                              onChanged: (value) {
                                setState(() => _isActive = value);
                              },
                              activeColor: AppColors.primary, // USE THEME COLOR
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Save Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveService,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, // USE THEME COLOR
                        foregroundColor: AppColors.onPrimary, // USE THEME COLOR
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.service != null ? 'Update Service' : 'Add Service',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Cancel Button
                    OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.text, // USE THEME COLOR
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}