import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../models/shipment_model.dart';
import '../../providers/shipment_provider.dart';
import '../../utils/constants.dart';
import 'shipment_detail_screen.dart';

class DriverShipmentsScreen extends StatefulWidget {
  const DriverShipmentsScreen({Key? key}) : super(key: key);

  @override
  State<DriverShipmentsScreen> createState() => _DriverShipmentsScreenState();
}

class _DriverShipmentsScreenState extends State<DriverShipmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadShipments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadShipments(refresh: true);
    }
  }

  void _loadShipments({bool refresh = false}) {
    String status;
    switch (_tabController.index) {
      case 0:
        status = '';
        break;
      case 1:
        status = ShipmentStatus.assigned;
        break;
      case 2:
        status = ShipmentStatus.inTransit;
        break;
      case 3:
        status = ShipmentStatus.delivered;
        break;
      default:
        status = '';
    }

    context.read<ShipmentProvider>().loadDriverShipments(
      status: status.isEmpty ? null : status,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      refresh: refresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الشحنات المخصصة لي'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'جديدة'),
            Tab(text: 'نشطة'),
            Tab(text: 'مكتملة'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'البحث برقم التتبع...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _loadShipments(refresh: true);
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              onSubmitted: (_) => _loadShipments(refresh: true),
            ),
          ),

          // Shipments List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildShipmentsList(),
                _buildShipmentsList(),
                _buildShipmentsList(),
                _buildShipmentsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentsList() {
    return Consumer<ShipmentProvider>(
      builder: (context, shipmentProvider, child) {
        if (shipmentProvider.isLoading && shipmentProvider.shipments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (shipmentProvider.error != null && shipmentProvider.shipments.isEmpty) {
          return _buildErrorWidget(shipmentProvider.error!);
        }

        if (shipmentProvider.shipments.isEmpty) {
          return _buildEmptyWidget();
        }

        return SmartRefresher(
          controller: _refreshController,
          enablePullDown: true,
          enablePullUp: shipmentProvider.hasMoreData,
          onRefresh: () async {
            await shipmentProvider.loadDriverShipments(refresh: true);
            _refreshController.refreshCompleted();
          },
          onLoading: () async {
            await shipmentProvider.loadDriverShipments();
            _refreshController.loadComplete();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: shipmentProvider.shipments.length,
            itemBuilder: (context, index) {
              final shipment = shipmentProvider.shipments[index];
              return _DriverShipmentCard(
                shipment: shipment,
                onTap: () => _navigateToDetails(shipment),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد شحنات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم عرض الشحنات المخصصة لك هنا',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _loadShipments(refresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  void _navigateToDetails(ShipmentModel shipment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ShipmentDetailScreen(shipmentId: shipment.id),
      ),
    );
  }
}

class _DriverShipmentCard extends StatelessWidget {
  final ShipmentModel shipment;
  final VoidCallback onTap;

  const _DriverShipmentCard({
    required this.shipment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${shipment.trackingNumber}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
              const Divider(height: 24),
              _buildAddressRow(
                icon: Icons.location_on_outlined,
                label: 'من:',
                address: shipment.pickupAddress,
                color: Colors.blue,
              ),
              const SizedBox(height: 8),
              _buildAddressRow(
                icon: Icons.flag_outlined,
                label: 'إلى:',
                address: shipment.deliveryAddress,
                color: Colors.green,
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'الوزن: ${shipment.weight} كجم',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (shipment.price != null) ...[
                        const SizedBox(width: 16),
                        Text(
                          'السعر: ${shipment.price} ر.س',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (shipment.client != null)
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          shipment.client!.name,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    switch (shipment.status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'assigned':
        chipColor = Colors.blue;
        break;
      case 'picked_up':
        chipColor = Colors.purple;
        break;
      case 'in_transit':
        chipColor = Colors.indigo;
        break;
      case 'delivered':
        chipColor = Colors.green;
        break;
      case 'cancelled':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        shipment.statusArabic,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          color: chipColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAddressRow({
    required IconData icon,
    required String label,
    required String address,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            address,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
