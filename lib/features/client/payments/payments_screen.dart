import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/models/payment_model.dart';
import 'package:sheersync/data/providers/payment_provider.dart';
import 'package:sheersync/data/providers/auth_provider.dart';
import 'package:sheersync/features/client/payments/payment_details_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Filter states
  String _searchQuery = '';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final paymentProvider = context.read<PaymentProvider>();
      
      if (authProvider.user != null) {
        // Load client payments with real-time updates
        paymentProvider.loadClientPayments(authProvider.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<PaymentProvider>(context);
    Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header with Balance
          _buildBalanceHeader(paymentProvider),
          // Search and Filter Bar
          _buildSearchFilterBar(),
          // Tab Bar
          _buildTabBar(),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pending Tab
                _buildPaymentsList(
                  _filterPayments(paymentProvider.clientPayments, status: 'pending'),
                  paymentProvider.isLoading,
                  'No pending payments',
                  'You don\'t have any pending payments.',
                ),
                // Completed Tab
                _buildPaymentsList(
                  _filterPayments(paymentProvider.clientPayments, status: 'completed'),
                  paymentProvider.isLoading,
                  'No completed payments',
                  'Your completed payments will appear here.',
                ),
                // Failed Tab
                _buildPaymentsList(
                  _filterPayments(paymentProvider.clientPayments, status: 'failed'),
                  paymentProvider.isLoading,
                  'No failed payments',
                  'Your failed payments will appear here.',
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addPaymentMethod(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBalanceHeader(PaymentProvider paymentProvider) {
    final totalSpent = paymentProvider.clientPayments
        .where((payment) => payment.status == 'completed')
        .fold(0.0, (sum, payment) => sum + payment.amount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'Total Spent',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'N\$${totalSpent.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBalanceStat(
                'Pending',
                paymentProvider.clientPayments
                    .where((payment) => payment.status == 'pending')
                    .length
                    .toString(),
                AppColors.accent,
              ),
              _buildBalanceStat(
                'Completed',
                paymentProvider.clientPayments
                    .where((payment) => payment.status == 'completed')
                    .length
                    .toString(),
                AppColors.success,
              ),
              _buildBalanceStat(
                'Failed',
                paymentProvider.clientPayments
                    .where((payment) => payment.status == 'failed')
                    .length
                    .toString(),
                AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceStat(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search payments...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
          ),
          const SizedBox(height: 12),
          // Date Filter
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _selectDateRange,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _dateRange == null
                            ? 'Select Date Range'
                            : '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_dateRange != null)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _dateRange = null;
                    });
                  },
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear Date Filter',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'Completed'),
          Tab(text: 'Failed'),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(
    List<PaymentModel> payments,
    bool isLoading,
    String emptyTitle,
    String emptySubtitle,
  ) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (payments.isEmpty) {
      return _buildEmptyState(emptyTitle, emptySubtitle);
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index];
          return _buildPaymentCard(payment);
        },
      ),
    );
  }

  Widget _buildPaymentCard(PaymentModel payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewPaymentDetails(payment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Status and Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(payment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      payment.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(payment.status),
                      ),
                    ),
                  ),
                  Text(
                    'N\$${payment.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Payment Details
              _buildPaymentDetail('Professional', payment.barberId), // Would need barber name lookup
              const SizedBox(height: 8),
              _buildPaymentDetail('Appointment', payment.appointmentId),
              const SizedBox(height: 8),
              _buildPaymentDetail('Method', payment.paymentMethod),
              const SizedBox(height: 8),
              _buildPaymentDetail('Date', DateFormat('MMM d, yyyy • HH:mm').format(payment.createdAt)),
              // Transaction ID if available
              if (payment.transactionId != null) ...[
                const SizedBox(height: 8),
                _buildPaymentDetail('Transaction ID', payment.transactionId!),
              ],
              // Actions based on status
              if (payment.status == 'pending') ..._buildPendingActions(payment),
              if (payment.status == 'failed') ..._buildFailedActions(payment),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentDetail(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPendingActions(PaymentModel payment) {
    return [
      const SizedBox(height: 12),
      const Divider(),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _retryPayment(payment),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
              ),
              child: const Text('Pay Now'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _cancelPayment(payment),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
              ),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildFailedActions(PaymentModel payment) {
    return [
      const SizedBox(height: 12),
      const Divider(),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _retryPayment(payment),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Retry Payment'),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...List.generate(4, (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyStateIcon(title),
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEmptyStateIcon(String title) {
    if (title.contains('pending')) return Icons.pending_actions_rounded;
    if (title.contains('completed')) return Icons.check_circle_outline_rounded;
    if (title.contains('failed')) return Icons.error_outline_rounded;
    return Icons.payment_rounded;
  }

  // Filtering methods
  List<PaymentModel> _filterPayments(
    List<PaymentModel> payments, {
    required String status,
  }) {
    var filtered = payments.where((payment) {
      // Status filter
      if (payment.status != status) {
        return false;
      }
      
      // Date range filter
      if (_dateRange != null) {
        if (payment.createdAt.isBefore(_dateRange!.start) || 
            payment.createdAt.isAfter(_dateRange!.end)) {
          return false;
        }
      }
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesAmount = payment.amount.toString().contains(query);
        final matchesMethod = payment.paymentMethod.toLowerCase().contains(query);
        final matchesTransaction = payment.transactionId?.toLowerCase().contains(query) ?? false;
        
        if (!matchesAmount && !matchesMethod && !matchesTransaction) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return filtered;
  }

  // Action methods
  Future<void> _refreshData() async {
    final authProvider = context.read<AuthProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    
    if (authProvider.user != null) {
      paymentProvider.loadClientPayments(authProvider.user!.id);
    }
  }

  void _viewPaymentDetails(PaymentModel payment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentDetailsScreen(payment: payment),
      ),
    );
  }

  void _retryPayment(PaymentModel payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retry Payment'),
        content: const Text('This will attempt to process the payment again. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processPaymentRetry(payment);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _processPaymentRetry(PaymentModel payment) {
    context.read<PaymentProvider>();
    
    // Show loading
    showCustomSnackBar(context, 'Processing payment...', type: SnackBarType.info);
    
    // In a real app, you would call the payment repository to retry the payment
    // For now, we'll simulate a successful retry
    Future.delayed(const Duration(seconds: 2), () {
      showCustomSnackBar(
        context,
        'Payment processed successfully',
        type: SnackBarType.success,
      );
    });
  }

  void _cancelPayment(PaymentModel payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment'),
        content: const Text('Are you sure you want to cancel this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmCancelPayment(payment);
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancelPayment(PaymentModel payment) {
    context.read<PaymentProvider>();
    
    // Show loading
    showCustomSnackBar(context, 'Cancelling payment...', type: SnackBarType.info);
    
    // In a real app, you would call the payment repository to cancel the payment
    Future.delayed(const Duration(seconds: 1), () {
      showCustomSnackBar(
        context,
        'Payment cancelled successfully',
        type: SnackBarType.success,
      );
    });
  }

  void _addPaymentMethod() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddPaymentMethodSheet(),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      currentDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'pending':
        return AppColors.accent;
      case 'failed':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Add Payment Method Bottom Sheet
class AddPaymentMethodSheet extends StatefulWidget {
  const AddPaymentMethodSheet({super.key});

  @override
  State<AddPaymentMethodSheet> createState() => _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState extends State<AddPaymentMethodSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  
  String _selectedMethod = 'card';
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Payment Method',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Payment Method Selection
          _buildMethodSelection(),
          const SizedBox(height: 16),
          
          // Payment Form
          _buildPaymentForm(),
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePaymentMethod,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildMethodChip('Card', Icons.credit_card, 'card'),
            _buildMethodChip('Mobile Money', Icons.phone_android, 'mobile_money'),
            _buildMethodChip('Bank Transfer', Icons.account_balance, 'bank_transfer'),
          ],
        ),
      ],
    );
  }

  Widget _buildMethodChip(String label, IconData icon, String value) {
    final isSelected = _selectedMethod == value;
    
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedMethod = value;
        });
      },
    );
  }

  Widget _buildPaymentForm() {
    switch (_selectedMethod) {
      case 'card':
        return _buildCardForm();
      case 'mobile_money':
        return _buildMobileMoneyForm();
      case 'bank_transfer':
        return _buildBankTransferForm();
      default:
        return const SizedBox();
    }
  }

  Widget _buildCardForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _cardNumberController,
            decoration: const InputDecoration(
              labelText: 'Card Number',
              hintText: '1234 5678 9012 3456',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter card number';
              }
              if (value.replaceAll(' ', '').length != 16) {
                return 'Please enter a valid card number';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date',
                    hintText: 'MM/YY',
                  ),
                  keyboardType: TextInputType.datetime,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter expiry date';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter CVV';
                    }
                    if (value.length != 3) {
                      return 'Please enter a valid CVV';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Cardholder Name',
              hintText: 'John Doe',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter cardholder name';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMoneyForm() {
    return Column(
      children: [
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '+1234567890',
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Mobile Money Provider',
          ),
          items: const [
            DropdownMenuItem(value: 'mtn', child: Text('MTN Mobile Money')),
            DropdownMenuItem(value: 'airtel', child: Text('Airtel Money')),
            DropdownMenuItem(value: 'vodafone', child: Text('Vodafone Cash')),
          ],
          onChanged: (value) {},
        ),
      ],
    );
  }

  Widget _buildBankTransferForm() {
    return Column(
      children: [
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Account Number',
            hintText: '1234567890',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Account Holder Name',
            hintText: 'John Doe',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Bank Name',
            hintText: 'Bank of Example',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Routing Number',
            hintText: '123456789',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Future<void> _savePaymentMethod() async {
    if (_selectedMethod == 'card' && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      showCustomSnackBar(
        context,
        'Payment method added successfully',
        type: SnackBarType.success,
      );
      
      Navigator.pop(context);
    } catch (e) {
      showCustomSnackBar(
        context,
        'Failed to add payment method: $e',
        type: SnackBarType.error,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}