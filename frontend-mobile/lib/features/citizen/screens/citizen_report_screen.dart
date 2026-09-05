import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_client.dart';
import '../../../services/auth_service.dart';
import '../../../services/location_service.dart';
import '../../../services/photo_upload_service.dart';
import '../../../services/pole_provider.dart';

class CitizenReportScreen extends StatefulWidget {
  final String? preselectedPoleId;
  const CitizenReportScreen({super.key, this.preselectedPoleId});

  @override
  State<CitizenReportScreen> createState() => _CitizenReportScreenState();
}

class _CitizenReportScreenState extends State<CitizenReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _photoUploadService = PhotoUploadService();

  String? _selectedPoleId;
  String _selectedHazardType = 'Electrical leakage suspicion';
  XFile? _selectedImage;
  bool _isUploading = false;
  String? _uploadedImageUrl;

  final List<String> _hazardTypes = const [
    'Electrical leakage suspicion',
    'Damaged pole',
    'Broken wire',
    'Sparking',
    'Water near electrical pole',
    'Fallen wire',
    'Fire/smoke',
    'Human/animal danger',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPoleId = widget.preselectedPoleId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = Provider.of<LocationService>(context, listen: false);
      loc.fetchDeviceLocation();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _pickCamera() async {
    final file = await _photoUploadService.captureFromCamera();
    if (file != null) {
      setState(() {
        _selectedImage = file;
        _uploadedImageUrl = null;
      });
    }
  }

  void _pickGallery() async {
    final file = await _photoUploadService.pickFromGallery();
    if (file != null) {
      setState(() {
        _selectedImage = file;
        _uploadedImageUrl = null;
      });
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final loc = Provider.of<LocationService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    setState(() => _isUploading = true);

    // 1. Upload photo if selected
    String? imageUrl;
    if (_selectedImage != null) {
      final uploadRes = await _photoUploadService.uploadPhoto(_selectedImage!);
      if (uploadRes['success'] == true) {
        imageUrl = uploadRes['image_url'];
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(uploadRes['error'] ?? 'Photo upload failed. Proceeding without photo.'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    }

    // 2. Submit report to backend
    final res = await ApiClient.submitHazardReport(
      latitude: loc.effectiveLatitude,
      longitude: loc.effectiveLongitude,
      poleId: _selectedPoleId,
      address: _addressController.text.isNotEmpty ? _addressController.text : LocationService.testLocationName,
      hazardType: _selectedHazardType,
      description: _descriptionController.text.trim(),
      imageUrl: imageUrl,
      reporterName: auth.currentUser?.name ?? 'Citizen Reporter',
      reporterPhone: null,
    );

    setState(() => _isUploading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      final reportId = res['data']?['report_id'] ?? 'REP-000124';
      _showSuccessDialog(reportId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] ?? 'Failed to submit report.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  void _showSuccessDialog(String reportId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 28),
            SizedBox(width: 10),
            Text('Hazard Reported', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your hazard report has been received and dispatched to the municipal electrical response team.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined, color: AppTheme.infoColor, size: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Report ID', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      Text(reportId, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.infoColor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Initial Status: REPORTED → Lineman verification will be assigned shortly.',
              style: TextStyle(fontSize: 11, color: AppTheme.warningColor),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.infoColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close report screen
            },
            child: const Text('View All Reports', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocationService>(context);
    final poleProvider = Provider.of<PoleProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Report Electrical Hazard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Location Bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        loc.isTestLocationMode ? Icons.science_outlined : Icons.my_location_rounded,
                        color: loc.isTestLocationMode ? AppTheme.warningColor : AppTheme.infoColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.locationSourceLabel,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            Text(
                              '${loc.effectiveLatitude.toStringAsFixed(4)}° N, ${loc.effectiveLongitude.toStringAsFixed(4)}° E',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: loc.toggleTestLocationMode,
                        child: Text(
                          loc.isTestLocationMode ? 'Use GPS' : 'Test Mode',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: loc.isTestLocationMode ? AppTheme.infoColor : AppTheme.warningColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Street / Landmark Address
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Street / Landmark Address',
                    hintText: 'e.g. Near Bus Stop 14, MG Road',
                    prefixIcon: Icon(Icons.place_outlined, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),

                // Associated Pole Selection (optional)
                DropdownButtonFormField<String>(
                  value: _selectedPoleId,
                  decoration: const InputDecoration(
                    labelText: 'Associated Pole (Optional)',
                    prefixIcon: Icon(Icons.bolt_outlined, color: AppTheme.textSecondary),
                  ),
                  dropdownColor: AppTheme.surfaceDark,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No specific pole / Nearby')),
                    ...poleProvider.poles.map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.id} — ${p.name}'),
                        )),
                  ],
                  onChanged: (val) => setState(() => _selectedPoleId = val),
                ),
                const SizedBox(height: 14),

                // Hazard Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedHazardType,
                  decoration: const InputDecoration(
                    labelText: 'Observed Hazard Type',
                    prefixIcon: Icon(Icons.warning_amber_rounded, color: AppTheme.dangerColor),
                  ),
                  dropdownColor: AppTheme.surfaceDark,
                  items: _hazardTypes.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      )).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedHazardType = val);
                  },
                ),
                const SizedBox(height: 14),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Hazard Description',
                    hintText: 'Describe sparking, loose wires, shock risk, or standing water near pole...',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => (v == null || v.trim().length < 5) ? 'Please describe the hazard in detail' : null,
                ),
                const SizedBox(height: 16),

                // Photo Upload Box
                const Text(
                  'Attach Photo Evidence',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Photos are securely analyzed by the Computer Vision safety pipeline for water puddles and proximity risk.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 10),

                if (_selectedImage == null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: AppTheme.infoColor.withOpacity(0.4)),
                          ),
                          icon: const Icon(Icons.camera_alt_rounded, color: AppTheme.infoColor, size: 20),
                          label: const Text('Take Photo', style: TextStyle(color: AppTheme.infoColor, fontWeight: FontWeight.bold)),
                          onPressed: _pickCamera,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                          ),
                          icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 20),
                          label: const Text('Choose Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: _pickGallery,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.successColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image_rounded, color: AppTheme.successColor, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedImage!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              const Text('Photo attached and ready for upload', style: TextStyle(fontSize: 11, color: AppTheme.successColor)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.dangerColor),
                          onPressed: () => setState(() => _selectedImage = null),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dangerColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  onPressed: _isUploading ? null : _handleSubmit,
                  child: _isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Uploading & Submitting Report...', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Submit Hazard Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
