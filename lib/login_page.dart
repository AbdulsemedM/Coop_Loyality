// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:loyalty_app/Forgot_pw.dart';
import 'package:loyalty_app/Home.dart';
import 'package:loyalty_app/Signup.dart';
import 'package:loyalty_app/colors.dart';
import 'package:get/get.dart';

import 'package:loyalty_app/utils/simple_preference.dart';
import 'package:http/http.dart' as http;

// ignore: camel_case_types
class Login_page extends StatefulWidget {
  const Login_page({Key? key}) : super(key: key);

  @override
  _Login_pageState createState() => _Login_pageState();
}

class ChallengeData {
  final String totalPoints;
  final String equivalentETB;
  final String levelName;
  final String levelColor;

  ChallengeData({
    required this.totalPoints,
    required this.equivalentETB,
    required this.levelName,
    required this.levelColor,
  });
}

class LevelDetail {
  late String levelName;
  late String points;
  late String status;

  LevelDetail({
    required this.levelName,
    required this.points,
    required this.status,
  });
}

class UserChallengeDTO {
  final String challengeLogo;
  final String challengeName;
  final String pointsEarned;
  final String awardPoints;
  final String affliateLink;

  UserChallengeDTO({
    required this.challengeLogo,
    required this.challengeName,
    required this.pointsEarned,
    required this.awardPoints,
    required this.affliateLink,
  });
}

// ignore: camel_case_types
class _Login_pageState extends State<Login_page> {
  bool _passwordVisible = false;
  DateTime timeBackPressed = DateTime.now();
  TextEditingController pnumber = TextEditingController();
  TextEditingController password = TextEditingController();
  String? isOn = "false";
  List<LevelDetail> challengeLevelDetails = [];
  List<UserChallengeDTO> challengeUserChallengeDTOs = [];
  late ChallengeData challengeData;

  @override
  void initState() {
    super.initState();
    // _checkDarkMode();
    // _setColors();
    // WidgetsBinding.instance.addObserver(this);
  }

  final List locale = [
    {'name': 'English', 'locale': Locale('en', 'US')},
    {'name': 'Afaan Oromoo', 'locale': Locale('or', 'ET')},
    {'name': 'አማርኛ', 'locale': Locale('am', 'ET')},
    {'name': 'Somali', 'locale': Locale('en', 'US')},
  ];

  buildLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (builder) {
        return AlertDialog(
          title: Text('Choose Language'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    child: Text(locale[index]['name']),
                    onTap: () async {
                      // Get the selected locale and call the setLanguage method
                      String selectedLocale = locale[index]['name'];
                      // print(selectedLocale);
                      SimplePreferences preferences = SimplePreferences();
                      await preferences.setLanguage(selectedLocale);
                      updateLanguage(locale[index]['locale']);
                      setState(() {});
                    },
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return Divider(
                  color: Colors_selector.primmary1,
                );
              },
              itemCount: locale.length,
            ),
          ),
        );
      },
    );
  }

  updateLanguage(Locale locale) async {
    // print(locale);
    Get.back();
    Get.updateLocale(locale);
  }

  bool loading = false;
  login() async {
    // Navigator.pushReplacement(
    //     context, MaterialPageRoute(builder: (context) => Home()));
    String pn = pnumber.text;
    print(pn);

    if (pnumber.text.length < 9 || pnumber.text == "") {
      const message = 'Invalid phone number format';
      Future.delayed(const Duration(milliseconds: 100), () {
        Fluttertoast.showToast(msg: message, fontSize: 18);
      });
    } else if (password.text == "") {
      const message = 'Invalid password';
      Future.delayed(const Duration(milliseconds: 100), () {
        Fluttertoast.showToast(msg: message, fontSize: 18);
      });
    } else {
      setState(() {
        loading = true;
      });
      final body = <String, String>{
        "username": pnumber.text.toString(),
        "password": password.text.toString(),
      };
      // print(body);
      try {
        final response = await http
            .post(
              Uri.http('10.1.177.123:9000', '/login'),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(body),
            )
            .timeout(Duration(seconds: 15));

        // print(response.body);
        // print("here" + "${response.statusCode}");

        if (response.statusCode == 200) {
          // ignore: prefer_interpolation_to_compose_strings
          final json = "[" + response.body + "]";
          // List list = (jsonDecode(json) as List<dynamic>);
          List<Map<String, dynamic>> dataList =
              (jsonDecode(json) as List).cast<Map<String, dynamic>>();
          if (dataList.isNotEmpty) {
            Map<String, dynamic> data = dataList.first;
            String accessToken = data['access_token'];
            Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
            dynamic subVal = decodedToken['sub']; // Access 'sub' field
            String sub = subVal.toString();
            List<dynamic> roles = decodedToken['roles']; // Access 'roles' field
            String firstRole = roles[0];
            dynamic expVal = decodedToken['exp']; // Access 'exp' field
            String exp = expVal.toString();
            List<String> newUser = [sub, firstRole, exp, accessToken];
            SimplePreferences preferences = SimplePreferences();
            await preferences.setUser(newUser);
          } else {
            print('No data found in the response.');
          }

          try {
            final challenge = await http.get(
              Uri.http('10.1.177.123:9000',
                  'api/userChallenges/getByUsername/${pnumber.text.toString()}'),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
            );
            // print(challenge.body);
            var Data = jsonDecode(challenge.body);

            for (var levelDetail in Data['levelDetails']) {
              challengeLevelDetails.add(LevelDetail(
                levelName: levelDetail['levelName'],
                points: levelDetail['points'],
                status: levelDetail['status'],
              ));
            }

            // Iterate through userChallengeDTOs in the challenge
            for (var userChallengeDTO in Data['userChallengeDTOs']) {
              challengeUserChallengeDTOs.add(UserChallengeDTO(
                challengeLogo: userChallengeDTO['challengeLogo'],
                challengeName: userChallengeDTO['challengeName'],
                pointsEarned: userChallengeDTO['pointsEarned'],
                awardPoints: userChallengeDTO['awardPoints'],
                affliateLink: userChallengeDTO['affliateLink'],
              ));
            }
            challengeData = ChallengeData(
              totalPoints: Data['totalPoints'],
              equivalentETB: Data['equivalentETB'],
              levelName: Data['levelName'],
              levelColor: Data['levelColor'],
            );

            List<String> data = [
              challengeData.totalPoints,
              challengeData.equivalentETB,
              challengeData.levelName,
              challengeData.levelColor
            ];
            print(data);
            print("heeeee");
            SimplePreferences preferences = SimplePreferences();
            await preferences.setData(data);
            // for (int i = 0; i < challengeLevelDetails.length; i++) {
            //   print("hereeee we go !!!${challengeLevelDetails[i].levelName}");
            // }
          } catch (e) {}

          setState(() {
            loading = false;
          });
          SimplePreferences preferences = SimplePreferences();
          await preferences.setRefresh("null");

          // ignore: use_build_context_synchronously
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => Home(
                      challengeUserChallengeDTOs: challengeUserChallengeDTOs,
                      challengeLevelDetails: challengeLevelDetails,
                      challengeData: challengeData)));
          setState(() {
            loading = false;
          });
        } else if (response.statusCode == 401) {
          setState(() {
            loading = false;
          });
          const message = 'Invalid username or password!';
          Fluttertoast.showToast(msg: message, fontSize: 18);
        }
      } catch (e) {
        const message =
            "Something went wrong, please Check your network connection";

        // print(message);
        Fluttertoast.showToast(msg: message, fontSize: 18);
      } finally {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: () async {
        final difference = DateTime.now().difference(timeBackPressed);
        final isExitWarning = difference >= Duration(seconds: 2);
        timeBackPressed = DateTime.now();
        if (isExitWarning) {
          const message = 'press again to exit';
          Fluttertoast.showToast(msg: message, fontSize: 18);

          return false;
        } else {
          Fluttertoast.cancel();
          return exit(0);
        }
      },
      child: SafeArea(
        child: Scaffold(
          // backgroundColor: Colors_selector.pair1,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(children: [
                Container(
                  height: screenHeight,
                  width: screenWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors_selector.tertiaryColor,
                      Colors_selector.tertiaryColor
                    ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            buildLanguageDialog(context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Text(
                                  "Languages".tr,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Center(
                          child: Image.asset(
                            'assets/images/Cap.png',
                            height: screenHeight * 0.3,
                            width: screenWidth * 0.6,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          "Login".tr,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors_selector
                                .primmary1, // You can use your color here
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.1),
                          child: SizedBox(
                            height: 55, // Adjust the height as needed
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: TextField(
                                  controller: pnumber,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.phone_android,
                                    ),
                                    border: InputBorder.none,
                                    labelText: "Phone Number".tr,
                                    labelStyle: GoogleFonts.playfairDisplay(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.1),
                          child: SizedBox(
                            height: 55, // Adjust the height as needed
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: TextField(
                                  controller: password,
                                  obscureText: !_passwordVisible,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.lock,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _passwordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _passwordVisible = !_passwordVisible;
                                        });
                                      },
                                    ),
                                    border: InputBorder.none,
                                    labelText: "Password".tr,
                                    labelStyle: GoogleFonts.playfairDisplay(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),
                        Padding(
                          padding: EdgeInsets.only(left: screenWidth * 0.1),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Forgot_pw(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Forgot".tr,
                                  style: GoogleFonts.playfairDisplay(
                                    color: Colors_selector
                                        .secondaryColor, // You can use your color here
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        loading
                            ? CircularProgressIndicator(
                                color: Colors_selector.primaryColor,
                              )
                            : Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.3,
                                  vertical: screenHeight * 0.02,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    login();
                                  },
                                  child: Container(
                                    padding:
                                        EdgeInsets.all(screenHeight * 0.01),
                                    decoration: BoxDecoration(
                                      color: Colors_selector
                                          .primmary1, // You can use your color here
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Login".tr,
                                        style: GoogleFonts.playfairDisplay(
                                          color: Colors
                                              .white, // You can use your color here
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        // _isLoading
                        //     ? CircularProgressIndicator(
                        //         color: Colors.white, // You can use your color here
                        //       )
                        //     : SizedBox(),
                        SizedBox(height: screenHeight * 0.02),
                        SizedBox(height: screenHeight * 0.08),

                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.1),
                          child: Row(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    child: Text(
                                      "Don't have an account? ".tr,
                                      style: GoogleFonts.playfairDisplay(
                                        color: Colors
                                            .black, // You can use your color here
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Signup(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        "Signup here".tr,
                                        style: GoogleFonts.playfairDisplay(
                                          color: Colors_selector
                                              .primmary1, // You can use your color here
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // SizedBox(height: screenHeight * 0.08),
                        // Text(
                        //   "copyright 1894-2023 © Coop Bank of Oromia",
                        //   style: TextStyle(fontSize: 15),
                        // ),
                        // SizedBox(height: screenHeight * 0.01),
                        // Text("All Rights Reserved"),
                      ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
