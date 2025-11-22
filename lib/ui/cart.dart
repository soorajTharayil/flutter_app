import 'package:devkitflutter/config/constant.dart';
import 'package:devkitflutter/config/global_style.dart';
import 'package:devkitflutter/ui/coupon.dart';
import 'package:devkitflutter/ui/detail_food.dart';
import 'package:devkitflutter/ui/detail_restaurant.dart';
import 'package:devkitflutter/ui/order_status.dart';
import 'package:devkitflutter/ui/reusable/reusable_widget.dart';
import 'package:flutter/material.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // initialize reusable widget
  final _reusableWidget = ReusableWidget();

  final List<String> _addressData = [];
  String _address = 'Home Address';

  @override
  void initState() {
    _getData();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _getData(){
    _addressData.add('Home Address');
    _addressData.add('Office Address');
    _addressData.add('Apartment Address');
    _addressData.add('Mom Address');
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
        title: const Text('Steam Boat Lovers - Lefferts Avenue', style: GlobalStyle.appBarTitle),
        backgroundColor: GlobalStyle.appBarBackgroundColor,
        bottom: _reusableWidget.bottomAppBar(),
      ),
      body: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: kToolbarHeight+22),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(0),
              children: [
                _buildDeliveryInformation(),
                _reusableWidget.divider1(),
                _buildOrderSummary(),
                _reusableWidget.divider1(),
                _buildPayment()
              ],
            ),
          ),
          _buildPlaceOrderButton(),
        ],
      ),
    );
  }

  Widget _buildDeliveryInformation(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          color: Colors.grey[100],
          padding: const EdgeInsets.all(16),
          child: const Text('Deliver To', style: TextStyle(
              color: black77,
              fontSize: 13,
              fontWeight: FontWeight.bold
          )),
        ),
        Container(
          margin: const EdgeInsets.all(16),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: (){
              showModalBottomSheet<void>(
                isScrollControlled:true,
                context: context,
                builder: (BuildContext context) {
                  return _reusableWidget.showPopup(_address, _addressData, (String newAddress){
                    setState((){
                      _address = newAddress;
                    });
                  });
                },
              );
            },
            child: Row(
              children: [
                Container(
                    margin:const EdgeInsets.only(right:16),
                    child: const Icon(Icons.place, color: assentColor, size: 20)
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_address, style: const TextStyle(
                          color: Colors.black, fontSize: 14
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      const Text('Hilltop Playground', style: TextStyle(
                          color: softGrey, fontSize: 13
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 30, color: softGrey)
              ],
            ),
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.fromLTRB(52, 0, 16, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.all(
                Radius.circular(4)
            ),
          ),
          child: const Text('Meet me at the car park', style: TextStyle(
            color: black77,
            fontSize: 13,
          )),
        )
      ],
    );
  }

  Widget _buildOrderSummary(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Order Summary', style: GlobalStyle.orderSummary),
                  GestureDetector(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const DetailRestaurantPage()));
                    },
                    child: const Text('Add items', style: GlobalStyle.orderAction),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1x', style: GlobalStyle.orderCount),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                                child:Text('Hainam Chicken Rice', style: GlobalStyle.orderFoodTitle, maxLines: 2, overflow: TextOverflow.ellipsis)
                            ),
                            SizedBox(width: 8),
                            Text('\$4.5', style: GlobalStyle.orderPrice)
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Regular', style: GlobalStyle.orderOptions, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        const Text('Hot', style: GlobalStyle.orderOptions, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        const Text('Chicken Breast, Chicken Thighs', style: GlobalStyle.orderOptions, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        const Text('No soy sauce please', style: GlobalStyle.orderNotes),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const DetailFoodPage()));
                          },
                          child: const Text('Edit', style: GlobalStyle.orderAction),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1x', style: GlobalStyle.orderCount),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                                child:Text('Hainam Chicken Rice', style: GlobalStyle.orderFoodTitle, maxLines: 2, overflow: TextOverflow.ellipsis)
                            ),
                            SizedBox(width: 8),
                            Text('\$5.5', style: GlobalStyle.orderPrice)
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Large', style: GlobalStyle.orderOptions, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        const Text('Extra Hot', style: GlobalStyle.orderOptions, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        const Text('Chicken Wings, Chicken Thighs', style: GlobalStyle.orderOptions, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const DetailFoodPage()));
                          },
                          child: const Text('Edit', style: GlobalStyle.orderAction),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              Divider(
                height: 32,
                color: Colors.grey[400],
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal', style: GlobalStyle.orderTotalSubtitle),
                  Text('\$10', style: GlobalStyle.orderTotalSubtitle),
                ],
              ),
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery fee', style: GlobalStyle.orderTotalSubtitle),
                  Text('\$2', style: GlobalStyle.orderTotalSubtitle),
                ],
              ),
              Divider(
                height: 32,
                color: Colors.grey[400],
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: GlobalStyle.orderTotalTitle),
                  Text('\$12', style: GlobalStyle.orderTotalTitle),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildPayment(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Payment', style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold
              ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                          width: 1,
                          color: black55
                      ),
                      borderRadius: const BorderRadius.all(
                          Radius.circular(2)
                      ),
                    ),
                    child: const Text('Cash on Delivery', style: TextStyle(
                        color: black55,
                        fontSize: 12,
                        fontWeight: FontWeight.bold
                    )),
                  ),
                  GestureDetector(
                    onTap:(){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CouponPage()));
                    },
                    child: const Text('Add a coupon', style: GlobalStyle.couponAction),
                  ),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildPlaceOrderButton(){
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                color: Colors.grey[100]!,
              )
          ),
        ),
        child: GestureDetector(
          onTap: (){
            Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderStatusPage()));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: kToolbarHeight-10,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(
                  Radius.circular(6)
              ),
              color: assentColor,
            ),
            child: const Center(
              child: Text('Place Order', style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold
              )),
            ),
          ),
        ),
      ),
    );
  }
}
