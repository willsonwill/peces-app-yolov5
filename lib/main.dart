import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:pytorch_lite/pigeon.dart';
import 'package:pytorch_lite/pytorch_lite.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ModelObjectDetection _objectModel;
  late ModelObjectDetection _clasficadorModel;
  String? _imagePrediction;
  File? _image;
  ImagePicker _picker = ImagePicker();
  bool objectDetection = false;
  List<ResultObjectDetection?> objDetect = [];
  List<ResultObjectDetection?> objClasificador = [];
  int? clase;
  @override
  void initState() {
    super.initState();
    loadModel();
  }

  //Cargar el modelo
  Future loadModel() async {
    String pathObjectDetectionModel = "assets/models/labels_objectDetection_Peces_yolov5.torchscript";
    String pathObjectClasificadorModel = "assets/models/labels_objectClasificacion_Peces_yolov5.torchscript";
    try {
      _objectModel = await PytorchLite.loadObjectDetectionModel(
          pathObjectDetectionModel, 2, 640, 640,
          labelPath: "assets/labels/labels_objectDetection_Peces_yolov5.txt");
      _clasficadorModel = await PytorchLite.loadObjectDetectionModel(
          pathObjectClasificadorModel, 3, 640, 640,
          labelPath: "assets/labels/labels_objectClasificacion_Peces_yolov5.txt");
    } catch (e) {
      if (e is PlatformException) {
        print("solo compatible con Android, el error es $e");
      } else {
        print("Error es $e");
      }
    }
  }

  Future runObjectDetectionClasificadorCamara() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    setState(() {
      objectDetection=true;
    });
    objDetect = await _objectModel.getImagePrediction(
        await File(image!.path).readAsBytes(),
        minimumScore: 0.1,
        IOUThershold: 0.3);
    objClasificador = await _clasficadorModel
        .getImagePredictionList(await File(image!.path).readAsBytes());
    objClasificador.forEach((element) {
      clase=element?.classIndex;
      if (clase==0) {
        _imagePrediction='PACU';
      }else if(clase==1){
        _imagePrediction='SABALO';
      }else if(clase==2){
        _imagePrediction='SURUBI';
      }else{
        _imagePrediction='';
      }
    });
    setState(() {
      _image = File(image.path);
      objectDetection=false;
    });
  }

  Future runObjectDetectionClasificadorGaleria() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      objectDetection=true;
    });
    objDetect = await _objectModel.getImagePrediction(
        await File(image!.path).readAsBytes(),
        minimumScore: 0.1,
        IOUThershold: 0.3);
    objClasificador = await _clasficadorModel
        .getImagePredictionList(await File(image!.path).readAsBytes());
    objClasificador.forEach((element) {
      clase=element?.classIndex;
      if (clase==0) {
        _imagePrediction='PACU';
      }else if(clase==1){
        _imagePrediction='SABALO';
      }else if(clase==2){
        _imagePrediction='SURUBI';
      }else{
         _imagePrediction='';
      }
    });
    setState(() {
      objectDetection=false;
      _image = File(image.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Detector de Peces'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: objectDetection
                  ?
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(width: 24),
                        Text('CARGANDO...')
                      ],
                    )
                  : 
                    objDetect.isNotEmpty
                    ? _image == null
                        ? const Text('NINGUNA IMAGEN SELECCIONADA.')
                        : _objectModel.renderBoxesOnImage(_image!, objDetect)
                    : _image == null
                        ? const Text('NINGUNA IMAGEN SELECCIONADA.')
                        : Image.file(_image!),
                    ),
            ),
            Card(
              child: Column(
                children: <Widget> [
                  Center(
                    child: Visibility(
                      visible: !objectDetection,
                      child: 
                      ListTile(
                        title: objClasificador.isNotEmpty 
                        ? 
                          Text("$_imagePrediction",textAlign: TextAlign.center)
                        :
                          const Text('SIN RESULTADOS.',textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        subtitle: objClasificador.isNotEmpty 
                        ?
                          objDetect.isNotEmpty 
                          ? 
                            const Text(" NO ACTO PARA EL CONSUMO. ",textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color.fromARGB(255, 230, 120, 120),
                              ),
                            )
                          :
                            const Text('ACTO PARA EL CONSUMO',textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.green
                              ),
                            )
                        :
                          const Text("-",textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          )
                      )
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _crearBottonNavigationBar(),
      ),
    );
  }

  Widget _crearBottonNavigationBar(){
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index){
        if (index==0) {
          runObjectDetectionClasificadorGaleria();
        }else{
          runObjectDetectionClasificadorCamara();
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.photo_camera_back),
          label:'Galeria'
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.photo_camera),
          label: 'Camara'
        ),
      ],
    );
  }
}