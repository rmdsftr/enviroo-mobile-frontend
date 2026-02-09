import 'package:flutter/material.dart';

class BalanceLayouts extends StatefulWidget{
  @override
  State<BalanceLayouts> createState() => _BalanceLayoutState(); 
}

class _BalanceLayoutState extends State<BalanceLayouts>{
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(25),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF013236),
              borderRadius: BorderRadius.circular(20)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.monetization_on_rounded,
                          color: Color(0xFFC1E6BA),
                          size: 27,
                        ),
                        SizedBox(width: 10),
                        Text(
                            "Saldo \nuang",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFFC1E6BA),
                            fontSize: 10
                          ),
                        )
                      ],
                    )
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "Rp1.345.000",
                      style: TextStyle(
                        color: Color(0xFFC1E6BA),
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 15
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Color(0xFF4EA771),
                borderRadius: BorderRadius.circular(20)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.numbers_rounded,
                          color: Color(0xFFC1E6BA),
                          size: 27,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Saldo \npoin",
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFFC1E6BA),
                              fontSize: 10
                          ),
                        )
                      ],
                    )
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "1590",
                      style: TextStyle(
                          color: Color(0xFFC1E6BA),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 15
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}