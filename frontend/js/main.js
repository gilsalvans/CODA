//import libraries & modules
import 'ol/ol.css';
import 'ol-popup/src/ol-popup.css';
import { Map, View } from 'ol';
import { ScaleLine, ZoomToExtent, defaults as defaultControls } from 'ol/control';
import GeoJSON from 'ol/format/GeoJSON';
import VectorSource from 'ol/source/Vector';
import { Fill, Stroke, Style } from 'ol/style';
import { Tile as TileLayer, Vector as VectorLayer } from 'ol/layer';
import { bbox as bboxStrategy } from 'ol/loadingstrategy';
import BingMaps from 'ol/source/BingMaps';
import Popup from 'ol-popup';
import { Grid, PluginPosition } from "gridjs";
import "gridjs/dist/theme/mermaid.css";
import Plotly from 'plotly.js-dist';

//add dark Bing basemap 
var bing_API_key = 'ApTJzdkyN1DdFKkRAE6QIDtzihNaf6IWJsT-nQ_2eMoO4PN__0Tzhl2-WgJtXFSp';

//To fix the performance bug, we must add three different bing base maps in each
//dashboard. This way, is how everything works smoothly.
var bing_layers = [];
for (var i = 0; i < 4; i++){
    bing_layers.push(
        new TileLayer({
        title: 'Bing Dark Basemap',
        type: 'base',
        visible: true,
        source: new BingMaps({
            key: bing_API_key,
            imagerySet: 'CanvasDark',
            maxZoom: 19
        })
    })
    );
}

//add AT Covid data (WFS)
var austria_source = new VectorSource({
    format: new GeoJSON(),
    url: function(extent) {
        return (
            'http://human.zgis.at/geoserver/covid_dashboard/wfs?service=WFS&' +
            'version=1.1.0&request=GetFeature&typeName=covid_dashboard:austria_cases_today' +
            '&srsname=EPSG:3857&outputFormat=application/json&' +
            'bbox=' + extent.join(',')
        );
    },
    strategy: bboxStrategy,
});

//Add Covid data for Germany
var germany_source = new VectorSource({
    format: new GeoJSON(),
    url: function(extent) {
        return (
            'http://human.zgis.at/geoserver/covid_dashboard/wfs?service=WFS&' +
            'version=1.1.0&request=GetFeature&typeName=covid_dashboard:germany_cases_today&' +
            '&rsname=EPSG:3857&outputFormat=application/json&' +
            'bbox=' + extent.join(',')
        );
    },
    strategy: bboxStrategy,
});

//Add data for Spain 
var spain_source = new VectorSource({
    format: new GeoJSON(),
    url: function(extent) {
        return (
            'http://human.zgis.at/geoserver/covid_dashboard/wfs?service=WFS&' +
            'version=1.1.0&request=GetFeature&typeName=covid_dashboard:spain_cases_today&' +
            '&rsname=EPSG:3857&outputFormat=application/json&' +
            'bbox=' + extent.join(',')
        );
    },
    strategy: bboxStrategy,
});

//Styling for different infected values 
var stroke = new Stroke({
    color: 'rgb(255, 255, 255)',
    width: 0.5,
});
//storing different color gradients in an array for the subsequent styling function 
var colorGradient = [
        'rgb(0, 186, 43)',
        'rgb(240, 232, 10)',
        'rgb(255, 204, 65)',
        'rgb(255, 166, 65)',
        'rgb(255, 125, 65)',
        'rgb(255, 0, 0)',
        'rgb(212, 0, 0)',
        'rgb(179, 0, 0)',
        'rgb(255, 255, 255)' //outdated data -- for ES
    ]
    //coloring function (since its a wfs, styling must be done in the js)
    //however, this function and the legend are in accordance  
function getStyle(feature, resolution) {
    if (feature.get('SiebenTageInzidenzFaelle') == 0 || feature.get('cases7_per_100k') == 0) {
        return new Style({
            stroke: stroke,
            fill: new Fill({
                color: colorGradient[0]
            })
        });
    } else if ((feature.get('SiebenTageInzidenzFaelle') > 0 && feature.get('SiebenTageInzidenzFaelle') < 6) ||
        (feature.get('cases7_per_100k') > 0 && feature.get('cases7_per_100k') < 6)) {
        return new Style({
            stroke: stroke,
            fill: new Fill({
                color: colorGradient[1]
            })
        });
    } else if ((feature.get('SiebenTageInzidenzFaelle') >= 6 && feature.get('SiebenTageInzidenzFaelle') < 26) ||
        (feature.get('cases7_per_100k') >= 6 && feature.get('cases7_per_100k') < 26)) {
        return new Style({
            stroke: stroke,
            fill: new Fill({
                color: colorGradient[2]
            })
        });
    } else if ((feature.get('SiebenTageInzidenzFaelle') >= 26 && feature.get('SiebenTageInzidenzFaelle') < 51) ||
        (feature.get('cases7_per_100k') >= 26 && feature.get('cases7_per_100k') < 51)) {
        return new Style({
            stroke: stroke,
            fill: new Fill({
                color: colorGradient[3]
            })
        });
    } else if ((feature.get('SiebenTageInzidenzFaelle') >= 51 && feature.get('SiebenTageInzidenzFaelle') < 101) ||
        (feature.get('cases7_per_100k') >= 51 && feature.get('cases7_per_100k') < 101)) {
        return new Style({
            stroke: stroke,
            fill: new Fill({
                color: colorGradient[4]
            })
        });
    } else if ((feature.get('SiebenTageInzidenzFaelle') >= 101 && feature.get('SiebenTageInzidenzFaelle') < 251) ||
        (feature.get('cases7_per_100k') >= 101 && feature.get('cases7_per_100k') < 251)) {
        return new Style({
            stroke: stroke,
            fill: new Fill({
                color: colorGradient[5]
            })
        });
    } else if ((feature.get('SiebenTageInzidenzFaelle') >= 251 && feature.get('SiebenTageInzidenzFaelle') < 501) ||
        (feature.get('cases7_per_100k') >= 251 && feature.get('cases7_per_100k') < 501)) {
        return new Style({
            stroke: stroke,
            fill: new Fill({
                color: colorGradient[6]
            })
        });
    } else if ((feature.get('SiebenTageInzidenzFaelle') >= 501) || (feature.get('cases7_per_100k') >= 501)) {
        return new Style({
            stroke: stroke,
            fill: new Fill({
                color: colorGradient[7]
            })
        });
    }
}
//style function for Spain 
function getStyleSpain(feature, resolution) {
    if (feature.get('case') != "ok") { //if data is marked as outdated - white
        return new Style({
            stroke: stroke,
            fill: new Fill({
                color: colorGradient[8]
            })
        });
    } else if (feature.get('case') == "ok" && feature.get('current_cases') <= 1000) {
        return new Style({
            stroke: stroke,
            fill: new Fill({
                color: colorGradient[0]
            })
        });
    } else if (feature.get('case') == "ok" && feature.get('current_cases') >= 1001 && feature.get('current_cases') <= 10000) {
        return new Style({
            stroke: stroke,
            fill: new Fill({
                color: colorGradient[1]
            })
        });
    } else if (feature.get('case') == "ok" && feature.get('current_cases') >= 10001 && feature.get('current_cases') <= 30000) {
        return new Style({
            stroke: stroke,
            fill: new Fill({
                color: colorGradient[2]
            })
        });
    } else if (feature.get('case') == "ok" && feature.get('current_cases') >= 30001 && feature.get('current_cases') <= 50000) {
        return new Style({
            stroke: stroke,
            fill: new Fill({
                color: colorGradient[3]
            })
        });
    } else if (feature.get('case') == "ok" && feature.get('current_cases') >= 50001 && feature.get('current_cases') <= 100000) {
        return new Style({
            stroke: stroke,
            fill: new Fill({
                color: colorGradient[4]
            })
        });
    } else if (feature.get('case') == "ok" && feature.get('current_cases') >= 100001 && feature.get('current_cases') <= 250000) {
        return new Style({
            stroke: stroke,
            fill: new Fill({
                color: colorGradient[5]
            })
        });
    } else if (feature.get('case') == "ok" && feature.get('current_cases') >= 250001 && feature.get('current_cases') <= 350000) {
        return new Style({
            stroke: stroke,
            fill: new Fill({
                color: colorGradient[6]
            })
        });
    } else if (feature.get('case') == "ok" && feature.get('current_cases') >= 350001) {
        return new Style({
            stroke: stroke,
            fill: new Fill({
                color: colorGradient[7]
            })
        });
    }
}

//add retrieved AT data to a new vector layer with the specified style function
var austria_data = new VectorLayer({
    title: 'Data Austria',
    source: austria_source,
    style: function(feature, resolution) {
        return getStyle(feature, resolution);
    }
});
//add retrieved DE data to a new vector layer with the specified style function
var germany_data = new VectorLayer({
    title: 'Data Germany',
    source: germany_source,
    style: function(feature, resolution) {
        return getStyle(feature, resolution);
    }
});
//add retrieved ES data to a new vector layer with the specified style function 
var spain_data = new VectorLayer({
    title: 'Data Spain',
    source: spain_source,
    style: function(feature, resolution) {
        return getStyleSpain(feature, resolution); //return style function
    }
});

//add map AT as a const
const map_AT = new Map({
    target: 'map_AT',
    layers: [
                bing_layers[1],
                austria_data
    ],
    view: new View({
        projection: 'EPSG:3857',
        center: [1479209.3714, 6077660.9930], //fitting to an Austrian national scale
        zoom: 7
    }),
    controls: defaultControls().extend([
        new ScaleLine(), //adding scale line
        new ZoomToExtent({ //adding fit to extent button - fit to  AT national scale
            extent: [
                949042.18,
                5804322.12,
                2079087.19,
                6325317.03
            ],
            label: '' //to put an own image instead of the default OL label
        })
    ])
});

//add map for DE as const
const map_DE = new Map({
    target: 'map_DE',
    layers: [
                bing_layers[2],
                germany_data
    ],
    view: new View({
        projection: 'EPSG:3857',
        center: [1122707.05, 6655524.88], //fitting to an German national scale
        zoom: 6
    }),
    controls: defaultControls().extend([
        new ScaleLine(), //adding scale line
        new ZoomToExtent({ //adding fit to extent button - fit to  DE national scale
            extent: [
                562576.5282,
                5929067.4100,
                1731757.3128,
                7421118.2022
            ],
            label: '' //to put an own image instead of the default OL label
        })
    ])
});

//map for ES as const
const map_ES = new Map({
    target: 'map_ES',
    layers: [
                bing_layers[3],
                spain_data
    ],
    view: new View({
        projection: 'EPSG:3857',
        center: [-457399.21, 4904199.78], //fitting to a Spanish national scale
        zoom: 6
    }),
    controls: defaultControls().extend([
        new ScaleLine(), //adding scale line
        new ZoomToExtent({  //adding fit to extent button - fit to  ES national scale
            extent: [
                -1379535.4865,
                4133714.4897,
                528332.7395,
                5630657.2516
            ],
            label: '' //to put an own image instead of the default OL label
        })
    ])
});

//popups (mouse over) - with ol-ext module
//defining highlighted style for the hovering popups
var highlightStyle = new Style({
    fill: new Fill({
        color: 'rgba(241,241,241,0.7)',
    }),
    stroke: new Stroke({
        color: 'rgb(255, 255, 255)',
        width: 2,
    }),
});

//Popups hovering
//create objects and add them to each map as an overlay
var popup_over_AT = new Popup();
map_AT.addOverlay(popup_over_AT);
var popup_over_DE = new Popup();
map_DE.addOverlay(popup_over_DE);
var popup_over_ES = new Popup();
map_ES.addOverlay(popup_over_ES)

var selected = null; //setting selected var as null for subsequent select interaction

//add hovering popups interaction for AT
map_AT.on('pointermove', function(e) { //defining and enabling function by moving the mouse over the map
    if (selected !== null) {
        selected.setStyle(undefined);
        selected = null;
    }
    //this function refers to any feature on the map (in this case works well because we only have one layer)
    map_AT.forEachFeatureAtPixel(e.pixel, function(f) {
        selected = f;
        f.setStyle(highlightStyle); //setting the highlighted style while going over with mouse
        //storing popup content on a var and setting titles in bold
        var incidence = f.get("SiebenTageInzidenzFaelle")
            //parse incidence variable to keep only 2 decimals in the popup (otherwise it has too many decimals)
        var incidence_prased = parseFloat(incidence).toFixed(2);
        var content_districts = "<b>District: </b>" + f.get("name") + '<br>' + "<b>Last 7 days new cases: </b>" + f.get("AnzahlFaelle7Tage") +
            '<br>' + "<b>Last 7 days new Cases/100k inhabitants: </b>" + incidence_prased
        if (f.get("name").length > 0) { //popup for districts
            popup_over_AT.show(e.coordinate, '<div><p>' + content_districts + '</p></div>');
        }
        return true;
    });
});

//popup interaction DE
map_DE.on('pointermove', function(e) { //defining and enabling function by moving the mouse over the map
    if (selected !== null) {
        selected.setStyle(undefined);
        selected = null;
    }
    //this function refers to any feature on the map (in this case works well because we only have one layer)
    map_DE.forEachFeatureAtPixel(e.pixel, function(f) {
        selected = f;
        f.setStyle(highlightStyle); //setting the highlighted style while going over with mouse
        //storing popup content on a var and setting titles in bold
        var incidence = f.get("cases7_per_100k")
            //parse incidence variable to keep only 2 decimals in the popup (otherwise it has too many decimals)
        var incidence_prased = parseFloat(incidence).toFixed(2);
        var content = "<b>District: </b>" + f.get("Landkreis") + '<br>' + "<b>New Cases: </b>" + f.get("AnzahlFall") +
            '<br>' + "<b>Last 7 days new Cases/100k inhabitants: </b>" + incidence_prased
        popup_over_DE.show(e.coordinate, '<div><p>' + content + '</p></div>');
        return true;
    });
});

//popup interaction ES
map_ES.on('pointermove', function(e) { //defining and enabling function by moving the mouse over the map
    if (selected !== null) {
        selected.setStyle(undefined);
        selected = null;
    }
    //this function refers to any feature on the map (in this case works well because we only have one layer)
    map_ES.forEachFeatureAtPixel(e.pixel, function(f) {
        selected = f;
        f.setStyle(highlightStyle); //setting the highlighted style while going over with mouse
        var incidence = f.get("change_per_100k")
        var incidence_prased = parseFloat(incidence).toFixed(2);
        var content = "<b>Region: </b>" + f.get("nuts_name") + '<br>' + "<b>Current Cases: </b>" + f.get("current_cases") +
            '<br>' + "<b>New Cases change per 100k inhabitants: </b>" + incidence_prased
        popup_over_ES.show(e.coordinate, '<div><p>' + content + '</p></div>');
        return true;
    });
});

//side table (with Grid.js lib)
//an ajax must be used to get the data as json and filter it accordingly (integrated with jQuery)
//NOTE -> an ol. object can't be parsed as a JSON, that's why AJAX must be used
//but first, we use the ready function to load the features when everything is loaded
// Side Table for AT
var table_style = { //define the style of the table in css here
    container: {
        'background-color': 'rgba(52, 56, 52)',
    },
    table: {
        border: '2px solid #ccc'
    },
    th: {
        'background-color': 'rgba(52, 56, 52)',
        color: 'rgb(241, 228, 228)',
        'text-align': 'center',
        'font-family': 'Verdana, Arial, Helvetica, sans-serif'
    },
    td: {
        'text-align': 'center',
        'background-color': 'rgba(52, 56, 52)',
        color: 'rgb(241, 228, 228)',
        'font-size': '1.4vh',
        'font-family': 'Verdana, Arial, Helvetica, sans-serif'
    }
};

// Side Table for AT
$(document).ready(function() {
    $.ajax({
        type: "GET",
        url: "http://human.zgis.at/geoserver/covid_dashboard/wfs?service=WFS&version=1.1.0&request=GetFeature&typeName=covid_dashboard:austria_cases_today&srsname=EPSG:3857&outputFormat=application/json&PropertyName=(SiebenTageInzidenzFaelle,name)",
        success: successHandler
    });
    //function to handle and manage the obtained json data from our service
    function successHandler(data) {
        // create a key value array for the input table data
        var data_table = [];
        for (var i = 0; i < data.features.length; i++) {
            data_table.push({ name: data.features[i].properties.name, cases: parseFloat(data.features[i].properties.SiebenTageInzidenzFaelle).toFixed(2) });
        }
        //creating table object
        var grid = new Grid({
            columns: [{
                id: 'name',
                name: 'Districts'
            }, {
                id: 'cases',
                name: '7 days incidence'
            }],
            sort: true, //enabling sorting functionality for table attributes
            search: true, //adding search bar to the table
            height: '33vh',
            fixedHeader: true,
            data: data_table,
            style: table_style
        }).render(document.getElementById("table_AT")); //place the grid object to div table

    }
});

// Side Table for DE
$(document).ready(function() {
    $.ajax({
        type: "GET",
        url: "http://human.zgis.at/geoserver/covid_dashboard/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=covid_dashboard:germany_cases_today&outputFormat=application%2Fjson&PropertyName=(cases7_per_100k,Landkreis)",
        success: successHandler
    });
    //function to handle and manage the obtained json data from our service
    function successHandler(data) {
        // create a key value array for the input table data
        var data_table = [];
        for (var i = 0; i < data.features.length; i++) {
            data_table.push({ name: data.features[i].properties.Landkreis, cases: parseFloat(data.features[i].properties.cases7_per_100k).toFixed(2) });
        }
        //creating table object
        var grid = new Grid({
            columns: [{
                id: 'name',
                name: 'Districts'
            }, {
                id: 'cases',
                name: '7 days incidence'
            }],
            sort: true, //enabling sorting funcionality for table attributes
            search: true, //adding search bar to the table
            height: '33vh',
            fixedHeader: true,
            data: data_table,
            style: table_style
        }).render(document.getElementById("table_DE")); //place the grid object to div table

    }
});

//Add Side Table for ES
$(document).ready(function() {
    $.ajax({
        type: "GET",
        url: "http://human.zgis.at/geoserver/covid_dashboard/wfs?service=WFS&version=1.1.0&request=GetFeature&typeName=covid_dashboard:spain_cases_today&srsname=EPSG:3857&outputFormat=application/json&PropertyName=(nuts_name,current_cases)",
        success: successHandler
    });
    //function to handle and manage the obtained json data from our service
    function successHandler(data) {
        // create a key value array for the input table data
        var data_table = [];
        for (var i = 0; i < data.features.length; i++) {
            data_table.push({ name: data.features[i].properties.nuts_name, cases: data.features[i].properties.current_cases });
        }
        //creating table object
        var grid = new Grid({
            columns: [{
                id: 'name',
                name: 'Region'
            }, {
                id: 'cases',
                name: 'New Cases'
            }],
            sort: true, //enabling sorting funcionality for table attributes
            search: true, //adding search bar to the table
            height: '33vh',
            fixedHeader: true,
            data: data_table,
            style: table_style
        }).render(document.getElementById("table_ES")); //place the grid object to div table

    }
});


//time series (using plotly js library) 
//define default data arrays for time series
//the data must be extracted from the service as json and accordingly filtered
//therefore, AJAX is again implemented
//arrays defined outside the function to be integrated later on

//Time Series for AT
var x_time_default_AT = [];
var y_cases_default_AT = [];
var recovered_AT = [];
var deaths_AT = [];

//line colors for each chart
var line_recovered = 'rgb(0, 200, 0)';
var line_deaths = 'rgb(180, 0, 0)';

$(document).ready(function() {
    $.ajax({ //grabbing timeline data national scale
        type: "GET",
        url: "http://human.zgis.at/geoserver/covid_dashboard/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=covid_dashboard:austria_timeline&outputFormat=application/json",
        success: successHandler
    });

    function successHandler(data) {
        // loop to get all the needed features on arrays
        for (var i = 0; i < data.features.length; i++) {
            x_time_default_AT.push(data.features[i].properties.Time)
            y_cases_default_AT.push(data.features[i].properties.AnzahlFaelleSum)
            recovered_AT.push(data.features[i].properties.AnzahlGeheiltSum)
            deaths_AT.push(data.features[i].properties.AnzahlTotSum)
        }
    }
});

$(document).ready(function() {
    $.ajax({
        type: "GET", //timeline data district scale
        url: "http://human.zgis.at/geoserver/covid_dashboard/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=covid_dashboard:austria_gkz_timeline&outputFormat=application/json",
        success: successHandler
    });

    function successHandler(data) {
        var cases_line = {    //displaying only last 100 days on time series
            x: x_time_default_AT,
            y: y_cases_default_AT,
            name: 'Cases',
            type: 'scatter'
        };
        var recovered_line = {
            x: x_time_default_AT,
            y: recovered_AT,
            line: {
                color: line_recovered //line color
            },
            name: 'Recovered',
            type: 'scatter'
        };
        var deaths_line = {
            x: x_time_default_AT,
            y: deaths_AT,
            line: {
                color: line_deaths
            },
            name: 'Deaths',
            type: 'scatter'
        };
        var data_timeline = [cases_line, recovered_line, deaths_line];
        var layout = {
            title: 'Austria Time Series',
            yaxis: { //we skip x axis since there are already the dates and it would look too crowded
                title: 'Cases',
                showline: false
            },
            xaxis: {
                range: [(x_time_default_AT.length - 100), x_time_default_AT.length] //display last 100 days in the time series
            },
            font: {
                color: '#ffffff'
            },
            plot_bgcolor: "#343834",
            paper_bgcolor: "#343834"
        };
        var config = {responsive: true}
        Plotly.newPlot('chart_AT', data_timeline, layout, config); //default plot object

        //clicking interactive function to select the districts (for interactive time series)
        map_AT.on('singleclick', function(e) {
            if (selected !== null) {
                selected = null;

                //popup_over = null; --popup hover posible disabling
            } else if (selected == null) {
                //redraw the default plot in a national scale, if no features are selected 
                //to turn back to default by clicking somewhere else in the map
                Plotly.newPlot('chart_AT', data_timeline, layout, config);
            }
            map_AT.forEachFeatureAtPixel(e.pixel, function(f) {
                selected = f;
                var selected_gkz = f.get("gkz"); //get gkz attribute to match it with its time data
                var name_dist = f.get("name"); //get name district data to add it on the chart header dynamically
                var x_time_gkz = [];
                var y_cases_gkz = [];
                var recovered_gkz = [];
                var deaths_gkz = [];
                //getting arrays of input data for timeline chart (for each specific selected district)
                for (var i = 0; i < data.features.length; i++) {
                    if (data.features[i].properties.GKZ == selected_gkz) {
                        x_time_gkz.push(data.features[i].properties.Time)
                        y_cases_gkz.push(data.features[i].properties.AnzahlFaelleSum)
                        recovered_gkz.push(data.features[i].properties.AnzahlGeheiltSum)
                        deaths_gkz.push(data.features[i].properties.AnzahlTotSum)
                    }
                }
                //time series chart customized per district
                var cases_line_gkz = {
                    x: x_time_gkz,
                    y: y_cases_gkz,
                    name: 'Cases',
                    type: 'scatter'
                };
                var recovered_line_gkz = {
                    x: x_time_gkz,
                    y: recovered_gkz,
                    line: {
                        color: line_recovered
                    },
                    name: 'Recovered',
                    type: 'scatter'
                };
                var deaths_line = {
                    x: x_time_gkz,
                    y: deaths_gkz,
                    line: {
                        color: line_deaths
                    },
                    name: 'Deaths',
                    type: 'scatter'
                };
                var data_gkz = [cases_line_gkz, recovered_line_gkz, deaths_line];
                var layout = {
                    title: name_dist + ' Time Series',
                    yaxis: { //we skip x axis since there are already the dates and it would look too crowded
                        title: 'Cases',
                        autorange: true //adapt range 
                    },
                    xaxis: {
                        range: [(x_time_gkz.length - 100), x_time_gkz.length] //display last 100 days in the time series
                    },
                    font: {
                        color: '#ffffff'
                    },
                    plot_bgcolor: "#343834",
                    paper_bgcolor: "#343834"
                };
                var config = {responsive: true}
                Plotly.newPlot('chart_AT', data_gkz, layout, config); //plot object for selected districts
                return true;
            });
        });
    }
});

//Time Series for DE
var x_time_default_DE = [];
var y_cases_default_DE = [];
var recovered_DE = [];
var deaths_DE = [];
$(document).ready(function() {
    $.ajax({ //grabbing timeline data national scale
        type: "GET",
        url: "http://human.zgis.at/geoserver/covid_dashboard/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=covid_dashboard:germany_timeline&outputFormat=application/json",
        success: successHandler
    });

    function successHandler(data) {
        // loop to get all the needed features on arrays
        for (var i = 0; i < data.features.length; i++) {
            x_time_default_DE.push(data.features[i].properties.Meldedatum)
            y_cases_default_DE.push(data.features[i].properties.SummeFall)
            recovered_DE.push(data.features[i].properties.SummeGenesen)
            deaths_DE.push(data.features[i].properties.SummeTodesfall)
        }
    }
});

$(document).ready(function() {
    $.ajax({
        type: "GET",
        url: "http://human.zgis.at/geoserver/covid_dashboard/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=covid_dashboard:germany_counties_timeline&outputFormat=application/json",
        success: successHandler
    });

    function successHandler(data) {
        var cases_line = {
            x: x_time_default_DE,
            y: y_cases_default_DE,
            name: 'Cases',
            type: 'scatter'
        };
        var recovered_line = {
            x: x_time_default_DE,
            y: recovered_DE,
            line: {
                color: line_recovered //line color
            },
            name: 'Recovered',
            type: 'scatter'
        };
        var deaths_line = {
            x: x_time_default_DE,
            y: deaths_DE,
            line: {
                color: line_deaths
            },
            name: 'Deaths',
            type: 'scatter'
        };
        var data_timeline = [cases_line, recovered_line, deaths_line];
        var layout = {
            title: 'Germany Time Series',
            yaxis: { //we skip x axis since there are already the dates and it would look too crowded
                title: 'Cases',
                showline: false
            },
            xaxis: {
                range: [(x_time_default_DE.length - 100), x_time_default_DE.length] //display last 100 days in the time series
            },
            font: {
                color: '#ffffff'
            },
            plot_bgcolor: "#343834",
            paper_bgcolor: "#343834"
        };
        var config = {responsive: true}
        Plotly.newPlot('chart_DE', data_timeline, layout, config); //default plot object

        //clicking interactive function to select the districts (for interactive time series)
        map_DE.on('singleclick', function(e) {
            if (selected !== null) {
                selected = null;
            } else if (selected == null) {
                //redraw the default plot in a national scale, if no features are selected 
                //to turn back to default by clicking somewhere else in the map
                Plotly.newPlot('chart_DE', data_timeline, layout, config);
            }
            map_DE.forEachFeatureAtPixel(e.pixel, function(f) {
                selected = f;
                var selected_kreis = f.get("Landkreis");
                var x_time_kreis = [];
                var y_cases_kreis = [];
                var recovered_kreis = [];
                var deaths_kreis = [];
                //getting arrays of input data for timeline chart (for each specific selected district)
                for (var i = 0; i < data.features.length; i++) {
                    if (data.features[i].properties.area == selected_kreis) {
                        x_time_kreis.push(data.features[i].properties.Meldedatum)
                        y_cases_kreis.push(data.features[i].properties.SummeFall)
                        recovered_kreis.push(data.features[i].properties.SummeGenesen)
                        deaths_kreis.push(data.features[i].properties.SummeTodesfall)
                    }
                }
                //time series chart customized per district
                var cases_line_kreis = {
                    x: x_time_kreis,
                    y: y_cases_kreis,
                    name: 'Cases',
                    type: 'scatter'
                };
                var recovered_line_kreis = {
                    x: x_time_kreis,
                    y: recovered_kreis,
                    line: {
                        color: line_recovered
                    },
                    name: 'Recovered',
                    type: 'scatter'
                };
                var deaths_line = {
                    x: x_time_kreis,
                    y: deaths_kreis,
                    line: {
                        color: line_deaths
                    },
                    name: 'Deaths',
                    type: 'scatter'
                };
                var data_kreis = [cases_line_kreis, recovered_line_kreis, deaths_line];
                var layout = {
                    title: selected_kreis + ' Time Series',
                    yaxis: { //we skip x axis since there are already the dates and it would look too crowded
                        title: 'Cases',
                        autorange: true //adapt range 
                    },
                    xaxis: {
                        range: [(x_time_kreis.length - 100), x_time_kreis.length] //display last 100 days in the time series
                    },
                    font: {
                        color: '#ffffff'
                    },
                    plot_bgcolor: "#343834",
                    paper_bgcolor: "#343834"
                };
                var config = {responsive: true}
                Plotly.newPlot('chart_DE', data_kreis, layout, config); //plot object for selected districts
                return true;
            });
        });
    }
});

//Time Series for ES
var x_time_default_ES = [];
var y_cases_default_ES = [];
var recovered_ES = [];
$(document).ready(function() {
    $.ajax({ //grabbing timeline data national scale
        type: "GET",
        url: "http://human.zgis.at/geoserver/covid_dashboard/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=covid_dashboard:spain_timeline&outputFormat=application/json",
        success: successHandler
    });

    function successHandler(data) {
        // loop to get all the needed features on arrays
        for (var i = 0; i < data.features.length; i++) {
            x_time_default_ES.push(data.features[i].properties.date)
            y_cases_default_ES.push(data.features[i].properties.Confirmed)
            recovered_ES.push(data.features[i].properties.Recovered)
        }
    }
});

$(document).ready(function() {
    $.ajax({
        type: "GET",
        url: "http://human.zgis.at/geoserver/covid_dashboard/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=covid_dashboard:spain_comunidad_autonoma_timeline&outputFormat=application/json",
        success: successHandler
    });

    function successHandler(data) {
        var cases_line = {
            x: x_time_default_ES,
            y: y_cases_default_ES,
            name: 'Cases',
            type: 'scatter'
        };
        var recovered_line = {
            x: x_time_default_ES,
            y: recovered_ES,
            line: {
                color: line_recovered
            },
            name: 'Recovered',
            type: 'scatter'
        };
        var data_timeline = [cases_line, recovered_line];
        var layout = {
            title: 'Spain Time Series',
            yaxis: { //we skip x axis since there are already the dates and it would look too crowded
                title: 'Cases',
                showline: false
            },
            xaxis: {
                range: [(x_time_default_ES.length - 100), x_time_default_ES.length] //display last 100 days in the time series
            },
            font: {
                color: '#ffffff'
            },
            plot_bgcolor: "#343834",
            paper_bgcolor: "#343834"
        };
        var config = {responsive: true};
        Plotly.newPlot('chart_ES', data_timeline, layout, config); //default plot object

        //clicking interactive function to select the districts (for interactive time series)
        map_ES.on('singleclick', function(e) {
            if (selected !== null) {
                selected = null;
            } else if (selected == null) {
                //to turn back to default by clicking somewhere else in the map
                Plotly.newPlot('chart_ES', data_timeline, layout, config);
            }
            map_ES.forEachFeatureAtPixel(e.pixel, function(f) {
                selected = f;
                var selected_ccaa = f.get("AdminRegion1");
                var x_time_ccaa = [];
                var y_cases_ccaa = [];
                var recovered_ccaa = [];
                //getting arrays of input data for timeline chart (for each specific selected district)
                for (var i = 0; i < data.features.length; i++) {
                    if (data.features[i].properties.AdminRegion1 == selected_ccaa) { //BUG IS HEREEE!!!!!! -> TWO TABLES ARE DIFFERENT
                        x_time_ccaa.push(data.features[i].properties.date)
                        y_cases_ccaa.push(data.features[i].properties.Confirmed)
                        recovered_ccaa.push(data.features[i].properties.Recovered)
                    }
                }
                //time series chart customized per district
                var cases_line_ccaa = {
                    x: x_time_ccaa,
                    y: y_cases_ccaa,
                    name: 'Cases',
                    type: 'scatter'
                };
                var recovered_line_ccaa = {
                    x: x_time_ccaa,
                    y: recovered_ccaa,
                    line: {
                        color: line_recovered
                    },
                    name: 'Recovered',
                    type: 'scatter'
                };
                var data_ccaa = [cases_line_ccaa, recovered_line_ccaa];
                var layout = {
                    title: selected_ccaa + ' Time Series',
                    yaxis: { //we skip x axis since there are already the dates and it would look too crowded
                        title: 'Cases',
                        autorange: true //adapt range 
                    },
                    xaxis: {
                        range: [(x_time_ccaa.length - 100), x_time_ccaa.length]
                    },
                    font: {
                        color: '#ffffff'
                    },
                    plot_bgcolor: "#343834",
                    paper_bgcolor: "#343834"
                };
                var config = {responsive: true}
                Plotly.newPlot('chart_ES', data_ccaa, layout, config); //plot object for selected districts
                return true;
            });
        });
    }
});