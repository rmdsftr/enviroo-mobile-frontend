import 'package:enviroo/screens/nasabah/home_screen.dart';
import 'package:flutter/material.dart';

class ProfilBsuScreen extends StatefulWidget {
  final String namaBank;
  final String alamatBank;
  final String? namaInduk;
  final String? photoBank;

  const ProfilBsuScreen({
    super.key,
    required this.namaBank,
    required this.alamatBank,
    this.namaInduk,
    this.photoBank,
  });

  @override
  State<ProfilBsuScreen> createState() => _ProfilBsuScreenState();
}

class _ProfilBsuScreenState extends State<ProfilBsuScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 25),
      child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: const Color(0xFF4EA771),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20)
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Center(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: const Color(0xFF013236).withOpacity(0.05),
                              shape: BoxShape.circle
                          ),
                          child: Image.network(
                            widget.photoBank != null && widget.photoBank!.isNotEmpty 
                                ? widget.photoBank! 
                                : "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQcsLMxl59B-uLQ0g27IEy0JRCIkqGJY8oKbw&s",
                            fit: BoxFit.cover,
                            height: 185,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 185,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported_rounded,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.namaBank,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Color(0xFF013236),
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Address
                          Text(
                            widget.alamatBank,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Color(0xFF013236),
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),

                          if(widget.namaInduk != null)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF013236),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Text(
                                  widget.namaInduk!,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    color: Color(0xFFFFFFFF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          )
      ),
    );
  }
}
