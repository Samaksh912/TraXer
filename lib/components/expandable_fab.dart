import 'package:flutter/material.dart';
import 'dart:ui';

class ExpandableGlassFab extends StatefulWidget {
  final VoidCallback onAddTap;
  final Function(String) onSearchChanged;

  const ExpandableGlassFab({
    super.key,
    required this.onAddTap,
    required this.onSearchChanged,
  });

  @override
  State<ExpandableGlassFab> createState() => _ExpandableGlassFabState();
}

class _ExpandableGlassFabState extends State<ExpandableGlassFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: 0.0,
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastLinearToSlowEaseIn,
      reverseCurve: Curves.fastOutSlowIn,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
        if (_isSearchActive) {
          _isSearchActive = false;
          _searchController.clear();
          widget.onSearchChanged("");
        }
      }
    });
  }

  Widget _buildAction(IconData icon, String label, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onPressed();
          _toggle();
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF192540).withOpacity(0.6),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFF40485D).withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFDEE5FF),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: const Color(0xFF9EFFC8), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Search Expansion
        if (_isSearchActive) ...[
          Container(
            width: MediaQuery.of(context).size.width - 40,
            margin: const EdgeInsets.only(bottom: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF192540).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF40485D).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF9EFFC8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white),
                          onChanged: widget.onSearchChanged,
                          decoration: const InputDecoration(
                            hintText: "Search transactions...",
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () {
                          setState(() {
                            _isSearchActive = false;
                            _searchController.clear();
                            widget.onSearchChanged("");
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],

        // Fab stack
        if (!_isSearchActive) ...[
          _AnimatedAction(
            animation: _expandAnimation,
            index: 4,
            child: _buildAction(
              Icons.history,
              "History",
              () => print("History tapped"),
            ),
          ),
          _AnimatedAction(
            animation: _expandAnimation,
            index: 0,
            child: _buildAction(
              Icons.mic,
              "Voice",
              () => print("Voice tapped"),
            ),
          ),
          _AnimatedAction(
            animation: _expandAnimation,
            index: 3,
            child: _buildAction(
              Icons.bar_chart_rounded,
              "Analytics",
              () => print("Analytics tapped"),
            ),
          ),
          _AnimatedAction(
            animation: _expandAnimation,
            index: 1,
            child: _buildAction(Icons.search, "Search", () {
              setState(() {
                _isSearchActive = true;
              });
            }),
          ),
          _AnimatedAction(
            animation: _expandAnimation,
            index: 2,
            child: _buildAction(Icons.add, "New Transaction", widget.onAddTap),
          ),
        ],

        const SizedBox(height: 12),

        // Main button
        ScaleTransition(
          scale: const AlwaysStoppedAnimation(1.0),
          child: GestureDetector(
            onTap: _toggle,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.fastLinearToSlowEaseIn,
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: _isOpen
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF9EFFC8), Color(0xFF1DFBA5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: _isOpen
                        ? const Color(0xFF192540).withOpacity(0.8)
                        : null,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isOpen
                          ? const Color(0xFF40485D).withOpacity(0.5)
                          : const Color(0xFF1DFBA5).withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isOpen
                            ? Colors.transparent
                            : const Color(0xFF9EFFC8).withOpacity(0.4),
                        blurRadius: _isOpen ? 0 : 25,
                        spreadRadius: _isOpen ? 0 : 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedRotation(
                      turns: _isOpen ? 0.125 : 0, // 45 degrees
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.fastLinearToSlowEaseIn,
                      child: Icon(
                        Icons.add,
                        color: _isOpen ? Colors.white : const Color(0xFF00452A),
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedAction extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final int index;

  const _AnimatedAction({
    required this.animation,
    required this.child,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final delay = index * 0.08;
    final begin = delay;
    final end = (delay + 0.6).clamp(0.0, 1.0);

    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(begin, end, curve: Curves.fastLinearToSlowEaseIn),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, childWidget) {
        if (itemAnimation.value == 0.0) return const SizedBox.shrink();

        return Transform.translate(
          offset: Offset(0, 30 * (1 - itemAnimation.value)),
          child: Transform.scale(
            scale: itemAnimation.value,
            child: Opacity(
              opacity: itemAnimation.value.clamp(0.0, 1.0),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: childWidget,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}
