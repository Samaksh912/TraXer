import 'package:flutter/material.dart';
class FloatingBottomNavBar extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onAddTap; // Renamed from onVoiceTap
  final Function(String) onSearchChanged;

  const FloatingBottomNavBar({
    super.key,
    required this.isVisible,
    required this.onAddTap,
    required this.onSearchChanged,
  });

  @override
  State<FloatingBottomNavBar> createState() => _FloatingBottomNavBarState();
}

class _FloatingBottomNavBarState extends State<FloatingBottomNavBar> {
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _searchController.clear();
        widget.onSearchChanged("");
        FocusScope.of(context).unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final fabColor = const Color(0xFF2C3E50);

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: widget.isVisible ? Offset.zero : const Offset(0, 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuint,
        width: _isSearchActive ? MediaQuery.of(context).size.width - 40 : 290,
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSearchActive ? _buildSearchBar(isDark) : _buildNavItems(fabColor, isDark),
        ),
      ),
    );
  }

  Widget _buildNavItems(Color fabColor, bool isDark) {
    return Row(
      key: const ValueKey('NavItems'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => print("Analytics Tapped"),
          icon: Icon(Icons.bar_chart_rounded, color: isDark ? Colors.white70 : Colors.grey),
        ),
        IconButton(
          onPressed: ()=> print("voice tapped") ,
          icon: Icon(Icons.mic_rounded, color: isDark ? Colors.white70 : Colors.grey),),

        // NEW: Add Button
        GestureDetector(
          onTap: widget.onAddTap,
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: fabColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: fabColor.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
          ),
        ),

        IconButton(
          onPressed: _toggleSearch,
          icon: Icon(Icons.search_rounded, color: isDark ? Colors.white70 : Colors.grey),
        ),
        IconButton(
          onPressed: () => print("Transaction Tapped"),
          icon: Icon(Icons.history, color: isDark ? Colors.white70 : Colors.grey),
        ),
      ],
    );
  }


  Widget _buildSearchBar(bool isDark) {
    return Row(
      key: const ValueKey('SearchBar'),
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: "Search transactions...",
              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400]),
              border: InputBorder.none,
              icon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.grey),
            ),
          ),
        ),
        IconButton(
          onPressed: _toggleSearch,
          icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
        ),
      ],
    );
  }
}