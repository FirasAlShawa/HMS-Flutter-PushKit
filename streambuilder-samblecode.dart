 StreamBuilder<RemoteMessage>(
                stream: Push.onMessageReceivedStream,
                builder: ((context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error occured while listening the data message'
                        ' stream. Error is ${snapshot.error.toString()}');
                  } else {
                    if (snapshot.data != null) {
                      String? data = snapshot.data!.getData;
                      badgeNum = badgeNum + 1;
                      return Text(data != null ? data : "data is null!");
                    }
                    return Text("Snapshot is null!");
                  }
                })),