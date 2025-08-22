import 'package:flutter/material.dart';
import '../models/connection_state.dart' show AirPlayConnectionState;
import '../constants/app_constants.dart';

class ControlButtonsWidget extends StatelessWidget {
  final bool isServiceRunning;
  final bool isServiceStarting;
  final bool isServiceStopping;
  final AirPlayConnectionState connectionState;
  final VoidCallback onToggleService;

  const ControlButtonsWidget({
    super.key,
    required this.isServiceRunning,
    this.isServiceStarting = false,
    this.isServiceStopping = false,
    required this.connectionState,
    required this.onToggleService,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 开启/关闭接收按钮
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (isServiceStarting || isServiceStopping)
                ? null
                : onToggleService,
            icon: _buildButtonIcon(),
            label: Text(
              _getButtonText(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getButtonColor(),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
              ),
              elevation: 2,
            ),
          ),
        ),

        const SizedBox(width: 16),

        // 设置按钮
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            icon: const Icon(Icons.settings, size: 24),
            label: const Text(
              '设置',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
              ),
              side: BorderSide(
                color: Colors.grey[400]!,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtonIcon() {
    if (isServiceStarting || isServiceStopping) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return Icon(
      isServiceRunning ? Icons.stop : Icons.play_arrow,
      size: 24,
    );
  }

  String _getButtonText() {
    if (isServiceStarting) {
      return '启动中...';
    } else if (isServiceStopping) {
      return '停止中...';
    } else if (isServiceRunning) {
      return '关闭接收';
    } else {
      return '开启接收';
    }
  }

  Color _getButtonColor() {
    if (isServiceStarting || isServiceStopping) {
      return Colors.grey[600]!;
    } else if (isServiceRunning) {
      return Colors.red[400]!;
    } else {
      return Colors.blue[600]!;
    }
  }
}
