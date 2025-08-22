import 'package:flutter/material.dart';
import '../models/connection_state.dart'
    show ConnectionStatus, AirPlayConnectionState;

class ConnectionStatusWidget extends StatelessWidget {
  final AirPlayConnectionState connectionState;

  const ConnectionStatusWidget({
    super.key,
    required this.connectionState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: _getBackgroundColor(connectionState.status),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (connectionState.status == ConnectionStatus.discovering ||
              connectionState.status == ConnectionStatus.connecting)
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(right: 8),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getTextColor(connectionState.status),
                ),
              ),
            )
          else
            Icon(
              _getStatusIcon(connectionState.status),
              size: 18,
              color: _getTextColor(connectionState.status),
            ),
          const SizedBox(width: 8),
          Text(
            connectionState.statusText,
            style: TextStyle(
              color: _getTextColor(connectionState.status),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          if (connectionState.isStreaming && connectionState.currentFPS != null)
            Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${connectionState.currentFPS}fps',
                style: TextStyle(
                  color: _getTextColor(connectionState.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.disconnected:
        return Icons.cast;
      case ConnectionStatus.discovering:
        return Icons.search;
      case ConnectionStatus.connecting:
        return Icons.cast_connected;
      case ConnectionStatus.connected:
        return Icons.cast_connected;
      case ConnectionStatus.streaming:
        return Icons.cast_connected;
      case ConnectionStatus.error:
        return Icons.error_outline;
    }
  }

  Color _getBackgroundColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.disconnected:
        return Colors.grey[200]!;
      case ConnectionStatus.discovering:
        return Colors.blue[100]!;
      case ConnectionStatus.connecting:
        return Colors.orange[100]!;
      case ConnectionStatus.connected:
        return Colors.green[100]!;
      case ConnectionStatus.streaming:
        return Colors.green[100]!;
      case ConnectionStatus.error:
        return Colors.red[100]!;
    }
  }

  Color _getTextColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.disconnected:
        return Colors.grey[700]!;
      case ConnectionStatus.discovering:
        return Colors.blue[700]!;
      case ConnectionStatus.connecting:
        return Colors.orange[700]!;
      case ConnectionStatus.connected:
        return Colors.green[700]!;
      case ConnectionStatus.streaming:
        return Colors.green[700]!;
      case ConnectionStatus.error:
        return Colors.red[700]!;
    }
  }
}
