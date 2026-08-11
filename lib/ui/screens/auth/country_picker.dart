import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

// Simple country list — TDLib GetCountries থেকে dynamically লোড করা হবে পরে
final _commonCountries = [
  {'name': 'Bangladesh', 'code': '880', 'flag': '🇧🇩'},
  {'name': 'India', 'code': '91', 'flag': '🇮🇳'},
  {'name': 'Pakistan', 'code': '92', 'flag': '🇵🇰'},
  {'name': 'United States', 'code': '1', 'flag': '🇺🇸'},
  {'name': 'United Kingdom', 'code': '44', 'flag': '🇬🇧'},
  {'name': 'Saudi Arabia', 'code': '966', 'flag': '🇸🇦'},
  {'name': 'UAE', 'code': '971', 'flag': '🇦🇪'},
  {'name': 'Germany', 'code': '49', 'flag': '🇩🇪'},
  {'name': 'Turkey', 'code': '90', 'flag': '🇹🇷'},
  {'name': 'Russia', 'code': '7', 'flag': '🇷🇺'},
  {'name': 'Malaysia', 'code': '60', 'flag': '🇲🇾'},
];


class CountryPickerSheet extends ConsumerStatefulWidget {
  const CountryPickerSheet({super.key});

  @override
  ConsumerState<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends ConsumerState<CountryPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _commonCountries
        .where((c) => c['name']!.toLowerCase().contains(_query.toLowerCase()) ||
            c['code']!.contains(_query.replaceAll('+', '')))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Select Country', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search country',
                prefixIcon: const Icon(Icons.search, color: AppTheme.tgGrey),
                filled: true,
                fillColor: AppTheme.tgSecondaryBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // List
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final country = filtered[i];
                return ListTile(
                  leading: Text(country['flag']!, style: const TextStyle(fontSize: 24)),
                  title: Text(country['name']!),
                  trailing: Text(
                    '+${country['code']}',
                    style: const TextStyle(color: AppTheme.tgBlue, fontWeight: FontWeight.w500),
                  ),
                  onTap: () => Navigator.pop(context, country),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
