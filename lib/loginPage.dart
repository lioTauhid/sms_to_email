import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:google_sign_in/google_sign_in.dart';

import 'package:sms_forward/send_mail.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Future<User?> signInWithGoogle() async {
    try {
      //SIGNING IN WITH GOOGLE
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!.authentication;

      //CREATING CREDENTIAL FOR FIREBASE
      final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken);

      //SIGNING IN WITH CREDENTIAL & MAKING A USER IN FIREBASE  AND GETTING USER CLASS
      final userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      //CHECKING IS ON
      assert(!user!.isAnonymous);
      assert(await user!.getIdToken() != null);

      final User? currentUser = await _auth.currentUser;
      assert(currentUser!.uid == user!.uid);
      print(user);

      if (user != null) {
        
        Navigator.pushReplacement (
            context, MaterialPageRoute(builder: ((context) => EmailSender(user: user,))));
        // userName = user.displayName;
        // userEmail = user.email;
        // token = user.uid;
        // print('Nameeeeeee $userName');
        // print('Nameeeeeee $token');
        // print('Nameeeeeee $userEmail');
      }

      return user;
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    signInWithGoogle();
    // TODO: implement initState
    super.initState();
  }

  void signOut() async {
    await googleSignIn.signOut();
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(body: Center(child: Text('Loading........',style: TextStyle(fontSize: 17,fontWeight: FontWeight.bold,color: Colors.blue),))),
    );
  }
}

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();
