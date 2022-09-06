import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

import 'loginPage.dart';

class EmailSender extends StatefulWidget {
  const EmailSender({Key? key}) : super(key: key);

  @override
  State<EmailSender> createState() => _EmailSenderState();
}

class _EmailSenderState extends State<EmailSender> {
  SmsQuery query = SmsQuery();
  late List<SmsMessage> messages = [];
  late List<SmsMessage> newMessages = [];
  int? timeStamp;
  String? toEmail;
  String messageBody = "";
  bool isSent = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadData();
  }

  void loadData() async {
    final prefs = await SharedPreferences.getInstance();
    timeStamp = prefs.getInt('time');
    toEmail = prefs.getString('email');
    messages = await query.querySms(
      kinds: [SmsQueryKind.inbox],
    );
    messageBody = "";
    if (timeStamp == null) {
      /// Check all sms first time
      newMessages = [];
      addEmailDialog(context);
      for (int i = 0; i < messages.length; i++) {
        print("Check all sms");
        newMessages.add(messages[i]);
        messageBody = "$messageBody\n----------------------------------------"
            "\n${messages[i].sender}--\n${messages[i].body}\n${messages[i].date!.toString()}";
      }
    } else {
      /// Check new sms
      newMessages = [];
      for (int i = 0; i < messages.length; i++) {
        if (messages[i]
                .date!
                .compareTo(DateTime.fromMillisecondsSinceEpoch(timeStamp!)) ==
            1) {
          print("New sms found");
          newMessages.add(messages[i]);
          messageBody = "$messageBody\n----------------------------------------"
              "\n${messages[i].sender}\n${messages[i].body}\n${messages[i].date!.toString()}";
        }
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: Drawer(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ListTile(
              title: Text('Add Email'),
              leading: Icon(Icons.email),
              onTap: () async {
                await addEmailDialog(context);
                setState(() {});
                Navigator.of(context).pop();
              },
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
        body: SizedBox(
            height: Size.infinite.height,
            width: Size.infinite.width,
            child: ListView.builder(
                shrinkWrap: true,
                //  physics: NeverScrollableScrollPhysics(),
                itemCount: newMessages.length,
                itemBuilder: (context, index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(newMessages[index].sender.toString()),
                        subtitle: Text(newMessages[index].body.toString()),
                        trailing: Icon(
                          Icons.cloud_done,
                          color: isSent ? Colors.blue : Colors.blueGrey,
                        ),
                        // tileColor: Colors.greenAccent,
                      ),
                      Divider(
                        thickness: 2,
                      )
                    ],
                  );
                })));
  }

  Future<void> sendNewSms() async {
    final prefs = await SharedPreferences.getInstance();
    if (messageBody.isNotEmpty) {
      /// Send sms here
      sendEmail('SMS from App', toEmail!, 'New SMS', messageBody)
          .then((value) async {
        showSnackBar(context, "Email sent SuccessFully");
        print("sms sent!!!!!!!!!!!!!");
        timeStamp = messages[0].date!.millisecondsSinceEpoch;
        await prefs.setInt('time', timeStamp!);
        isSent = true;
        setState(() {});
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
    print('Authenticaltion mail $email');
    print('Authenticaltion token $token');

    final smtpServer = gmailSaslXoauth2(email!, token!);
    final message = Message()
      ..from = Address(email!, title)
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

  Future<void> addEmailDialog(BuildContext context) async {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Receiver Email Address'),
          actions: [
            MaterialButton(
              elevation: 0,
              minWidth: MediaQuery.of(context).size.width / 4,
              height: 40,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              onPressed: () async {
                toEmail = controller.text;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('email', controller.text);
                setState(() {});
                Navigator.of(context).pop();
                showSnackBar(context, "Receiver Email added");
              },
              color: Colors.blue,
              child: Text("Save"),
              textColor: Colors.white,
            ),
            MaterialButton(
              elevation: 0,
              minWidth: MediaQuery.of(context).size.width / 4,
              height: 40,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              color: Colors.blue,
              child: Text("Cancel"),
              textColor: Colors.white,
            ),
          ],
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height - 600,
            child: TextFormField(
              decoration: const InputDecoration(
                  hintText: 'ex: exaple@gmail.com',
                  labelText: "Enter Email Address",
                  border: OutlineInputBorder()),
              controller: controller,
            ),
          ),
        );
      },
    );
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        message,
      ),
      duration: const Duration(seconds: 6),
      backgroundColor: Colors.blue,
      action: SnackBarAction(
        label: 'Ok',
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    ));
  }
}
