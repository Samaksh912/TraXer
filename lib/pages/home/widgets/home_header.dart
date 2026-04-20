import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onNotificationsTap,
  });

  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: const Color(0xFF40485D).withOpacity(0.3)),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCMa9MlXowKW3yW4mVI5HrKq3Isaxiy5dV86De3ubGy53ihw60STZSNUIO9TU55opa0HpVZp_KimCc99OcYsEUkVTwwg6nQjS_izDl-uHJIMms0eAnY__MC53WqSI9gQz-7M5Lbv_AgsLCyjoPVIPo_IBcs4q5vIyygbBLfVIqspn0c-4dQY2RY3XDmkUi93JmxhD-JT9zWN7HOAQlElm9t_zglmh2UUo-dQloz6cR41wgPd1oNHMX4fm64Mz9-lbI8ukT-5AVm9Q',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'EXPNSE',
              style: TextStyle(
                color: Color(0xFF9EFFC8),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: onNotificationsTap,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child:
                Icon(Icons.notifications_outlined, color: Color(0xFF9EFFC8)),
          ),
        ),
      ],
    );
  }
}

