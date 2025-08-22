import 'package:flutter/material.dart';
import '../models/connection_state.dart' show AirPlayConnectionState;
import '../constants/app_constants.dart';

class ControlButtonsWidget extends StatelessWidget {
  final bool isServiceRunning;
  final AirPlayConnectionState connectionState;
  final VoidCallback onToggleService;
  
  const ControlButtonsWidget({
    super.key,
    required this.isServiceRunning,
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
            onPressed: onToggleService,
            icon: Icon(
              isServiceRunning ? Icons.stop : Icons.play_arrow,
              size: 24,
            ),
            label: Text(
              isServiceRunning ? '关闭接收' : '开启接收',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isServiceRunning 
                  ? Colors.red[400] 
                  : Colors.blue[600],
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
}