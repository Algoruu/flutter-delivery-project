import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/place_search_service.dart';
import '../theme.dart';

/// 지도 위에 오버레이되는 검색 바 위젯
class MapSearchBar extends StatefulWidget {
  final PlaceSearchService searchService;
  final void Function(PlaceSearchResult result) onResultSelected;

  const MapSearchBar({
    super.key,
    required this.searchService,
    required this.onResultSelected,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<PlaceSearchResult> _results = [];
  bool _isLoading = false;
  bool _showResults = false;
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_focusNode.hasFocus && !_isSearching) {
            setState(() => _showResults = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _showResults = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query, {bool autoSelect = false}) async {
    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    final results = await widget.searchService.search(query);

    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
        _isSearching = false;
        _showResults = true;
      });

      if (autoSelect && results.isNotEmpty) {
        _selectResult(results.first);
      }
    }
  }

  void _selectResult(PlaceSearchResult result) {
    _controller.text = result.displayTitle;
    _focusNode.unfocus();
    setState(() {
      _showResults = false;
    });
    widget.onResultSelected(result);
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _results = [];
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 검색 입력 바
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            onSubmitted: (query) {
              if (query.trim().isNotEmpty) {
                _performSearch(query, autoSelect: true);
              }
            },
            style: GoogleFonts.notoSansKr(fontSize: 15),
            decoration: InputDecoration(
              hintText: '주소 또는 장소명을 검색하세요',
              hintStyle: GoogleFonts.notoSansKr(
                fontSize: 15,
                color: AppTheme.subtleText,
              ),
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: _clearSearch,
                    )
                  : _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),

        // 검색 결과 목록
        if (_showResults)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : _results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 20, color: AppTheme.subtleText),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '검색 결과가 없습니다.\n도로명 주소 또는 장소명으로 검색해 보세요.',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 13,
                                  color: AppTheme.subtleText,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 48),
                        itemBuilder: (context, index) {
                          final result = _results[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              result.isPlace
                                  ? Icons.place_outlined
                                  : Icons.location_on_outlined,
                              color: AppTheme.primaryColor,
                              size: 22,
                            ),
                            title: Text(
                              result.displayTitle,
                              style: GoogleFonts.notoSansKr(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: result.displaySubtitle.isNotEmpty
                                ? Text(
                                    result.displaySubtitle,
                                    style: GoogleFonts.notoSansKr(
                                      fontSize: 12,
                                      color: AppTheme.subtleText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: () => _selectResult(result),
                          );
                        },
                      ),
          ),
      ],
    );
  }
}
