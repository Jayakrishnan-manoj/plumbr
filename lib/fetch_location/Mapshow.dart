import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:plumbr/general/Payment.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:ui' as ui;
import 'dart:typed_data';

final _auth = FirebaseAuth.instance;
final fire = FirebaseFirestore.instance;
List<String> list = new List<String>();
double latitude;
double longitude;
PolylinePoints polylinePoints = PolylinePoints();
Map<PolylineId, Polyline> polylines = {};
List<LatLng> polylineCoordinates = [];
String job;

class Mapshow extends StatefulWidget {
  String joli;
  Mapshow({String joli}) {
    job = joli;
  }
  @override
  _MapshowState createState() => _MapshowState();
}

class _MapshowState extends State<Mapshow> {
  Set<Marker> _markers = {};

  Future getDocs() async {
    final Uint8List customMarker= await getBytesFromAsset(
        path:"images/4.png", //paste the custom image path
        width: 150); // size of custom image as marker
    int x = 2;
    await FirebaseFirestore.instance
        .collection('employee')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        if (doc["work"].toString() == job) {
          x++;
          setState(() {
            _markers.add(
              Marker(icon: BitmapDescriptor.fromBytes(customMarker),
                  markerId: MarkerId('id-$x'),
                  position: LatLng(doc["latittude"] + 2, doc["longitude"] + 2),
                  infoWindow: InfoWindow(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return Payment();
                        }));
                      },
                      title: doc["email"],
                      snippet: doc["phone"])),
            );
          });
        }
      });
    });
    print(list);
  }

  Future<Uint8List> getBytesFromAsset({String path,int width})async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: width
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
        format: ui.ImageByteFormat.png))
        .buffer.asUint8List();
  }
  


  @override
  void initState() {
    getDocs();
    getcurrentlocation();
    
    addPolyLine();
    makeLines();

    super.initState();
  }

  Future<void> getcurrentlocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    try {


      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      latitude = position.latitude;
      longitude = position.longitude;
      print(position);
      print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId('id-2'),
            position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                          return Payment();
                        }));
                  },
                  title: "Your Location",
                  )),


        );
      });
    } catch (e) {
      print(e);
    }

  }

  addPolyLine() {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id, color: Colors.red, points: polylineCoordinates);
    polylines[id] = polyline;
    setState(() {});
  }

  void makeLines() async {
    await polylinePoints
        .getRouteBetweenCoordinates(
      'AIzaSyC0mDpWjR6y6mIwWIpRV6O7uAeQr_gaFSI',
      PointLatLng(latitude, longitude), //Starting LATLANG
      PointLatLng(20.8505, 76.2711), //End LATLANG
      travelMode: TravelMode.driving,
    )
        .then((value) {
      value.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }).then((value) {
      addPolyLine();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: GoogleMap(
      polylines: Set<Polyline>.of(polylines.values),
      onMapCreated: null,
      markers: _markers,
      initialCameraPosition:
          CameraPosition(target: LatLng(10.8505, 76.2711), zoom: 5),
    ));
  }
}
