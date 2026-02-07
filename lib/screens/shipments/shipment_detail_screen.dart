import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shipment_provider.dart';
import '../../utils/app_helpers.dart';

class ShipmentDetailScreen extends StatefulWidget {
  final String shipmentId;

  const ShipmentDetailScreen({
    Key? key,
    required this.shipmentId,
  }) : super(key: key);

  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ShipmentProvider>().loadShipmentDetails(widget.shipmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الشحنة'),
      ),
      body: Consumer<ShipmentProvider>(
        builder: (context, shipmentProvider, child) {
          if (shipmentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (shipmentProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    shipmentProvider.error!,
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.red[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => shipmentProvider.loadShipmentDetails(widget.shipmentId),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final shipment = shipmentProvider.selectedShipment;
          if (shipment == null) {
            return const Center(child: Text('لم يتم العثور على الشحنة'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tracking Number & Status
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          shipment.trackingNumber,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStatusBadge(shipment.status),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Addresses
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'عنوان الاستلام',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                shipment.pickupAddress,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        const Text(
                          'عنوان التوصيل',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.flag, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                shipment.deliveryAddress,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Shipment Details
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('الوزن', '${shipment.weight} كجم'),
                        if (shipment.price != null)
                          _buildDetailRow('السعر', '${shipment.price} ر.س'),
                        _buildDetailRow(
                          'تاريخ الإنشاء',
                          AppHelpers.formatDateTime(shipment.createdAt),
                        ),
                        if (shipment.description != null)
                          _buildDetailRow('الوصف', shipment.description!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Driver Info (if assigned)
                if (shipment.driver != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'معلومات السائق',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: shipment.driver!.avatar != null
                                    ? NetworkImage(shipment.driver!.avatar!)
                                    : null,
                                child: shipment.driver!.avatar == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shipment.driver!.name,
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      shipment.driver!.phone,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.phone, color: Colors.green),
                                onPressed: () {
                                  // TODO: Make phone call
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(shipment),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        text = 'قيد الانتظار';
        break;
      case 'assigned':
        color = Colors.blue;
        text = 'تم التعيين';
        break;
      case 'picked_up':
        color = Colors.purple;
        text = 'تم الاستلام';
        break;
      case 'in_transit':
        color = Colors.indigo;
        text = 'في الطريق';
        break;
      case 'delivered':
        color = Colors.green;
        text = 'تم التوصيل';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'ملغي';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Cairo',
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic shipment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Track Shipment Button
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Navigate to tracking screen
          },
          icon: const Icon(Icons.map),
          label: const Text('تتبع الشحنة'),
        ),
        const SizedBox(height: 12),

        // Chat with Driver Button
        if (shipment.driver != null)
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to chat screen
            },
            icon: const Icon(Icons.chat),
            label: const Text('التواصل مع السائق'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
      ],
    );
  }
}
