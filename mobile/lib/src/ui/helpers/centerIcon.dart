import 'package:flutter/material.dart';

class CenterIcon extends StatelessWidget {
  const CenterIcon({
    super.key, 
    this.containerSize, 
    this.iconSize, 
    this.containerColor, 
    this.iconColor,
    this.iconData,
    this.child,
  });
  final double? containerSize, iconSize;
  final Color? containerColor, iconColor;
  final IconData? iconData;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    double hw = containerSize ?? 40;
    Color cc = containerColor ?? Color(0xec8f5e1e);
    Color ic = iconColor ?? Colors.white;
    double iSize = iconSize ?? 20;
    return Material(
      color: cc,
      borderRadius: BorderRadius.circular(hw/2),
      child: SizedBox(
        height: hw,
        width: hw,
        child: Center(child: child ?? Icon(iconData ?? Icons.add, color: ic,size: iSize,)),
      ),
    );
  }
}
