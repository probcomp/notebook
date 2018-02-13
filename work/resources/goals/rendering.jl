HTML("""


<svg>
<defs>
<svg id="drone" viewBox="0 0 100 100">
    <image href="resources/goals/drone.png" x="0" y="0" height="100px" width="100px"/>
</svg>
<svg id="tree" viewBox="0 0 100 100">
    <image href="resources/goals/tree.png" x="0" y="0" height="100px" width="100px"/>
</svg>
</defs>
</svg>

<style>
    .start {
        fill: blue;
    }
    .destination {
        fill: red;
    }
    .waypoint {
        fill: none;
        stroke: magenta;
        stroke-width: 1;
        //stroke-dasharray: 1.5, 1.5;
    } 
    .path {
        fill: orange;
        fill-opacity: 0.3;
    }
    .path_segments {
        stroke: black;
        stroke-opacity: 0.2;
    }
    .wall {
        fill: saddlebrown;
    }
    .score {
        text-anchor: middle;
        font-size: 10px;
        visibility: hidden; // make hidden by default
    }
    .interventions {
        stroke: black;
        stroke-width: 1;
    }
    .constraints {
        stroke: black;
        stroke-width: 1;
        stroke-dasharray: 1, 1;
    }
    .legend {
        font-size: 8px;
        alignment-baseline: middle;
    }
</style>

<script>
// Gen.jl provides a Jupyter notebook extension that allows trace to be
// passed from Julia to Javscript rendering functions.
var Gen = require("nbextensions/gen_notebook_extension/main");

// We use D3 for the trace rendering in this example notebook. However,
// in principle any Javascript library for graphics or visualization
// can be used to render Gen.jl traces.
var d3 = require("nbextensions/d3/d3.min");

// Add an SVG element representing the scene.
function add_svg_if_not_exists(parent, trace) {
    var svg = parent.selectAll("svg").data([""]);
    return svg.enter().append("svg")
        .attr("viewBox", "0 0 100 100")
        .attr("position", "absolute")
        .style("height", "100%")
        .merge(svg);
}

function add_bounding_box(svg) {
    svg.selectAll("rect").data([""]).enter().append("rect")
        .attr("width", "100%")
        .attr("height", "100%")
        .attr("stroke", "black")
        .attr("fill", "white")
        .attr("fill-opacity", 0.0);
}

// Add the static elements of the scene (only once)
function add_scene(svg, trace) {
    var scene = Gen.find_choice(trace, "scene");
    if (!scene) {
        return;
    }
    
    var trace_trees = scene.value.obstacles.filter(function(element) { return element.name == "Tree";});
    var trees = svg.selectAll(".tree").data(trace_trees);
    trees.exit().remove();
    trees.enter().append("use").classed("tree", true).classed("trace", true)
        .attr("xlink:href","#tree")
       .merge(trees)
         .attr("x", function(d) { return d.center.x - d.size/2.0; })
         .attr("y", function(d) { return d.center.y - d.size/2.0; })
         .attr("width", function(d) { return d.size; })
         .attr("height", function(d) { return d.size; });
    
    var trace_walls = scene.value.obstacles.filter(function(element) { return element.name == "Wall";});
    var walls = svg.selectAll(".wall").data(trace_walls);
    walls.exit().remove();
    walls.enter().append("rect").classed("wall", true).classed("trace", true)
      .merge(walls)
        .attr("x", function(d) { return d.start.x; })
        .attr("y", function(d) { return d.start.y; })
        .attr("width", function(d) { return d.orientation == 1 ? d.length : d.thickness; })
        .attr("height", function(d) { return d.orientation == 2 ? d.length : d.thickness; });
}

// Add the starting location of the agent
function add_start(svg, trace, conf) {
    var radius = 2;
    if (!conf) {
        conf = "overwrite";
    }
    var trace_start = Gen.find_choice(trace, "start");
    var update;
    if (conf == "overwrite") {
        update = svg.selectAll(".start").data(trace_start ? [trace_start] : []);
        update.exit().remove();
        update = update.enter().append("circle").classed("start", true).attr("r", radius).merge(update);
    } else if (conf == "overlay") {                                                                                                       
        update = svg.append("g").selectAll(".start").data(trace_start ? [trace_start] : []);
        update = update.enter().append("circle").classed("start", true).attr("r", radius);
    }
    update.attr("cx", function(d) { return d.value.x; })
          .attr("cy", function(d) { return d.value.y; });
}

// Add waypoint of a path, if it exists
function add_waypoint(svg, trace, conf) {
    var radius = 2;
    if (!conf) {
        conf = "overwrite";
    }
    var trace_waypoint = Gen.find_choice(trace, "waypoint");
    var update;
    if (conf == "overwrite") {
        update = svg.selectAll(".waypoint").data(trace_waypoint ? [trace_waypoint] : []);
        update.exit().remove();
        update = update.enter().append("circle").classed("waypoint", true).attr("r", radius).merge(update);
    } else if (conf == "overlay") {                                                                                                       
        update = svg.append("g").selectAll(".waypoint").data(trace_waypoint ? [trace_waypoint] : []);
        update = update.enter().append("circle").classed("waypoint", true).attr("r", radius);
    }
    update.attr("cx", function(d) { return d.value.x; })
          .attr("cy", function(d) { return d.value.y; });
}                                                                                                                            

// Add the destination location of the agent
function add_destination(svg, trace, conf) {
    var radius = 2;
    if (!conf) {
        conf = "overwrite";
    }
    var trace_dest = Gen.find_choice(trace, "destination");
    var update;
    if (conf == "overwrite") {
        update = svg.selectAll(".destination").data(trace_dest ? [trace_dest] : []);
        update.exit().remove();
        update = update.enter().append("circle").classed("destination", true).attr("r", radius).merge(update);
    } else if (conf == "overlay") {                                                                                                       
        update = svg.append("g").selectAll(".destination").data(trace_dest ? [trace_dest] : []);
        update = update.enter().append("circle").classed("destination", true).attr("r", radius);
    }
    update.attr("cx", function(d) { return d.value.x; })
          .attr("cy", function(d) { return d.value.y; });
}

function add_measured_locations(svg, trace, conf) {
    if (!conf) {
        conf = "overwrite";
    }
    var times_trace = Gen.find_choice(trace, "times");
    if (!times_trace) {
        return;
    }
    var times = times_trace.value;
    var path_point_data = [];
    for (var i=1; i<=times.length; i++) {
        var x = Gen.find_choice(trace, "x" + i);
        var y = Gen.find_choice(trace, "y" + i);
        if (x && y) {
            path_point_data.push({x: x, y: y, where: x.where == y.where ? x.where : "mixed" });
        }
    }
    
    var update;
    var drone_size = 8
    if (conf == "overwrite") {
        update = svg.selectAll(".path").data(path_point_data);
        update.exit().remove();
        update = update.enter().append("use").classed("path", true).classed("trace", true).attr("xlink:href","#drone").attr("width", drone_size).attr("height", drone_size).merge(update);
    } else if (conf == "overlay") {
        update = svg.append("g").selectAll(".path").data(path_point_data);
        update = update.enter().append("use").classed("path", true).classed("trace", true).attr("xlink:href","#drone").attr("width", drone_size).attr("height", drone_size);
    }
    update
        .attr("x", function(d) { return d.x.value - drone_size/2; })
        .attr("y", function(d) { return d.y.value - drone_size/2; });
}

function add_path(svg, trace, conf) {
    if (!conf) {
        conf = "overwrite";
    }
    var path_segment_data = [];
    var planned_path = Gen.find_choice(trace, "final-path");
    if (planned_path) {
        if (planned_path.value) {
            // planning succeeded, show the path; otherwise do not
            var points = planned_path.value.points;
            for (var i=0; i<points.length-1; i++) {
                var x_cur = points[i].x;
                var y_cur = points[i].y;
                var x_next = points[i+1].x;
                var y_next = points[i+1].y;
                if (x_cur && y_cur && x_next && y_next) {
                    path_segment_data.push({prev: {x: x_cur, y: y_cur},
                                            next: {x: x_next, y: y_next}});
                }
            }
        }
    }

    var update;
    if (conf == "overwrite") {
        update = svg.selectAll(".path_segments").data(path_segment_data);
        update.exit().remove();
        update = update.enter().append("line").classed("path_segments", true).classed("trace", true).merge(update);
    } else if (conf == "overlay") {
        update = svg.append("g").selectAll(".path_segments").data(path_segment_data);
        update = update.enter().append("line").classed("path_segments", true).classed("trace", true);
    }
    update
        .attr("x1", function(d) { return d.prev.x; })
        .attr("y1", function(d) { return d.prev.y; })
        .attr("x2", function(d) { return d.next.x; })
        .attr("y2", function(d) { return d.next.y; });  
}

// Set a different style to elements if they were intervened in the trace
// with intervene! or constrained with constrain!
function apply_styles(svg) {
    svg.selectAll(".trace")
        .classed("recorded", function(d) { return d.where == Gen.recorded; })
        .classed("interventions", function(d) { return d.where == Gen.interventions; })
        .classed("constraints", function(d) { return d.where == Gen.constraints; });
}

// Add the score of the trace to the bottom of the scene
function add_score(svg, value) {
    var score = svg.selectAll(".score").data([""]);
    score.exit().remove();
    var text = value.toFixed(2);
    score.enter().append("text").classed("score", true)
        .merge(score)
        .attr("x", 50).attr("y", 95)
        .text(text);
}

// The main Javascript trace rendering function, registered with Gen
// Renders 'trace' onto the the DOM element #'id'
Gen.register_jupyter_renderer("agent_model_renderer", function(id, trace, conf, args) {
    console.log(args);
    var root = d3.select("#" + id);
    var svg = add_svg_if_not_exists(root, trace);
    add_bounding_box(svg);
    add_path(svg, trace, conf.path);
    add_measured_locations(svg, trace, conf.measured_locations);
    add_start(svg, trace, conf.start);
    add_waypoint(svg, trace, conf.waypoint);
    add_destination(svg, trace, conf.destination);
    add_scene(svg, trace); // TODO conf.scene
    if (args.score) {
        add_score(svg, args.score);
    }
    apply_styles(svg);
});

// An secondary trace rendering that just draws a legend onto the DOM element #'id'
Gen.register_jupyter_renderer("agent_model_legend_renderer", function(id, trace, conf) {
    var root = d3.select("#" + id);
    var radius = 2;
    root.append("circle").classed("start", true).attr("r", radius).attr("cx", 10).attr("cy", 10);
    root.append("text").text("Starting location").classed("legend", true).attr("x", 20).attr("y", 10);
    root.append("circle").classed("destination", true).attr("r", radius).attr("cx", 10).attr("cy", 20);
    root.append("text").text("Destination").classed("legend", true).attr("x", 20).attr("y", 20);
    root.append("circle").classed("path", true).attr("r", radius).attr("cx", 10).attr("cy", 30);
    root.append("use").attr("xlink:href","#drone").attr("width", 10).attr("height", 10).classed("legend", true).attr("x", 10 - 5).attr("y", 30 - 5);
    root.append("text").text("Measured location").classed("legend", true).attr("x", 20).attr("y", 30);
    root.append("use").classed("tree", true).attr("x", 5).attr("y", 35).attr("xlink:href","#tree").attr("width", 10).attr("height", 10);
    root.append("text").text("Tree").classed("legend", true).attr("x", 20).attr("y", 40);
    root.append("rect").classed("wall", true).attr("x", 5).attr("y", 50).attr("width", 10).attr("height", 2);
    root.append("text").text("Wall").classed("legend", true).attr("x", 20).attr("y", 50);
});
</script>
""")
