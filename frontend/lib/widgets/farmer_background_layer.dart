import 'package:flutter/material.dart';

class FarmerBackgroundLayer extends StatelessWidget {
  const FarmerBackgroundLayer({super.key});

  static const imageUrl =
      'https://img.freepik.com/premium-photo/agriculture-project-africa_943281-36244.jpg?w=2000';

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF0B1326)),
        ),
        const ColoredBox(color: Color(0xD90B1326)),
      ],
    ),
  );
}
