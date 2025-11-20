import 'package:devkitflutter/config/constant.dart';
import 'package:devkitflutter/config/global_style.dart';
import 'package:devkitflutter/ui/cart.dart';
import 'package:devkitflutter/ui/detail_food.dart';
import 'package:devkitflutter/ui/detail_restaurant.dart';
import 'package:devkitflutter/ui/search_address.dart';
import 'package:devkitflutter/ui/reusable/cache_image_network.dart';
import 'package:devkitflutter/ui/reusable/global_function.dart';
import 'package:flutter/material.dart';

class ReusableWidget{
  // initialize global function
  final _globalFunction = GlobalFunction();

  PreferredSizeWidget bottomAppBar(){
    return PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: Colors.grey[100],
          height: 1.0,
        ));
  }

  Widget fabCart(context){
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage()));
      },
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))),
      child: Stack(
        children: [
          const Icon(Icons.shopping_bag_outlined, color: black21, size: 42),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(14),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: const Center(
                child: Text('3', style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget createDefaultLabel(context, String text){
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
      decoration: BoxDecoration(
          color: softBlue,
          borderRadius: BorderRadius.circular(2)
      ),
      child: Row(
        children: [
          Text(text, style: const TextStyle(
              color: Colors.white, fontSize: 13
          )),
          const SizedBox(
            width: 4,
          ),
          const Icon(Icons.done, color: Colors.white, size: 11)
        ],
      ),
    );
  }

  Widget buildHorizontalListCard(context, data){
    final double imageWidth = (MediaQuery.of(context).size.width / 2.3);
    final double imageheight = (MediaQuery.of(context).size.width / 3.07);
    return SizedBox(
      width: imageWidth,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        elevation: 2,
        color: Colors.white,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: (){
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DetailRestaurantPage()));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(6)),
                  child: buildCacheNetworkImage(width: imageWidth, height: imageheight, url: data.image)
              ),
              Container(
                margin: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 36,
                      child: Text(data.name+' - '+data.location, style: GlobalStyle.cardTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(height: 6),
                    data.promo!=''
                        ? Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, color: assentColor, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(data.promo, style: GlobalStyle.textPromo, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ) : const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRestaurantList(context, index, data){
    final double boxImageSize = (MediaQuery.of(context).size.width / 4);
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: (){
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DetailRestaurantPage()));
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                    borderRadius:
                    const BorderRadius.all(Radius.circular(4)),
                    child: buildCacheNetworkImage(width: boxImageSize, height: boxImageSize, url: data[index].image)),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data[index].name+' - '+data[index].location, style: GlobalStyle.textRestaurantNameBig, maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(data[index].tag, style: GlobalStyle.textTag, maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 15),
                          const SizedBox(width: 2),
                          Text(data[index].rating.toString(), style: GlobalStyle.textRatingDistances),
                          const SizedBox(width: 6),
                          const Icon(Icons.location_pin, color: assentColor, size: 15),
                          const SizedBox(width: 2),
                          Text('${data[index].distance} miles', style: GlobalStyle.textRatingDistances),
                        ],
                      ),
                      const SizedBox(height: 6),
                      data[index].promo!=''
                          ? Row(
                        children: [
                          const Icon(Icons.local_offer_outlined, color: assentColor, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(data[index].promo, style: GlobalStyle.textPromo, maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ) : const SizedBox.shrink(),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        (index == data.length - 1)
            ? const Wrap()
            : Divider(
          height: 0,
          color: Colors.grey[400],
        )
      ],
    );
  }

  Widget buildFoodList(context, index, data){
    final double boxImageSize = (MediaQuery.of(context).size.width / 4);
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: (){
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DetailRestaurantPage()));
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DetailFoodPage()));
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                    child: buildCacheNetworkImage(width: boxImageSize, height: boxImageSize, url: data[index].image)),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data[index].name, style: GlobalStyle.textRestaurantNameBig, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text(data[index].restaurantName+' - '+data[index].location, style: GlobalStyle.textRestaurantNameNormal, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 15),
                          const SizedBox(width: 2),
                          Text(data[index].rating.toString(), style: GlobalStyle.textRatingDistances),
                          const SizedBox(width: 6),
                          const Icon(Icons.location_pin, color: assentColor, size: 15),
                          const SizedBox(width: 2),
                          Text('${data[index].distance} miles', style: GlobalStyle.textRatingDistances),
                        ],
                      ),
                      const SizedBox(height: 12),
                      data[index].discount!=0
                          ? Text('\$ ${_globalFunction.removeDecimalZeroFormat(data[index].price)}', style: GlobalStyle.textPriceLineThrough) : const SizedBox.shrink(),
                      Text('\$ ${_globalFunction.removeDecimalZeroFormat(((100-data[index].discount)*data[index].price/100))}', style: GlobalStyle.textPrice),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        (index == data.length - 1)
            ? const Wrap()
            : Divider(
          height: 0,
          color: Colors.grey[400],
        )
      ],
    );
  }

  Widget buildFoodDetailList(context, index, data){
    final double boxImageSize = (MediaQuery.of(context).size.width / 4);
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: (){
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DetailFoodPage()));
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                    borderRadius:
                    const BorderRadius.all(Radius.circular(4)),
                    child: buildCacheNetworkImage(width: boxImageSize, height: boxImageSize, url: data[index].image)),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(data[index].name, style: GlobalStyle.restaurantFoodTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                          Text('\$ ${_globalFunction.removeDecimalZeroFormat(((100-data[index].discount)*data[index].price/100))}', style: GlobalStyle.restaurantFoodPrice),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam eu risus nec arcu cursus accumsan in id felis.', style: GlobalStyle.restaurantFoodDesc, maxLines: 3, overflow: TextOverflow.ellipsis)
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        (index == data.length - 1)
            ? const Wrap()
            : Divider(
          height: 0,
          color: Colors.grey[400],
        )
      ],
    );
  }

  Widget showPopup(address, addressData, Function(String newAddress) changeAddress){
    // must use StateSetter to update data between main screen and popup.
    // if use default setState, the data will not update
    return StatefulBuilder(builder: (BuildContext context, StateSetter mystate) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text('Address List', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold
            )),
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: List.generate(addressData.length,(index){
                return Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap:(){
                        Navigator.pop(context);
                        changeAddress(addressData[index]);
                      },
                      child: addressData[index]==address
                          ? Row(
                        children: [
                          Text(addressData[index], style: const TextStyle(
                              color: black55, fontSize: 16
                          )),
                          const Spacer(),
                          createDefaultLabel(context, 'Current'),
                        ],
                      ) : Align(
                        alignment: Alignment.topLeft,
                        child: Text(addressData[index], style: const TextStyle(
                            color: black55, fontSize: 16
                        )),
                      ),
                    ),
                    Divider(
                      height: 32,
                      color: Colors.grey[400],
                    ),
                    addressData.length==index+1
                        ? SizedBox(
                            width: double.maxFinite,
                            child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchAddressPage()));
                            },
                            style: ButtonStyle(
                                overlayColor: MaterialStateProperty.all(Colors.transparent),
                                shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0),
                                    )
                                ),
                                side: MaterialStateProperty.all(
                                  const BorderSide(
                                      color: primaryColor,
                                      width: 1.0
                                  ),
                                )
                            ),
                            child: const Text(
                              'Add New Address',
                              style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13
                              ),
                              textAlign: TextAlign.center,
                            )
                          ),
                        ) : const SizedBox.shrink(),
                  ],
                );
              }),
            ),
          ),
        ],
      );
    });
  }

  Widget deliveryInformation(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: const Text('Delivery Information', style: GlobalStyle.deliveryInformationTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: softBlue
                    ),
                    child: const Center(
                        child: Icon(Icons.restaurant, size: 12, color: Colors.white)
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text('M3GC+C2 Brooklyn, New York, United States', style: GlobalStyle.deliveryInformationAddress, maxLines:1, overflow: TextOverflow.ellipsis),
                  )
                ],
              ),
              const SizedBox(height: 4),
              Container(
                  margin: const EdgeInsets.only(left: 11),
                  width: 1,
                  height: 12,
                  color: softGrey
              ),
              const SizedBox(height: 2),
              const Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(
                        child: Icon(Icons.location_pin, size: 24, color: assentColor)
                    ),
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text('Home Address', style: GlobalStyle.deliveryInformationAddress, maxLines:1, overflow: TextOverflow.ellipsis),
                  )
                ],
              ),
              Divider(
                height: 32,
                color: Colors.grey[400],
              ),
              const Text('Note to driver', style: GlobalStyle.deliveryInformationNoteTitle),
              const SizedBox(height: 4),
              const Text('Meet me at the car park', style: GlobalStyle.deliveryInformationNoteValue)
            ],
          ),
        )
      ],
    );
  }

  Widget divider1(){
    return Container(
      height: 8,
      color: Colors.grey[100],
    );
  }

  Widget divider2(){
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 32,
        color: Colors.grey[400],
      ),
    );
  }

  Widget divider3(){
    return Divider(
      height: 32,
      color: Colors.grey[400],
    );
  }
}