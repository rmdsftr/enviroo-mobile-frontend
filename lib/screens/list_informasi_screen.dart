import 'package:enviroo/screens/informasi_screen.dart';
import 'package:enviroo/widgets/pagination.dart';
import 'package:enviroo/widgets/search.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/providers/konten_provider.dart';
import 'package:enviroo/models/konten_model.dart';

class _C {
  static const dark  = Color(0xFF013236);
  static const green = Color(0xFF4EA771);
}

class ListInformasiScreen extends StatefulWidget {
  @override
  State<ListInformasiScreen> createState() => _ListInformasiState();
}

class _ListInformasiState extends State<ListInformasiScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  List<KontenModel> _getFilteredList(List<KontenModel> list) {
    if (_searchQuery.isEmpty) return list;
    return list
        .where((info) =>
            info.judul.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            info.deskripsi.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _onPageChanged(int page) {
    context.read<KontenProvider>().goToPage(page);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KontenProvider>(
      builder: (context, kontenProv, child) {
        final filtered = _getFilteredList(kontenProv.kontenList);

        return Scaffold(
          backgroundColor: const Color(0xFFF2FAF0),
          body: SafeArea(
            child: Column(
              children: [
                const TopBarBack(title: "Informasi"),
                CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Cari informasi...',
                  onChanged: (v) => setState(() => _searchQuery = v),
                  searchQuery: _searchQuery,
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  padding: const EdgeInsets.fromLTRB(24, 5, 24, 0),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: kontenProv.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _C.green),
                        )
                      : filtered.isEmpty
                          ? _buildEmptyState()
                          : GridView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.72,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) =>
                                  _buildInfoCard(filtered[index]),
                            ),
                ),
                if (!kontenProv.isLoading && kontenProv.totalPages > 1) ...[
                  const SizedBox(height: 8),
                  Pagination(
                    currentPage: kontenProv.currentPage,
                    totalPages: kontenProv.totalPages,
                    onPageChanged: _onPageChanged,
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(KontenModel info) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InformasiScreen(kontenId: info.kontenId),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF013236).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 90,
                width: double.infinity,
                color: const Color(0xFF4EA771).withValues(alpha: 0.1),
                child: info.thumbnail.isNotEmpty
                    ? Image.network(
                        info.thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),

            // Konten
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      info.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _C.dark,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info.deskripsi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: _C.dark.withValues(alpha: 0.5),
                        height: 1.4,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.account_balance_outlined, size: 11, color: _C.green),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            info.nama_instansi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: _C.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.image_rounded,
        size: 32,
        color: const Color(0xFF4EA771).withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: _C.dark.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            'Tidak ada informasi ditemukan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: _C.dark.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
