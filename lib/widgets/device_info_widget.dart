import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class DeviceInfoWidget extends StatelessWidget {
  const DeviceInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 设备名称
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.tablet_android,
                  size: 24,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 12),
                Text(
                  AppConstants.deviceName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 设备规格信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.monitor,
                    '分辨率',
                    '3392×2400 (7:5)',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.refresh,
                    '刷新率',
                    '144Hz',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.memory,
                    '处理器',
                    '骁龙8至尊版',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              '在Mac上选择AirPlay，找到并连接到此设备',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}