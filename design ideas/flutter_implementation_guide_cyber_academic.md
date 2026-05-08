# Design System: Cyber-Academic Intelligence System (Flutter Edition)

## 🎨 Visual Identity
A high-tech bridge between academic rigor and AI innovation. This "Cyber Edition" utilizes deep void surfaces, holographic glassmorphism, and neon accents.

## 🌈 Color Palette (ThemeData)

```dart
class CyberTheme {
  // Dark Mode (Core)
  static const Color surface = Color(0xFF111317);
  static const Color surfaceDim = Color(0xFF0D0F12);
  static const Color primary = Color(0xFF00E5FF); // Electric Cyan
  static const Color secondary = Color(0xFF7209B7); // Cyber Purple
  static const Color accent = Color(0xFF39FF14); // Acid Green
  static const Color onSurface = Colors.white;
  static const Color onSurfaceVariant = Color(0xFF94A3B8);

  // Glassmorphism helper
  static BoxDecoration glassDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.05),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withOpacity(0.1)),
  );
}
```

## 📐 Typography
- **Font:** `Montserrat`
- **Headlines:** Bold/ExtraBold for tech-forward impact.
- **Data Points:** SemiBold with glowing effects (Shadows) in Dark Mode.

---

# Flutter Component Examples

## 1. Dashboard Metric Card (CRA)
```dart
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String delta;

  const MetricCard({required this.label, required this.value, required this.delta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: CyberTheme.glassDecoration.copyWith(
        boxShadow: [
          BoxShadow(
            color: CyberTheme.primary.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label.toUpperCase(), 
                style: TextStyle(color: CyberTheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: CyberTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(delta, style: TextStyle(color: CyberTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: value, style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white)),
                TextSpan(text: ' / 5.0', style: TextStyle(fontSize: 18, color: CyberTheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## 2. AI Chat Bubble (Assistant)
```dart
class AIChatBubble extends StatelessWidget {
  final String message;

  const AIChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: CyberTheme.secondary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: CyberTheme.secondary.withOpacity(0.4), blurRadius: 15)],
            ),
            child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: CyberTheme.glassDecoration.copyWith(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(message, style: TextStyle(color: Colors.white, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}
```

## 3. Holographic Bottom Nav
```dart
class CyberNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CyberTheme.surfaceDim.withOpacity(0.8),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.dashboard, label: 'CRA', isActive: true),
              _NavItem(icon: Icons.auto_awesome, label: 'ASSISTANT'),
              _NavItem(icon: Icons.analytics, label: 'GRADES'),
              _NavItem(icon: Icons.person, label: 'PROFILE'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  const _NavItem({required this.icon, required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? CyberTheme.primary : CyberTheme.onSurfaceVariant),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: isActive ? CyberTheme.primary : CyberTheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
```