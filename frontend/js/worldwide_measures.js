//import libraries & modules
import 'ol/ol.css';
import 'ol-popup/src/ol-popup.css';
import { Map, View } from 'ol';
import { ScaleLine, ZoomToExtent, defaults as defaultControls } from 'ol/control';
import VectorSource from 'ol/source/Vector';
import {Circle as CircleStyle, Fill, Icon, Stroke, Style} from 'ol/style';
import { Tile as TileLayer, Vector as VectorLayer } from 'ol/layer';
import BingMaps from 'ol/source/BingMaps';
import Popup from 'ol-popup';
import { Grid, PluginPosition } from "gridjs";
import "gridjs/dist/theme/mermaid.css";
import EsriJSON from 'ol/format/EsriJSON';
import { renderDeclutterItems } from 'ol/render';


//add dark Bing basemap
var bing_bmap = new TileLayer({
    title: 'Bing Dark Basemap',
    type: 'base',
    visible: true,
    source: new BingMaps({
        key: 'ApTJzdkyN1DdFKkRAE6QIDtzihNaf6IWJsT-nQ_2eMoO4PN__0Tzhl2-WgJtXFSp',
        imagerySet: 'CanvasDark',
        maxZoom: 19
    })
});

//ESRI data request
//Extra: Add travel restrictions 
//data retrieved from an ESRI REST Feature Service
var serviceUrl = 'https://services3.arcgis.com/t6lYS2Pmd8iVx1fy/ArcGIS/rest/services/COVID_Travel_Restrictions_V2/FeatureServer/';
var layer = '0';
var esrijsonFormat = new EsriJSON();

var countries_div = document.getElementById("countries_list"); // countries div to add its features as list

var travel_restrictions = new VectorSource({
    loader: function(extent, resolution, projection) { //fetching the data in a continuous manner
        var url = serviceUrl + layer + '/query/?f=json&' + //querying all the data from the service with its respective parameters
            'returnGeometry=true&spatialRel=esriSpatialRelIntersects&geometry=' +
            encodeURIComponent('{"xmin":' + -19745654.2414122 + ',"ymin":' +
                -15806348.0709987 + ',"xmax":' + 19810863.640646 + ',"ymax":' + 14826270.4354729 +
                ',"spatialReference":{"wkid":102100}}') +
            '&geometryType=esriGeometryEnvelope&inSR=102100&outFields=*' +
            '&outSR=102100';
        $.ajax({ //ajax call to retrieve the data continuously from a json source
            url: url,
            dataType: 'jsonp',
            success: function(response) {
                var features = esrijsonFormat.readFeatures(response, { //read the json geom features
                    featureProjection: projection //set the features to the specified 3857 projection
                });
                travel_restrictions.addFeatures(features); //add REST service features to vector source
            }
        });
    },
});

//definition of the style (for all the point features)
var point_style = new Style({
    image: new CircleStyle({
        radius: 5,
        fill: new Fill({color: 'rgb(255,255,0)'}),
        stroke: new Stroke({color: 'rgb(0,0,0)', width: 1}),
      }),
});

//travel restrictions layer
var layer_restrictions = new VectorLayer({
    title: 'Travel restrictions by country',
    source: travel_restrictions,
    style: point_style
});

//add map AT as a const
const map_restrictions = new Map({
    target: 'map_restrictions',
    layers: [
                bing_bmap,
                layer_restrictions
    ],
    view: new View({
        projection: 'EPSG:3857',
        center: [1056665.4790, 3874440.0897], //fitting to a worldwide scale
        zoom: 2
    }),
    controls: defaultControls().extend([
        new ScaleLine(), //adding scale line
        new ZoomToExtent({ //adding fit to extent button - fit to  worldwide scale
            extent: [
                -18863435.5883,
                -7827151.6964,
                21368124.1312,
                17376276.7660
            ],
            label: '' //to put an own image instead of the default OL label
        })
    ])
});

//retrieve country measures dinamic interaction on side div
var selected = null;

//Default div message for country measures
var info_div = document.getElementById("info_measures");
var default_text = document.createElement("H1"); //define default message as header style
var default_message = document.createTextNode("Select any country point feature to get its latest up to date Covid 19 measures and restrictions.");
default_text.appendChild(default_message);
info_div.appendChild(default_text);

map_restrictions.on('singleclick', function(e) {
    if (selected !== null) {
        selected = null;
    } else if (selected == null) {
        //delete the previous content (so it doesnt acumulate text)
        info_div.innerHTML = "";
        //return the default message again
        info_div.appendChild(default_text);
    }
    map_restrictions.forEachFeatureAtPixel(e.pixel, function(f) {
        selected = f;
        var country = f.get("adm0_name"); //retrieving country name
        var country_measures = f.get("info"); //retrieving up to date measures
        //delete the previous content (so it doesnt acumulate text)
        info_div.innerHTML = "";
        //add dynamically the latest measures per country plus a heading with the country name
        if (country_measures == null ){ //if there is no info (there are a few exceptions), indicate it
            info_div.innerHTML ="<h1>" + country + " " + "latest measures" + "</h1><p> &emsp; &emsp; Latest measures not available for this country</p>";
        }
        else{ //if there is info (as in most of the countries), print it accordingly
            info_div.innerHTML ="<h1>" + country + " " + "latest measures" + "</h1><p>" + country_measures + "</p>";
        }
    })
});


