import 'package:devkitflutter/config/constant.dart';
import 'package:devkitflutter/config/global_style.dart';
import 'package:devkitflutter/model/coupon_model.dart';
import 'package:devkitflutter/ui/reusable/reusable_widget.dart';
import 'package:devkitflutter/ui/reusable/cache_image_network.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CouponDetailPage extends StatefulWidget {
  final CouponModel couponData;

  const CouponDetailPage({Key? key, required this.couponData}) : super(key: key);

  @override
  State<CouponDetailPage> createState() => _CouponDetailPageState();
}

class _CouponDetailPageState extends State<CouponDetailPage> {
  // initialize reusable widget
  final _reusableWidget = ReusableWidget();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: GlobalStyle.appBarIconThemeColor,
        ),
        systemOverlayStyle: GlobalStyle.appBarSystemOverlayStyle,
        centerTitle: true,
        title: const Text('Coupon Detail', style: GlobalStyle.appBarTitle),
        backgroundColor: GlobalStyle.appBarBackgroundColor,
        bottom: _reusableWidget.bottomAppBar(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          Align(
            alignment: Alignment.center,
            child: buildCacheNetworkImage(height: 80, url: '$globalUrl/apps/food_delivery/merchant_logo.png', plColor: Colors.transparent),
          ),
          _buildCouponCard(widget.couponData),
          Container(
            margin: const EdgeInsets.only(top: 24),
            child: const Text('Terms and Conditions', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold
            )),
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: Text(widget.couponData.term),
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: TextButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) => primaryColor,
                  ),
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3.0),
                      )
                  ),
                ),
                onPressed: () {
                  Fluttertoast.showToast(msg: 'Coupon applied', toastLength: Toast.LENGTH_LONG);
                  Navigator.pop(context);
                  if(widget.couponData.id!=999){
                    Navigator.pop(context);
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 5.0),
                  child: Text(
                    'Use',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(CouponModel couponData){
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      elevation: 2,
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(couponData.name, style: GlobalStyle.couponName.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  decoration: BoxDecoration(
                      color: assentColor,
                      borderRadius: BorderRadius.circular(5)
                  ), //
                  child: const Text('Limited Offer', style: GlobalStyle.couponLimitedOffer),
                ),
                Row(
                  children: [
                    const Icon(
                        Icons.access_time,
                        size: 14,
                        color: softGrey
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Text('Expiring in ${couponData.day} days', style: GlobalStyle.couponExpiringDate),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
