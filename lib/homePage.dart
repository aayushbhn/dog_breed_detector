import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

import 'main.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  bool isWorking = false;
  String result= '';
  CameraController? cameraController;
  CameraImage? imageCamera;

  initCamera()
  {
    cameraController = CameraController(cameras![0],ResolutionPreset.medium);
    cameraController!.initialize().then((value)
    {
      if(!mounted){
        return;
      }

      setState(() {
        cameraController!.startImageStream((imageFromStream) =>
        {
          if(!isWorking)
            {
              isWorking = true,
              imageCamera = imageFromStream,
              runModelOnStreamFrames(),
            }
        });
      });

    });
  }

  // create load model

  loadModel()async{
    await Tflite.loadModel(
        model: "assets/model.tflite",
      labels: "assets/labels.txt",


    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadModel();
  }


  runModelOnStreamFrames()async{
    if(imageCamera != null){
      var recognitions = await Tflite.runModelOnFrame(
          bytesList: imageCamera!.planes.map((plane)
          {
            return plane.bytes;
          }
          ).toList(),

        imageHeight: imageCamera!.height,
        imageWidth: imageCamera!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );

      result = '';

      recognitions!.forEach((response)
      {
        result += response["label"] + " " + (response["confidence"] as double).toStringAsFixed(2)+ "\n\n";
      });
      setState(() {
        result;
      });

      isWorking = false;
    }
  }

  @override
  void dispose() async{
    // TODO: implement dispose
    super.dispose();

    await Tflite.close();
    cameraController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text("Dog Breed Dectector"),),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/back.jpg"),
              fit: BoxFit.fill,


            ),
          ),

          child: Column(
            children: [
              Stack(
                children: [


                  Center(
                    child: TextButton(
                      onPressed: ()
                      {
                        initCamera();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 35.0),
                        height: 270.0,
                        width: 360.0,
                        child: imageCamera == null
                          ?
                            Container(
                              height: 270.0,
                              width: 360.0,
                              child: Icon(Icons.photo_camera, color: Colors.red, size: 40.0,),
                            )
                            :
                            AspectRatio(
                                aspectRatio: cameraController!.value.aspectRatio,
                                child: CameraPreview(cameraController!),
                            ),



                      ),
                    ),
                  )
                ],
              ),

              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 55.0),
                  child: SingleChildScrollView(
                    child: Text(
                      result,
                      style: const TextStyle(
                        backgroundColor: Colors.white70,
                        fontSize: 30.0,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            ],
          ),
        ) ,
      ),



    );
  }
}
