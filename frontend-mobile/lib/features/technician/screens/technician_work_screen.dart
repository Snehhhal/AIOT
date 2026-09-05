import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/photo_upload_service.dart';
import '../../../services/pole_provider.dart';

class TechnicianWorkScreen extends StatefulWidget {
  const TechnicianWorkScreen({super.key});

  @override
  State<TechnicianWorkScreen> createState() => _TechnicianWorkScreenState();
}

class _TechnicianWorkScreenState extends State<TechnicianWorkScreen> {
  String _selectedPoleId = 'P-001';
  final _notesController = TextEditingController();
  final _insulationController = TextEditingController(text: '120');
  final _earthingController = TextEditingController(text: '3.2');
  
  String? _uploadedImageUrl;
  bool _isUploadingPhoto = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    _insulationController.dispose();
    _earthingController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _isUploadingPhoto = true);
    final url = await PhotoUploadService.pickAndUploadImage(context, source);
    if (mounted) {
      setState(() {
        _isUploadingPhoto = false;
        if (url != null) _uploadedImageUrl = url;
      });
    }
  }

  Future<void> _submitWorkOrder() async {
    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter repair or inspection notes.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Update pole telemetry back to normal safe steady state
    final poleProvider = Provider.of<PoleProvider>(context, listen: false);
    await poleProvider.triggerScenario(_selectedPoleId, 'NORMAL');

    setState(() => _isSubmitting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Work order for $_selectedPoleId submitted and marked RESOLVED. Pole restored to SAFE.'),
          backgroundColor: AppTheme.safeColor,
        ),
      );
      setState(() {
        _notesController.clear();
        _uploadedImageUrl = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final poleProvider = Provider.of<PoleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Work Order Execution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Pole Selector
            const Text('Select Target Pole', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: DropdownButton<String>(
                value: _selectedPoleId,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: AppTheme.surfaceDark,
                items: poleProvider.poles.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text(' —  ()'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPoleId = val);
                },
              ),
            ),
            const SizedBox(height: 20),

            // Diagnostic Measurements
            const Text('Field Measurements', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _insulationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Insulation Resistance',
                      suffixText: 'MΩ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _earthingController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Earth Pit Resistance',
                      suffixText: 'Ω',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Inspection Photo Upload
            const Text('Post-Repair Photographic Evidence', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            if (_uploadedImageUrl != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.safeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.safeColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.safeColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Photo Uploaded Successfully', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.safeColor)),
                          Text(_uploadedImageUrl!, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _uploadedImageUrl = null),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppTheme.infoColor),
                    ),
                    icon: const Icon(Icons.camera_alt, color: AppTheme.infoColor),
                    label: const Text('Capture Camera', style: TextStyle(color: AppTheme.infoColor, fontSize: 13)),
                    onPressed: _isUploadingPhoto ? null : () => _pickPhoto(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppTheme.infoColor),
                    ),
                    icon: const Icon(Icons.photo_library, color: AppTheme.infoColor),
                    label: const Text('Gallery', style: TextStyle(color: AppTheme.infoColor, fontSize: 13)),
                    onPressed: _isUploadingPhoto ? null : () => _pickPhoto(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            if (_isUploadingPhoto)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 20),

            // Field Inspection Notes
            const Text('Action Performed & Certification Notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'e.g. Replaced worn insulator bushing, re-earthed pole base, verified leakage is 0.0mA...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.safeColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
              icon: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.verified, size: 20),
              label: Text(_isSubmitting ? 'Submitting...' : 'COMPLETE REPAIR & VERIFY SAFE', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              onPressed: _isSubmitting ? null : _submitWorkOrder,
            ),
          ],
        ),
      ),
    );
  }
}
