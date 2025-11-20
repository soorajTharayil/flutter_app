import 'package:devkitflutter/config/constant.dart';
import 'package:devkitflutter/config/global_style.dart';
import 'package:devkitflutter/ui/cart.dart';
import 'package:devkitflutter/ui/coupon.dart';
import 'package:devkitflutter/model/food_model.dart';
import 'package:devkitflutter/ui/restaurant_information.dart';
import 'package:devkitflutter/ui/reusable/reusable_widget.dart';
import 'package:devkitflutter/ui/reusable/cache_image_network.dart';
import 'package:flutter/material.dart';

class DetailRestaurantPage extends StatefulWidget {
  const DetailRestaurantPage({Key? key}) : super(key: key);

  @override
  State<DetailRestaurantPage> createState() => _DetailRestaurantPageState();
}

class _DetailRestaurantPageState extends State<DetailRestaurantPage> {
  // initialize reusable widget
  final _reusableWidget = ReusableWidget();

  bool _showAppBar = false;

  late ScrollController _scrollController;

  List<FoodModel> _foodData = [];

  @override
  void initState() {
    setupAnimateAppbar();
    _getData();

    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void setupAnimateAppbar(){
    _scrollController = ScrollController()..addListener((){
      if(_scrollController.hasClients && _scrollController.offset > (MediaQuery.of(context).size.width*3/4)-80){
        setState(() {
          _showAppBar = true;
        });
      } else {
        setState(() {
          _showAppBar = false;
        });
      }
    });
  }

  void _getData(){
    /*
    Image Information
    width = 800px
    height = 600px
    ratio width height = 4:3
     */
    _foodData = [
      FoodModel(
          id: 8,
          restaurantName: "Chicken Specialties",
          name: "Chicken Rice Teriyaki",
          image: "$globalUrl/apps/food_delivery/food/8.jpg",
          price: 5,
          discount: 10,
          rating: 4.7,
          distance: 3.9,
          location: "Liberty Avenue"
      ),
      FoodModel(
          id: 6,
          restaurantName: "Bread and Cookies",
          name: "Delicious Croissant",
          image: "$globalUrl/apps/food_delivery/food/6.jpg",
          price: 5,
          discount: 0,
          rating: 4.8,
          distance: 0.9,
          location: "Mapple Street"
      ),
      FoodModel(
          id: 7,
          restaurantName: "Taco Salad Beef Classic",
          name: "Awesome Health",
          image: "$globalUrl/apps/food_delivery/food/7.jpg",
          price: 4.9,
          discount: 10,
          rating: 4.9,
          distance: 1.1,
          location: "Fenimore Street"
      ),
      FoodModel(
          id: 5,
          restaurantName: "Italian Food",
          name: "Chicken Penne With Tomato",
          image: "$globalUrl/apps/food_delivery/food/5.jpg",
          price: 6.5,
          discount: 20,
          rating: 4.6,
          distance: 0.9,
          location: "New York Avenue"
      ),
      FoodModel(
          id: 4,
          restaurantName: "Steam Boat Lovers",
          name: "Seafood shabu-shabu",
          image: "$globalUrl/apps/food_delivery/food/4.jpg",
          price: 6,
          discount: 20,
          rating: 4.9,
          distance: 0.7,
          location: "Lefferts Avenue"
      ),
      FoodModel(
          id: 3,
          restaurantName: "Salad Stop",
          name: "Sesame Salad",
          image: "$globalUrl/apps/food_delivery/food/3.jpg",
          price: 4.8,
          discount: 10,
          rating: 4.3,
          distance: 0.7,
          location: "Empire Boulevard"
      ),
      FoodModel(
          id: 2,
          restaurantName: "Beef Lovers",
          name: "Beef Yakiniku",
          image: "$globalUrl/apps/food_delivery/food/2.jpg",
          price: 3.6,
          discount: 20,
          rating: 5,
          distance: 0.6,
          location: "Montgomery Street"
      ),
      FoodModel(
          id: 1,
          restaurantName: "Mr. Hungry",
          name: "Hainam Chicken Rice",
          image: "$globalUrl/apps/food_delivery/food/1.jpg",
          price: 5,
          discount: 50,
          rating: 4.9,
          distance: 0.4,
          location: "Crown Street"
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final double bannerWidth = MediaQuery.of(context).size.width;
    final double bannerHeight = MediaQuery.of(context).size.width*3/4;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: kToolbarHeight+22),
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(0),
              children: [
                buildCacheNetworkImage(width: bannerWidth, height: bannerHeight, url: "$globalUrl/apps/food_delivery/food/4.jpg"),
                _buildMerchantTop(),
                _reusableWidget.divider1(),
                _buildNewMenu(),
                _reusableWidget.divider1(),
                _buildChickenMenu(),
                _reusableWidget.divider1(),
                _buildBeefMenu(),
              ],
            ),
          ),
          Opacity(
            opacity: _showAppBar?1:0,
            child: SizedBox(
              height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top - 20 + 22,
              child: AppBar(
                iconTheme: const IconThemeData(
                  color: GlobalStyle.appBarIconThemeColor,
                ),
                systemOverlayStyle: GlobalStyle.appBarSystemOverlayStyle,
                centerTitle: true,
                title: const Text('Steam Boat Lovers - Lefferts Avenue', style: GlobalStyle.appBarTitle),
                backgroundColor: GlobalStyle.appBarBackgroundColor,
              ),
            ),
          ),
          _buildViewCartButton(),
        ],
      ),
    );
  }

  Widget _buildMerchantTop(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Preferred Merchants', style: GlobalStyle.preferredMerchant),
              GestureDetector(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RestaurantInformationPage()));
                  },
                  child: const Icon(Icons.info_outline, size: 20, color: black77)
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: const Text('Steam Boat Lovers - Lefferts Avenue', style: GlobalStyle.restaurantTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(height: 4),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: const Text('Hot, Fresh, Steam', style: GlobalStyle.restaurantTag),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: const Row(
            children: [
              Icon(Icons.star, color: Colors.orange, size: 15),
              SizedBox(width: 2),
              Text('4.9', style: GlobalStyle.textRatingDistances),
              SizedBox(width: 6),
              Icon(Icons.location_pin, color: assentColor, size: 15),
              SizedBox(width: 2),
              Text('0.7 miles', style: GlobalStyle.textRatingDistances),
            ],
          ),
        ),
        _reusableWidget.divider2(),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap:(){
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CouponPage()));
            },
            child: const Row(
              children: [
                Icon(Icons.local_offer_outlined, color: assentColor, size: 16),
                SizedBox(width: 4),
                Text('Check for available coupons'),
                Spacer(),
                Text('See Coupons', style: GlobalStyle.couponAction),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16)
      ],
    );
  }

  Widget _buildNewMenu(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: const Text('New Menu', style: GlobalStyle.menuTitle),
        ),
        ListView.builder(
          primary: false,
          shrinkWrap: true,
          itemCount: _foodData.length,
          padding: const EdgeInsets.symmetric(vertical: 0),
          itemBuilder: (BuildContext context, int index) {
            return _reusableWidget.buildFoodDetailList(context, index, _foodData);
          },
        )
      ],
    );
  }

  Widget _buildChickenMenu(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: const Text('Chicken Menu', style: GlobalStyle.menuTitle),
        ),
        ListView.builder(
          primary: false,
          shrinkWrap: true,
          itemCount: _foodData.length,
          padding: const EdgeInsets.symmetric(vertical: 0),
          itemBuilder: (BuildContext context, int index) {
            return _reusableWidget.buildFoodDetailList(context, index, _foodData);
          },
        )
      ],
    );
  }

  Widget _buildBeefMenu(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: const Text('Beef Menu', style: GlobalStyle.menuTitle),
        ),
        ListView.builder(
          primary: false,
          shrinkWrap: true,
          itemCount: _foodData.length,
          padding: const EdgeInsets.symmetric(vertical: 0),
          itemBuilder: (BuildContext context, int index) {
            return _reusableWidget.buildFoodDetailList(context, index, _foodData);
          },
        )
      ],
    );
  }

  Widget _buildViewCartButton(){
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage()));
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
            child: const Row(
              children: [
                Text('View Cart', style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold
                )),
                SizedBox(width: 16),
                Text('3 Items', style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                )),
                Spacer(),
                Text('\$14', style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
