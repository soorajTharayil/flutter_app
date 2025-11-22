import 'dart:async';

import 'package:devkitflutter/config/constant.dart';
import 'package:devkitflutter/config/global_style.dart';
import 'package:devkitflutter/ui/reusable/reusable_widget.dart';
import 'package:devkitflutter/model/restaurant_model.dart';
import 'package:devkitflutter/ui/reusable/shimmer_loading.dart';
import 'package:flutter/material.dart';

class CategoryMenuPage extends StatefulWidget {
  final String title;

  const CategoryMenuPage({Key? key, this.title = 'Food Around You'}) : super(key: key);

  @override
  State<CategoryMenuPage> createState() => _CategoryMenuPageState();
}

class _CategoryMenuPageState extends State<CategoryMenuPage> {
  // initialize shimmer loading and reusable widget
  final _shimmerLoading = ShimmerLoading();
  final _reusableWidget = ReusableWidget();

  bool _loading = true;
  Timer? _timerDummy;

  List<RestaurantModel> _foodData = [];

  bool _isNearby = false;
  bool _isBestSeller = false;
  bool _isPromo = false;
  bool _isNewComers = false;
  bool _isDrink = false;

  @override
  void initState() {
    _getData();

    super.initState();
  }

  @override
  void dispose() {
    _timerDummy?.cancel();
    super.dispose();
  }

  void _getData(){
    // this timer function is just for demo, so after 1 second, the shimmer loading will disappear and show the content
    _timerDummy = Timer(const Duration(seconds: 1), () {
      setState(() {
        _loading = false;
      });
    });

    /*
    Image Information
    width = 800px
    height = 600px
    ratio width height = 4:3
     */
    _foodData = [
      RestaurantModel(
          id: 1,
          name: "Mr. Hungry",
          tag: "Chicken, Rice",
          image: "$globalUrl/apps/food_delivery/food/1.jpg",
          rating: 4.9,
          distance: 0.4,
          promo: '50% Off | Get Gift Voucher If You Buy 4 pcs',
          location: "Crown Street"
      ),
      RestaurantModel(
          id: 2,
          name: "Beef Lovers",
          tag: "Beef, Yakiniku, Japanese Food",
          image: "$globalUrl/apps/food_delivery/food/2.jpg",
          rating: 5,
          distance: 0.6,
          promo: 'Buy 1 Get 1',
          location: "Montgomery Street"
      ),
      RestaurantModel(
          id: 3,
          name: "Salad Stop",
          tag: "Healthy Food, Salad",
          image: "$globalUrl/apps/food_delivery/food/3.jpg",
          rating: 4.3,
          distance: 0.7,
          promo: '',
          location: "Empire Boulevard"
      ),
      RestaurantModel(
          id: 4,
          name: "Steam Boat Lovers",
          tag: "Hot, Fresh, Steam",
          image: "$globalUrl/apps/food_delivery/food/4.jpg",
          rating: 4.9,
          distance: 0.7,
          promo: '20% Off',
          location: "Lefferts Avenue"
      ),
      RestaurantModel(
          id: 5,
          name: "Italian Food",
          tag: "Penne, Western Food",
          image: "$globalUrl/apps/food_delivery/food/5.jpg",
          rating: 4.6,
          distance: 0.9,
          promo: '',
          location: "New York Avenue"
      ),
      RestaurantModel(
          id: 6,
          name: "Bread and Cookies",
          tag: "Bread",
          image: "$globalUrl/apps/food_delivery/food/6.jpg",
          rating: 4.8,
          distance: 0.9,
          promo: '',
          location: "Mapple Street"
      ),
      RestaurantModel(
          id: 7,
          name: "Awesome Health",
          tag: "Salad, Healthy Food, Fresh",
          image: "$globalUrl/apps/food_delivery/food/7.jpg",
          rating: 4.9,
          distance: 1.1,
          promo: '10% Off',
          location: "Fenimore Street"
      ),
      RestaurantModel(
          id: 8,
          name: "Chicken Specialties",
          tag: "Chicken, Rice, Teriyaki",
          image: "$globalUrl/apps/food_delivery/food/8.jpg",
          rating: 4.7,
          distance: 3.9,
          promo: '10% Off',
          location: "Liberty Avenue"
      ),
    ];
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
        title: Text(widget.title, style: GlobalStyle.appBarTitle),
        backgroundColor: GlobalStyle.appBarBackgroundColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[100]!,
                    width: 1.0,
                  )
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            height: kToolbarHeight,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(
                  label: const Text('Nearby'),
                  labelStyle: TextStyle(color: _isNearby?Colors.white:Colors.black),
                  selected: _isNearby,
                  onSelected: (bool selected) {
                    refreshData();
                    setState(() {
                      _isNearby = !_isNearby;
                    });
                  },
                  elevation: 0,
                  pressElevation: 0,
                  backgroundColor: Colors.grey[200],
                  selectedColor: primaryColor,
                  checkmarkColor: Colors.white,
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Best Seller'),
                  labelStyle: TextStyle(color: _isBestSeller?Colors.white:Colors.black),
                  selected: _isBestSeller,
                  onSelected: (bool selected) {
                    refreshData();
                    setState(() {
                      _isBestSeller = !_isBestSeller;
                    });
                  },
                  elevation: 0,
                  pressElevation: 0,
                  backgroundColor: Colors.grey[200],
                  selectedColor: primaryColor,
                  checkmarkColor: Colors.white,
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Promo'),
                  labelStyle: TextStyle(color: _isPromo?Colors.white:Colors.black),
                  selected: _isPromo,
                  onSelected: (bool selected) {
                    refreshData();
                    setState(() {
                      _isPromo = !_isPromo;
                    });
                  },
                  elevation: 0,
                  pressElevation: 0,
                  backgroundColor: Colors.grey[200],
                  selectedColor: primaryColor,
                  checkmarkColor: Colors.white,
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('New Comers'),
                  labelStyle: TextStyle(color: _isNewComers?Colors.white:Colors.black),
                  selected: _isNewComers,
                  onSelected: (bool selected) {
                    refreshData();
                    setState(() {
                      _isNewComers = !_isNewComers;
                    });
                  },
                  elevation: 0,
                  pressElevation: 0,
                  backgroundColor: Colors.grey[200],
                  selectedColor: primaryColor,
                  checkmarkColor: Colors.white,
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Drink'),
                  labelStyle: TextStyle(color: _isDrink?Colors.white:Colors.black),
                  selected: _isDrink,
                  onSelected: (bool selected) {
                    refreshData();
                    setState(() {
                      _isDrink = !_isDrink;
                    });
                  },
                  elevation: 0,
                  pressElevation: 0,
                  backgroundColor: Colors.grey[200],
                  selectedColor: primaryColor,
                  checkmarkColor: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: (_loading == true)
            ? _shimmerLoading.buildShimmerContent()
            : ListView.builder(
          itemCount: _foodData.length,
          padding: const EdgeInsets.symmetric(vertical: 0),
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return _reusableWidget.buildRestaurantList(context, index, _foodData);
          },
        ),
      ),
      floatingActionButton: _reusableWidget.fabCart(context),
    );
  }

  Future refreshData() async {
    setState(() {
      _foodData.clear();
      _loading = true;
      _getData();
    });
  }
}
