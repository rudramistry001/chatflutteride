// Based on https://dartpad.dev/?id=d57c6c898dabb8c6fb41018588b8cf73
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

const Color darkBlue = Color.fromARGB(255, 18, 32, 47);

const messageLimit = 30;

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
  } catch (e, st) {
    print(e);
    print(st);
  }

  // The first step to using Firebase is to configure it so that our code can
  // find the Firebase project on the servers. This is not a security risk, as
  // explained here: https://stackoverflow.com/a/37484053
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // We sign the user in anonymously, meaning they get a user ID without having
  // to provide credentials. While this doesn't allow us to identify the user,
  // this would, for example, still allow us to associate data in the database
  // with each user.
  await FirebaseAuth.instance.signInAnonymously();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final DateFormat formatter = DateFormat('MM/dd HH:mm:SS');

  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The user can send a message to Firebase. What they can send is
              // protected by server-side security rules, which in this case
              // only allow chat messages that this regular expression:
              //
              //    ^((?i)hello|\\s|firebase|welcome|to|summit|the|this|
              //    everyone|good|morning|afternoon|firestore|meetup|
              //    devfest|virtual|online)+
              //
              // In a real project you'd probably expand that, for example by
              // only allowing users that you explicitly approve to post
              // messages.
              const SizedBox(height: 32),
              Text(
                'Enter a new message',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'You can type a message into this field and hit the enter key '
                'to add it to the stream. The security rules for the '
                'Firestore database only allow certain words, though! Check '
                'the comments in the code to the left for details.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              FractionallySizedBox(
                widthFactor: 0.5,
                child: TextField(
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter your message and hit Enter'),
                  onSubmitted: (String value) {
                    FirebaseFirestore.instance.collection('chat').add(
                      {
                        'message': value,
                        'timestamp': DateTime.now().millisecondsSinceEpoch
                      },
                    );
                  },
                ),
              ),
              // We use a stream builder to both read the initial data from the
              // database and listen to updates to that data in realtime. The
              // database we use is called Firestore, and we are asking the 10
              // most recent messages.
              const SizedBox(height: 32),
              Text(
                'The latest messages',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chat')
                      .orderBy('timestamp', descending: true)
                      .limit(messageLimit)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('$snapshot.error'));
                    } else if (!snapshot.hasData) {
                      return const Center(
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    var docs = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        return ListTile(
                          leading: DefaultTextStyle.merge(
                            style: const TextStyle(color: Colors.indigo),
                            child: Text(formatter.format(
                                DateTime.fromMillisecondsSinceEpoch(
                                    docs[i]['timestamp']))),
                          ),
                          title: Text('${docs[i]['message']}'),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
