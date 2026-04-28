import 'package:enviroo/screens/informasi_screen.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/providers/konten_provider.dart';
import 'package:enviroo/models/konten_model.dart';

class _C {
  static const bg        = Color(0xFFFFFFFF);
  static const dark      = Color(0xFF013236);
  static const green     = Color(0xFF4EA771);
  static const lime      = Color(0xFF94DF0C);
}

class ListInformasiScreen extends StatefulWidget {
  @override
  State<ListInformasiScreen> createState() => _ListInformasiState();
}

class _ListInformasiState extends State<ListInformasiScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<KontenModel> _getFilteredList(List<KontenModel> list) {
    if (_searchQuery.isEmpty) return list;
    return list
        .where((info) =>
            info.judul.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KontenProvider>(
      builder: (context, kontenProv, child) {
        final _filteredList = _getFilteredList(kontenProv.kontenList);

        return Scaffold(
          backgroundColor: _C.bg,
          body: SafeArea(
            child: Column(
              children: [
                const TopBarBack(title: "Informasi"),
                _buildSearchBar(),
                const SizedBox(height: 20),
                Expanded(
                  child: kontenProv.isLoading && kontenProv.kontenList.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredList.isEmpty
                          ? _buildEmptyState()
                          : _buildGrid(_filteredList),
                ),
              ],
            ),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(right: 10, bottom: 10),
            child: FloatingActionButton(
              onPressed: () {
                // To be implemented
              },
              backgroundColor: const Color(0xFF013236),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Search Bar ──────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 5, 24, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _C.dark),
        decoration: InputDecoration(
          hintText: "Cari informasi...",
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: _C.dark.withOpacity(0.35),
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: _C.green, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: _C.dark.withOpacity(0.35)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide(color: _C.green.withOpacity(0.5), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: _C.green, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  // ─── Grid ────────────────────────────────────────────────────────
  Widget _buildGrid(List<KontenModel> filteredList) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final info = filteredList[index];
        return _buildInfoCard(info);
      },
    );
  }

  // ─── Card ────────────────────────────────────────────────────────
  Widget _buildInfoCard(KontenModel info) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InformasiScreen(konten: info)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image placeholder or network image ──
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _C.green.withOpacity(0.3),
                        _C.green.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      info.thumbnail.isNotEmpty
                          ? Image.network(
                              info.thumbnail,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                      // TBD: Category chip if needed from backend
                    ],
                  ),
                ),
              ),
            ),

            // ── Content ──
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: _C.dark.withOpacity(0.35),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${info.createdAt.day}-${info.createdAt.month}-${info.createdAt.year}",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: _C.dark.withOpacity(0.45),
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
        size: 36,
        color: _C.green.withOpacity(0.35),
      ),
    );
  }

  // ─── Empty State ─────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: _C.dark.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text(
            'Tidak ada informasi ditemukan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: _C.dark.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
