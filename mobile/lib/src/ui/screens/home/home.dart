import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mobile/src/ui/helpers/centerIcon.dart';
import 'package:mobile/src/ui/helpers/draggableSheet.dart';
import 'package:mobile/src/ui/screens/home/widgets/lineChart.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  @override
  Widget build(BuildContext context) {
    const Color neonGreen = Color(0xFFD4F06B);
    const Color secondNeonGreen = Color(0xFF9BBA0F);
    final currentTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: neonGreen,
      body: Stack(
        children: [
          Positioned.fill(
              top: 40,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 300,
                      child: ListTile(
                        title: Center(child: Text('My Meme Coins')),
                        leading: CenterIcon(
                          containerColor: Colors.pinkAccent,
                          child: Text('😎'),
                        ),
                        trailing: CenterIcon(
                          containerColor: Color(0xff01197e),
                          iconData: Icons.add,
                        ),
                      ),
                    ),
                
                    SizedBox(height: 30),
                
                    Text(
                      '10 780,48 \$',
                      style: currentTheme.headlineLarge?.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                
                    SizedBox(height: 3),
                    Container(
                      height: 27,
                      width: 120,
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: secondNeonGreen,
                      ),
                      child: Center(
                        child: Text(
                          '+749,44 \$ (+ 2,15 %)',
                          style: currentTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                
                    LineChartHome(
                
                    ),
                    SizedBox(height: 200)
                  ],
                ),
              ),
          ),

          CustomDraggableSheet(
            child: ListView(
              children: [
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
