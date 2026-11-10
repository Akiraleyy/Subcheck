import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data_access/models/enums.dart';
import '../../data_access/models/subscription.dart';
import '../../theme.dart';
import '../../utils/helpers.dart';
import '../controllers/subscription_controller.dart';
import '../widgets/common.dart';
import 'confirmation_screen.dart';

/// Figure 2. Add Subscription. The same screen is used to EDIT a subscription
/// (from Subscription Details) when [existing] is given.
class AddSubscriptionScreen extends StatefulWidget {
  const AddSubscriptionScreen({super.key, this.existing});

  final Subscription? existing;

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _peopleController = TextEditingController(text: '2');
  final _dateController = TextEditingController();
  final _dateFormat = DateFormat('MM/dd/yyyy');

  Category _category = Category.entertainment;
  BillingCycle _cycle = BillingCycle.monthly;
  DateTime? _date;
  bool _shared = false;
  String? _logoPath;
  bool _saving = false;

  /// Problems found by validate(), by field name (name, price, ...).
  Map<String, String> _errors = {};

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.name;
      _priceController.text = e.price == e.price.roundToDouble()
          ? e.price.toStringAsFixed(0)
          : e.price.toString();
      _category = e.category;
      _cycle = e.billingCycle;
      _date = e.nextPaymentDate;
      _dateController.text = _dateFormat.format(e.nextPaymentDate);
      _shared = e.isShared;
      _peopleController.text = e.numberOfPeople.toString();
      _logoPath = e.logoPath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _peopleController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  double? get _priceValue =>
      double.tryParse(_priceController.text.trim().replaceAll(',', ''));
  int? get _peopleValue => int.tryParse(_peopleController.text.trim());

  /// "Your share" shown live while typing.
  double get _yourShare {
    final price = _priceValue;
    final people = _peopleValue;
    if (price == null || people == null || people < 1) return 0;
    return price / people;
  }

  void _clearError(String field) {
    if (_errors.containsKey(field)) {
      setState(() => _errors = Map.of(_errors)..remove(field));
    }
  }

  Future<void> _pickLogo() async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, maxWidth: 512);
      if (picked != null) setState(() => _logoPath = picked.path);
    } catch (_) {
      if (mounted) showSnack(context, 'Could not open the photo library.');
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1);
    var initial = _date ?? now;
    if (initial.isBefore(firstDate)) initial = firstDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateController.text = _dateFormat.format(picked);
        _errors = Map.of(_errors)..remove('nextPaymentDate');
      });
    }
  }

  Future<void> _save() async {
    final controller = context.read<SubscriptionController>();
    final navigator = Navigator.of(context);

    final data = SubscriptionData(
      name: _nameController.text.trim(),
      category: _category,
      price: _priceValue,
      billingCycle: _cycle,
      nextPaymentDate: _date,
      logoPath: _logoPath,
      isShared: _shared,
      numberOfPeople: _shared ? (_peopleValue ?? 0) : 1,
    );

    // 1. Check the form. Show every problem under its field.
    final result = controller.validate(data);
    if (!result.valid) {
      setState(() {
        _errors = {for (final e in result.errors) e.field: e.message};
      });
      return;
    }

    // 2. Save.
    setState(() => _saving = true);
    try {
      if (_editing) {
        await controller.editSubscription(widget.existing!.id, data);
        navigator.pop();
      } else {
        final saved = await controller.addSubscription(data);
        // Replace this screen with the confirmation screen (Figure 3).
        navigator.pushReplacement(MaterialPageRoute(
          builder: (_) => ConfirmationScreen(subscriptionId: saved.id),
        ));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, 'Could not save. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_editing ? 'Edit Subscription' : 'Add Subscription')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            // Logo (optional)
            Center(
              child: GestureDetector(
                onTap: _pickLogo,
                child: Column(children: [
                  SubLogo(path: _logoPath, size: 64),
                  const SizedBox(height: 6),
                  Text('Tap to upload a logo image',
                      style: TextStyle(color: context.ink, fontSize: 13)),
                  Text('(optional)',
                      style: TextStyle(color: context.muted, fontSize: 11)),
                ]),
              ),
            ),

            const FieldLabel('Subscription name'),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => _clearError('name'),
              decoration: InputDecoration(
                hintText: 'Netflix, Spotify, Canva…',
                errorText: _errors['name'],
              ),
            ),

            const FieldLabel('Category'),
            AppDropdown<Category>(
              value: _category,
              items: Category.values,
              labelOf: (c) => c.label,
              onChanged: (c) => setState(() => _category = c),
            ),

            const FieldLabel('Price (₱)'),
            TextField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) {
                _clearError('price');
                setState(() {}); // updates "Your share"
              },
              decoration: InputDecoration(
                hintText: '₱0.00',
                errorText: _errors['price'],
              ),
            ),

            const FieldLabel('Billing cycle'),
            AppDropdown<BillingCycle>(
              value: _cycle,
              items: BillingCycle.values,
              labelOf: (c) => c.label,
              onChanged: (c) => setState(() => _cycle = c),
            ),

            const FieldLabel('Next payment date'),
            TextField(
              controller: _dateController,
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                hintText: 'MM/DD/YYYY',
                errorText: _errors['nextPaymentDate'],
                suffixIcon:
                    const Icon(Icons.calendar_today_outlined, size: 18),
              ),
            ),

            const FieldLabel('Is this a shared subscription?'),
            Row(children: [
              Expanded(child: _yesNoButton('Yes', true)),
              const SizedBox(width: 12),
              Expanded(child: _yesNoButton('No', false)),
            ]),

            if (_shared) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _peopleController,
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  _clearError('numberOfPeople');
                  setState(() {}); // updates "Your share"
                },
                decoration: InputDecoration(
                  labelText: 'Number of people sharing (including you)',
                  errorText: _errors['numberOfPeople'],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: context.surfaceTint,
                    borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'People sharing: '
                      '${(_peopleValue ?? 0) >= 2 ? _peopleValue : '--'}',
                      style: TextStyle(color: context.muted, fontSize: 12),
                    ),
                    Text('Your share: ${peso(_yourShare)}',
                        style: TextStyle(
                            color: context.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_editing ? 'Save changes' : 'Save subscription'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _yesNoButton(String label, bool value) {
    final on = _shared == value;
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: () => setState(() => _shared = value),
        style: OutlinedButton.styleFrom(
          backgroundColor: on ? AppColors.lime : Colors.transparent,
          foregroundColor: on ? AppColors.purple : context.muted,
          side: BorderSide(color: on ? AppColors.lime : context.cardBorder),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ),
    );
  }
}
