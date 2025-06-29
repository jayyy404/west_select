import 'package:cc206_west_select/features/screens/listing/all_orders.dart';
import 'package:cc206_west_select/features/screens/listing/create_listing.dart';
import 'package:cc206_west_select/features/screens/listing/myProducts.dart';
import 'package:flutter/material.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  bool _isCreatingListing = false;
  bool _isViewingMyProducts = false;
  bool _isViewingAllOrders = false;

  int _pendingOrderCount = 1;
  int _completedOrderCount = 1;
  int _reviewsCount = 3;

  Widget _buildStatusTile(String count, String label) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF201D1B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF201D1B)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF201D1B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF201D1B)),
        onTap: () {
          if (title == "All orders") {
            setState(() => _isViewingAllOrders = true);
          } else if (title == "My Products") {
            setState(() => _isViewingMyProducts = true);
          } else if (title == "Create Listing") {
            setState(() => _isCreatingListing = true);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top yellow header section
          Container(
            padding:
                const EdgeInsets.only(top: 40, bottom: 20, left: 16, right: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFFFCF68),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Stack(
              children: [
                // X button in top left corner
                Positioned(
                  top: 0,
                  left: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    color: const Color(0xFF201D1B),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        "My shop",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF201D1B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Shop Status",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF201D1B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusTile(
                            "$_pendingOrderCount", "Pending Orders"),
                        _buildStatusTile(
                            "$_completedOrderCount", "Completed Orders"),
                        _buildStatusTile("$_reviewsCount", "Reviews Received"),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main content section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 24, left: 24, bottom: 16),
                  child: Text(
                    "What you can do",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF201D1B),
                    ),
                  ),
                ),
                _buildActionTile(
                  "All orders",
                  "See updates about your products",
                  Icons.list_alt,
                ),
                _buildActionTile(
                  "My Products",
                  "Check your inventory",
                  Icons.shopping_bag,
                ),
                _buildActionTile(
                  "Create Listing",
                  "List your products",
                  Icons.add,
                ),
                const Spacer(),
                // Content display area
                Expanded(
                  flex: 3,
                  child: _isCreatingListing
                      ? const CreateListingForm()
                      : _isViewingMyProducts
                          ? const MyProductsList()
                          : _isViewingAllOrders
                              ? const OrdersList()
                              : Center(
                                  child: Text(
                                    "Select an option to manage your shop",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
