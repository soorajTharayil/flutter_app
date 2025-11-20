import 'package:devkitflutter/config/constant.dart';
import 'package:devkitflutter/config/global_style.dart';
import 'package:devkitflutter/ui/reusable/reusable_widget.dart';
import 'package:devkitflutter/ui/reusable/cache_image_network.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
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
        appBar: AppBar(
          iconTheme: const IconThemeData(
            color: GlobalStyle.appBarIconThemeColor,
          ),
          systemOverlayStyle: GlobalStyle.appBarSystemOverlayStyle,
          centerTitle: true,
          title: const Text('User Profile', style: GlobalStyle.appBarTitle),
          backgroundColor: GlobalStyle.appBarBackgroundColor,
          bottom: _reusableWidget.bottomAppBar(),
        ),
        body: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _createProfilePicture(),
                const SizedBox(height: 40),
                const Text('Name', style: GlobalStyle.userProfileTitle),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('Robert Steven', style: GlobalStyle.userProfileValue),
                    ),
                    GestureDetector(
                      onTap: (){
                        Fluttertoast.showToast(msg: 'Click edit name', toastLength: Toast.LENGTH_SHORT);
                      },
                      child: const Text('Edit', style: GlobalStyle.userProfileEdit),
                    )
                  ],
                ),
                const SizedBox(
                  height: 24,
                ),
                const Text('Email', style: GlobalStyle.userProfileTitle),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('robert.steven@ijtechnology.net', style: GlobalStyle.userProfileValue),
                    ),
                    GestureDetector(
                      onTap: (){
                        Fluttertoast.showToast(msg: 'Click edit email', toastLength: Toast.LENGTH_SHORT);
                      },
                      child: const Text('Edit', style: GlobalStyle.userProfileEdit),
                    )
                  ],
                ),
                const SizedBox(
                  height: 24,
                ),
                const Text('Phone Number', style: GlobalStyle.userProfileTitle),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('0811888999', style: GlobalStyle.userProfileValue),
                    ),
                    GestureDetector(
                      onTap: (){
                        Fluttertoast.showToast(msg: 'Click edit phone number', toastLength: Toast.LENGTH_SHORT);
                      },
                      child: const Text('Edit', style: GlobalStyle.userProfileEdit),
                    )
                  ],
                ),
              ],
            ),
          ),
        )
    );
  }

  Widget _createProfilePicture(){
    final double profilePictureSize = MediaQuery.of(context).size.width/3;
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        width: profilePictureSize,
        height: profilePictureSize,
        child: GestureDetector(
          onTap: () {
            _showPopupUpdatePicture();
          },
          child: Stack(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: (profilePictureSize),
                child: Hero(
                  tag: 'profilePicture',
                  child: ClipOval(
                      child: buildCacheNetworkImage(width: profilePictureSize, height: profilePictureSize, url: '$globalUrl/user/avatar.png')
                  ),
                ),
              ),
              // create edit icon in the picture
              Container(
                width: 30,
                height: 30,
                margin: EdgeInsets.only(top: 0, left: MediaQuery.of(context).size.width/4),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 1,
                  child: const Icon(Icons.edit, size: 12, color: black55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPopupUpdatePicture() {
    // set up the buttons
    Widget cancelButton = TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Text('No', style: TextStyle(color: softBlue))
    );
    Widget continueButton = TextButton(
        onPressed: () {
          Navigator.pop(context);
          Fluttertoast.showToast(msg: 'Click edit profile picture', toastLength: Toast.LENGTH_SHORT);
        },
        child: const Text('Yes', style: TextStyle(color: softBlue))
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      title: const Text('Edit Profile Picture', style: TextStyle(fontSize: 18),),
      content: const Text('Do you want to edit profile picture ?', style: TextStyle(fontSize: 13, color: black77)),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
