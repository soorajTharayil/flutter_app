import 'dart:async';

import 'package:devkitflutter/config/constant.dart';
import 'package:devkitflutter/config/global_style.dart';
import 'package:devkitflutter/ui/reusable/reusable_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddAddressPage extends StatefulWidget {
  final bool fromList;

  const AddAddressPage({Key? key, this.fromList = false}) : super(key: key);

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  // initialize reusable widget
  final _reusableWidget = ReusableWidget();

  late GoogleMapController _controller;
  bool _mapLoading = true;
  Timer? _timerDummy;

  final LatLng _initialPosition = const LatLng(40.675416, -73.914554);

  Marker? _marker;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    if(!kIsWeb) {
      _timerDummy?.cancel();
    }
    super.dispose();
  }

  // add marker
  void _addMarker(double lat, double lng) {
    LatLng position = LatLng(lat, lng);

    // set initial marker
    _marker = Marker(
      markerId: const MarkerId('marker1'),
      position: position,
      icon: BitmapDescriptor.defaultMarker,
    );

    CameraUpdate u2 = CameraUpdate.newCameraPosition(CameraPosition(target: position, zoom: 15));

    _controller.moveCamera(u2).then((void v) {
      _check(u2, _controller);
    });
  }

  /* start additional function for camera update
  - we get this function from the internet
  - if we don't use this function, the camera will not work properly (Zoom to marker sometimes not work)
  */
  void _check(CameraUpdate u, GoogleMapController c) async {
    c.moveCamera(u);
    _controller.moveCamera(u);
    LatLngBounds l1 = await c.getVisibleRegion();
    LatLngBounds l2 = await c.getVisibleRegion();

    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      _check(u, c);
    }
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
        title: const Text('Add New Address', style: GlobalStyle.appBarTitle),
        backgroundColor: GlobalStyle.appBarBackgroundColor,
        bottom: _reusableWidget.bottomAppBar(),
      ),
      body: ListView(
        children: [
          (!kIsWeb)
          ? SizedBox(
            height: MediaQuery.of(context).size.width/2,
            child: Stack(
              children: [
                _buildGoogleMap(),
                (_mapLoading)?Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: Colors.grey[100],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ):const SizedBox.shrink()
              ],
            ),
          ):const SizedBox.shrink(),
          Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Place Name'),
                const SizedBox(height: 4),
                const TextField(
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: softGrey, width: 0),
                        borderRadius: BorderRadius.all(
                          Radius.circular(8),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: softGrey, width: 0),
                        borderRadius: BorderRadius.all(
                          Radius.circular(8),
                        ),
                      ),
                      hintText: 'e.g. Home Address, Office Address',
                      hintStyle: TextStyle(
                        color: softGrey,
                        fontSize: 14
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12.0),
                    ),
                ),
                const SizedBox(height: 16),
                const Text('Address'),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 0,
                      color: softGrey
                    ),
                    borderRadius: const BorderRadius.all(
                        Radius.circular(8.0)
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                          margin: const EdgeInsets.all(16),
                          child: const Icon(Icons.place, color: assentColor, size: 20)
                      ),
                      const Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hilltop Playground', style: TextStyle(
                                color: Colors.black, fontSize: 14
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                            SizedBox(height: 2),
                            Text('Hopkinson Avenue &, Pacific St, Brooklyn, NY 11233, United States', style: TextStyle(
                                color: softGrey, fontSize: 13
                            ), maxLines: 1, overflow: TextOverflow.ellipsis)
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Address Detail'),
                const SizedBox(height: 4),
                const TextField(
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: softGrey, width: 0),
                      borderRadius: BorderRadius.all(
                        Radius.circular(8),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: softGrey, width: 0),
                      borderRadius: BorderRadius.all(
                        Radius.circular(8),
                      ),
                    ),
                    hintText: 'e.g. Floor, unit number',
                    hintStyle: TextStyle(
                        color: softGrey,
                        fontSize: 14
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12.0),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Note to driver'),
                const SizedBox(height: 4),
                const TextField(
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: softGrey, width: 0),
                      borderRadius: BorderRadius.all(
                        Radius.circular(8),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: softGrey, width: 0),
                      borderRadius: BorderRadius.all(
                        Radius.circular(8),
                      ),
                    ),
                    hintText: 'e.g. Meet me at the car park',
                    hintStyle: TextStyle(
                        color: softGrey,
                        fontSize: 14
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12.0),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
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
                        Fluttertoast.showToast(msg: 'Save Address Success', toastLength: Toast.LENGTH_SHORT);
                        Navigator.pop(context);
                        if(!widget.fromList){
                          Navigator.pop(context);
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.0),
                        child: Text(
                          'Save Address',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      )
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // build google maps to used inside widget
  Widget _buildGoogleMap() {
    return GoogleMap(
      mapType: MapType.normal,
      trafficEnabled: false,
      compassEnabled: false,
      rotateGesturesEnabled: false,
      scrollGesturesEnabled: false,
      tiltGesturesEnabled: false,
      zoomControlsEnabled: false,
      zoomGesturesEnabled: false,
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
      mapToolbarEnabled: false,
      markers: Set.of((_marker != null) ? [_marker!] : []),
      initialCameraPosition: CameraPosition(
        target: _initialPosition,
        zoom: 14,
      ),
      onMapCreated: (GoogleMapController controller) {
        _controller = controller;
        _timerDummy = Timer(const Duration(milliseconds: 300), () {
          setState(() {
            _mapLoading = false;
            _addMarker(40.675416, -73.914554);
          });
        });
      },
    );
  }
}
