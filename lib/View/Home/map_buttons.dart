import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Theme/colors.dart';

class MapButtonsController {
  final Function()? refreshSession;

  MapButtonsController({this.refreshSession});
}

class MapButtons extends StatefulWidget {
  final VoidCallback onMyLocation;
  final VoidCallback onList;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  final Function(int? sessionId)? onNavigate;
  final Function(MapButtonsController)? onControllerCreated;
  final VoidCallback? onRefreshStations;

  const MapButtons({
    Key? key,
    required this.onMyLocation,
    required this.onList,
    required this.onZoomOut,
    required this.onZoomIn,
    this.onNavigate,
    this.onControllerCreated,
    this.onRefreshStations,
  }) : super(key: key);

  @override
  State<MapButtons> createState() => MapButtonsState();
}

class MapButtonsState extends State<MapButtons> {
  bool _hasActiveSession = false;
  int? _activeSessionId;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _checkActiveSession();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _checkActiveSession();
      }
    });

    if (widget.onControllerCreated != null) {
      widget.onControllerCreated!(MapButtonsController(
        refreshSession: _checkActiveSession,
      ));
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getInt('active_session_id');
      final sessionStatus = prefs.getString('session_status');
      final hasActive = sessionId != null && sessionStatus == 'charging';

      if (mounted) {
        setState(() {
          _hasActiveSession = hasActive;
          _activeSessionId = sessionId;
        });
      }

      print('🔍 MapButtons: Session active: $hasActive, ID: $sessionId, Status: $sessionStatus');
    } catch (e) {
      print('❌ Error checking active session: $e');
    }
  }

  Future<void> refreshSession() async {
    await _checkActiveSession();
  }

  void _onMyLocationPressed() {
    widget.onMyLocation();
    if (widget.onRefreshStations != null) {
      widget.onRefreshStations!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lighter black (more transparent) - 40% opacity instead of 70%
    final buttonBackgroundColor = Colors.black.withOpacity(0.6);
    final buttonSplashColor = Colors.white.withOpacity(0.2);
    final buttonHighlightColor = Colors.white.withOpacity(0.1);

    return Column(
      children: [
        if (_hasActiveSession) ...[
          _circleButton(
            icon: Icons.directions_car,
            onPressed: () {
              if (widget.onNavigate != null) {
                widget.onNavigate!(_activeSessionId);
              }
            },
            color: Colors.white,
            backgroundColor: buttonBackgroundColor,
            splashColor: buttonSplashColor,
            highlightColor: buttonHighlightColor,
          ),
          const SizedBox(height: 10),
        ],
        _circleButton(
          icon: Icons.my_location,
          onPressed: _onMyLocationPressed,
          color: Colors.white,
          backgroundColor: buttonBackgroundColor,
          splashColor: buttonSplashColor,
          highlightColor: buttonHighlightColor,
        ),
        const SizedBox(height: 10), // Reduced spacing
        _circleButton(
          icon: Icons.list,
          onPressed: widget.onList,
          color: Colors.white,
          backgroundColor: buttonBackgroundColor,
          splashColor: buttonSplashColor,
          highlightColor: buttonHighlightColor,
        ),
        const SizedBox(height: 10), // Reduced spacing
        _circleButton(
          icon: Icons.add,
          onPressed: widget.onZoomIn,
          color: Colors.white,
          backgroundColor: buttonBackgroundColor,
          splashColor: buttonSplashColor,
          highlightColor: buttonHighlightColor,
        ),
        const SizedBox(height: 10), // Reduced spacing
        _circleButton(
          icon: Icons.remove,
          onPressed: widget.onZoomOut,
          color: Colors.white,
          backgroundColor: buttonBackgroundColor,
          splashColor: buttonSplashColor,
          highlightColor: buttonHighlightColor,
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.white,
    required Color backgroundColor,
    required Color splashColor,
    required Color highlightColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15), // Reduced shadow opacity
            blurRadius: 6, // Reduced blur
            offset: const Offset(0, 1), // Reduced offset
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          splashColor: splashColor,
          highlightColor: highlightColor,
          child: Container(
            width: 40, // Reduced from 48 to 40
            height: 40, // Reduced from 48 to 40
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

