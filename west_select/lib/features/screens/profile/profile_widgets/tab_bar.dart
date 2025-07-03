import 'package:flutter/material.dart';

class OrderTabBar extends StatelessWidget {
  const OrderTabBar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _btn('Pending Orders', 0),
          _btn('Completed Orders', 1),
        ],
      );

  Widget _btn(String label, int idx) => GestureDetector(
        onTap: () => onSelect(idx),
        child: Column(children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected == idx ? Colors.blue : Colors.grey)),
          if (selected == idx)
            Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 20,
                color: Colors.blue)
        ]),
      );
}
