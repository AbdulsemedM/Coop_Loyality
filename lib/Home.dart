import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loyalty_app/tabs/Home3.dart';
import 'package:loyalty_app/tabs/MyProfile.dart';
import 'package:loyalty_app/tabs/Redeem.dart';
import 'package:loyalty_app/utils/simple_preference.dart';

import 'colors.dart';
import 'login_page.dart';

// ignore: must_be_immutable
class Home extends StatefulWidget {
  final List<UserChallengeDTO> challengeUserChallengeDTOs;
  final List<LevelDetail> challengeLevelDetails;
  final ChallengeData challengeData;

  const Home({
    Key? key,
    required this.challengeUserChallengeDTOs,
    required this.challengeLevelDetails,
    required this.challengeData,
  }) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _pageController = PageController(initialPage: 0);
  int _tabIndex = 1;
  int get tabIndex => _tabIndex;
  set tabIndex(int v) {
    _tabIndex = v;
    setState(() {});
  }

  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: _tabIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// widget list

  @override
  Widget build(BuildContext context) {
    final List<Widget> bottomBarPages = [
      const Redeem(),
      Home3(
        challengeUserChallengeDTOs: widget.challengeUserChallengeDTOs,
        challengeLevelDetails: widget.challengeLevelDetails,
        challengeData: widget.challengeData,
      ),

      const MyProfile(),
      // const Michu(),
    ];
    return WillPopScope(
      onWillPop: () => _onBackButtonPressed(context),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors_selector.tertiaryColor,
          body: PageView(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
                bottomBarPages.length, (index) => bottomBarPages[index]),
          ),
          extendBody: true,
          bottomNavigationBar: CircleNavBar(
            activeIcons: [
              Icon(Icons.redeem, color: Colors_selector.primaryColor),
              Icon(Icons.home, color: Colors_selector.primaryColor),
              Icon(Icons.person, color: Colors_selector.primaryColor),
            ],
            inactiveIcons: [
              Text(
                "Redeem",
                style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text("Home",
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              Text("Profile",
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ],
            color: Colors.white,
            height: 50,
            circleWidth: 50,
            activeIndex: tabIndex,
            onTap: (index) {
              tabIndex = index;
              pageController.jumpToPage(tabIndex);
            },
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 5),
            cornerRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
            shadowColor: Colors.blue.shade300,
            elevation: 10,
          ),
        ),
      ),
    );
  }

  Future<bool> _onBackButtonPressed(BuildContext context) async {
    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors_selector.pair2,
            title: Text("Confirm Exit".tr),
            content: Text("Do you want to Logout?".tr),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text("No".tr)),
              TextButton(
                  onPressed: () async {
                    SimplePreferences preferences = SimplePreferences();
                    await preferences.setRefresh("null");
                    List<String> user = [];
                    SimplePreferences preferences1 = SimplePreferences();
                    await preferences1.setUser(user);
                    // ignore: use_build_context_synchronously
                    Navigator.pushReplacement<void, void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => const Login_page(),
                      ),
                    );
                  },
                  child: Text(
                    "Yes".tr,
                    style: TextStyle(color: Colors.red),
                  ))
            ],
          );
        });
  }
}
