import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'auth_service.dart';
import 'dart:io';

Future<void> deleteImages(List<String> deleteImages) async {
  //Delete everu filein List from Firebase Storage
  deleteImages.forEach((url) async {
    //Get filename (with extension) from download url
    String fileName = url
        .replaceAll("/o/", "*")
        .replaceAll("?", "*")
        .split("*")[1]
        .split("%2F")[1];
    Reference storageReferance = FirebaseStorage.instance.ref();
    storageReferance
        .child(AuthService.getUserEmail())
        .child(fileName)
        .delete()
        .then((_) => print('Successfully deleted $fileName storage item'))
        .catchError((e) => print("Delete nai hua because: " + e.toString()));
  });
}

Future<DocumentReference> createEntry(String title, String content, String mood,
    List<String> images, DateTime dateCreated) async {
  String email = AuthService.getUserEmail();
  DocumentReference userDoc =
      FirebaseFirestore.instance.collection('users').doc(email);
  DocumentReference randomDoc = userDoc.collection('entries').doc();
  String docId = randomDoc.id;

  List<String> imagesURLs = [];

  if (images.length > 0) {
    String id = email;

    await Future.wait(
        images.map((String _image) async {
          String imageRef = id + '/' + _image.split('/').last;
          Reference ref = FirebaseStorage.instance.ref(imageRef);
          UploadTask uploadTask = ref.putFile(File(_image));

          TaskSnapshot _ = await uploadTask.whenComplete(() async {
            String downloadUrl = await ref.getDownloadURL();
            imagesURLs.add(downloadUrl);
          });
        }),
        eagerError: true,
        cleanUp: (_) {
          print('eager cleaned up');
        });
  } else {
    imagesURLs = [];
  }

  DateTime now = new DateTime.now();
  final _ = await userDoc.collection('entries').doc(docId).set({
    'title': title,
    'content': content,
    'dateCreated': dateCreated.toString(),
    'dateLastModified': now.toString(),
    'mood': mood,
    'images': imagesURLs,
    'docId': docId
  });
  DocumentReference query = userDoc.collection('entries').doc(docId);
  return query;
}

Stream<QuerySnapshot> getEntries() {
  String email = AuthService.getUserEmail();
  DocumentReference userDoc =
      FirebaseFirestore.instance.collection('users').doc(email);
  Stream<QuerySnapshot> query = userDoc
      .collection('entries')
      .orderBy('dateCreated', descending: true)
      .snapshots();
  return query;
}

Future<DocumentSnapshot> getEntry(String entryId) async {
  String email = AuthService.getUserEmail();
  DocumentReference userDoc =
      FirebaseFirestore.instance.collection('users').doc(email);
  DocumentSnapshot doc = await userDoc.collection('entries').doc(entryId).get();
  return doc;
}

Future<void> editEntry(
    String entryId,
    String title,
    String content,
    String mood,
    List<String> selectedImages,
    List<String> previousImagesURLs,
    List<String> deletedImages,
    DateTime dateCreated) async {
  String email = AuthService.getUserEmail();
  DocumentReference userDoc =
      FirebaseFirestore.instance.collection('users').doc(email);
  List<String> selectedImagesURLs = [];
  if (selectedImages.length > 0) {
    String id = email;

    await Future.wait(
        selectedImages.map((String _image) async {
          String imageRef = id + '/' + _image.split('/').last;
          Reference ref = FirebaseStorage.instance.ref(imageRef);
          UploadTask uploadTask = ref.putFile(File(_image));

          TaskSnapshot _ = await uploadTask.whenComplete(() async {
            String downloadUrl = await ref.getDownloadURL();
            selectedImagesURLs.add(downloadUrl);
          });
        }),
        eagerError: true,
        cleanUp: (_) {
          print('eager cleaned up');
        });
  } else {
    selectedImagesURLs = [];
  }
  List<String> imagesURLs = selectedImagesURLs + previousImagesURLs;

  DateTime now = new DateTime.now();
  print("Editing: dc = ${dateCreated.toString()}");

  Future<void> _ = userDoc.collection('entries').doc(entryId).update({
    'title': title,
    'content': content,
    'dateCreated': dateCreated.toString(),
    'dateLastModified': now.toString(),
    'mood': mood,
    'images': imagesURLs,
  });
  deletedImages.length > 0 ? deleteImages(deletedImages) : null;
}

void deleteEntry(DocumentSnapshot documentSnapshot) async {
  await deleteImages(List<String>.from(documentSnapshot['images']));

  await FirebaseFirestore.instance
      .runTransaction((Transaction myTransaction) async {
    myTransaction.delete(documentSnapshot.reference);
  });
}
