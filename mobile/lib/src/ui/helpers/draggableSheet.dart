import 'package:flutter/material.dart';

class CustomDraggableSheet extends StatefulWidget {
  const CustomDraggableSheet({super.key, required this.child, this.backgroundColor});
  final Widget child;
  final Color? backgroundColor;
  @override
  State<CustomDraggableSheet> createState() => _CustomDraggableSheetState();
}

class _CustomDraggableSheetState extends State<CustomDraggableSheet> {

  final DraggableScrollableController sheetController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    sheetController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: sheetController,
      initialChildSize: .3,
      maxChildSize: .7,
      minChildSize: .1,
      snapSizes: [.1,.3,.7],
      builder: (context, scrollController) {
        final currentSize = scrollController.hasClients ? sheetController.size : .3;
        return AnimatedContainer(
          duration: Duration(milliseconds: 150),
          margin: EdgeInsets.symmetric(
            horizontal: currentSize < 0.2 ? 20 : 0
          ),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Color(0xff123234),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(currentSize < 0.2 ? 20 : 30),
            ),
          ),
          child: Column(
            spacing: 20,
            children: [
              SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: GestureDetector(
                  onTap: () {
                    double currentSize = sheetController.size;

                    double targetSize = currentSize < 0.4 ? 0.7 : 0.3;
                    sheetController.animateTo(
                      targetSize,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Center(
                    child: Container(
                      height: 5,
                      width: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.yellowAccent,
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(child: widget.child)
            ],
          ),
        );
      },
    );
  }
}
