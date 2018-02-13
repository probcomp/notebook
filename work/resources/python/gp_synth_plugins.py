import contextlib
from collections import OrderedDict
import os.path as pa
import sys

import numpy as np
import matplotlib.pyplot as plt

import venture.lite.types as vt
from venture.lite.sp_help import deterministic_typed
from venture.lite.gp import _cov_sp
from venture.lite.gp import GPCovarianceType

@contextlib.contextmanager
def extra_load_path(path):
    old_path = sys.path
    try:
        sys.path = [path] + old_path
        yield
    finally:
        sys.path = old_path

with extra_load_path(pa.dirname(pa.abspath(__file__))):
    from change_points import change_point

def load_csv(path):
    return np.loadtxt(path)

def concatenate(arraylike1, arraylike2):
    if not isinstance(arraylike1, list):
        arraylike1 = arraylike1.tolist()
    if not isinstance(arraylike2, list):
        arraylike2 = arraylike2.tolist()
    return arraylike1 + arraylike2

def get_figure_parameters(dict_of_plotting_parameters):
    if "alpha" in dict_of_plotting_parameters:
        alpha = dict_of_plotting_parameters["alpha"].getNumber()
    else:
        alpha = 1
    if "width" in dict_of_plotting_parameters:
        width = dict_of_plotting_parameters["width"].getNumber()
    else:
        width = None
    if "height" in dict_of_plotting_parameters:
        height  = dict_of_plotting_parameters["height"].getNumber()
    else:
        height = None
    if "color" in dict_of_plotting_parameters:
        color = dict_of_plotting_parameters["color"].getString()
    else:
        color = "green"
    if "marker" in dict_of_plotting_parameters:
        marker = dict_of_plotting_parameters["marker"].getString()
    else:
        marker = None
    if "linestyle" in dict_of_plotting_parameters:
        linestyle = dict_of_plotting_parameters["linestyle"].getString()
    else:
        linestyle = "-"
    if "markersize" in dict_of_plotting_parameters:
        markersize = dict_of_plotting_parameters["markersize"].getNumber()
    else:
        markersize = 200
    return width, height, linestyle, color, alpha, marker, markersize

def get_plot_labels(dict_of_plotting_parameters):
    if "label" in dict_of_plotting_parameters:
        label = dict_of_plotting_parameters["label"].getString()
    else:
        label = None
    if "title" in dict_of_plotting_parameters:
        title = dict_of_plotting_parameters["title"].getString()
    else:
        title = None
    if "xlabel" in dict_of_plotting_parameters:
        xlabel = dict_of_plotting_parameters["xlabel"].getString()
    else:
        xlabel = None
    if "ylabel" in dict_of_plotting_parameters:
        ylabel = dict_of_plotting_parameters["ylabel"].getString()
    else:
        ylabel = None
    if "xlim" in dict_of_plotting_parameters:
        xlim = [
            lim.getNumber()
            for lim in dict_of_plotting_parameters["xlim"].getArray()
        ]
    else:
        xlim = None
    if "ylim" in dict_of_plotting_parameters:
        ylim = [
            lim.getNumber()
            for lim in dict_of_plotting_parameters["ylim"].getArray()
        ]
    else:
        ylim = None
    return label, title, xlabel, ylabel, xlim, ylim

def create_figure(width, height):
    fig = plt.gcf()
    ax = plt.gca()
    if fig is None:
        fig, ax = plt.subplot()
    if (width is not None) and (height is not None):
        fig.set_size_inches(width, height)
    ax.grid(True)
    return fig, ax

def label_figure(ax, title, xlabel, ylabel, xlim, ylim):
    if title is not None:
        ax.set_title(title)
    if xlabel is not None:
        ax.set_xlabel(xlabel)
    if ylabel is not None:
        ax.set_ylabel(ylabel)
    if xlim is not None:
        ax.set_xlim(xlim )
    if ylim is not None:
        ax.set_ylim(ylim )

def scatter_plot(x, y, dict_of_plotting_parameters={}):
    width, height, linestyle, color, alpha, marker, markersize =\
        get_figure_parameters(
            dict_of_plotting_parameters
        )
    label, title, xlabel, ylabel, xlim, ylim, = get_plot_labels(
        dict_of_plotting_parameters
    )
    fig, ax = create_figure(width, height)
    if marker is None:
        marker = 'x'
    ax.scatter(x, y, zorder=2, alpha=alpha, marker=marker,
        s=markersize, linewidths=2, color = color, label=label)
    label_figure(ax, title, xlabel, ylabel, xlim, ylim)

def line_plot(x, y, dict_of_plotting_parameters={}):
    width, height, linestyle, color, alpha, marker, markersize =\
        get_figure_parameters(
            dict_of_plotting_parameters
        )
    label, title, xlabel, ylabel, xlim, ylim, = get_plot_labels(
        dict_of_plotting_parameters
    )
    fig, ax = create_figure(width, height)
    if marker is None:
        ax.plot(
            x,
            y,
            linestyle=linestyle,
            color=color,
            alpha=alpha,
            label=label
        )
    else:
        ax.plot(
            x,
            y,
            linestyle=linestyle,
            marker=marker,
            color=color,
            alpha=alpha,
            label=label
        )
    label_figure(ax, title, xlabel, ylabel, xlim, ylim)

def legend(location=None):
    ax = plt.gca()
    handles, labels = ax.get_legend_handles_labels()
    by_label = OrderedDict(zip(labels, handles))
    legend_object = ax.legend(
        by_label.values(),
        by_label.keys(),
        frameon = 1,
        loc = location
    )
    for line in legend_object.get_lines():
        line.set_alpha(1)
    legend_object.get_frame().set_facecolor('white')

def square_heatmap(posterior_landscape, limits, dict_of_plotting_parameters={}):
    width, height, linestyle, color, alpha, marker, markersize =\
        get_figure_parameters(
            dict_of_plotting_parameters
        )
    label, title, xlabel, ylabel, xlim, ylim, = get_plot_labels(
        dict_of_plotting_parameters
    )

    number_probe_points = int(np.sqrt(len(posterior_landscape)))
    x = np.linspace(limits[0], limits[1], number_probe_points)
    y = x
    Z = np.array(posterior_landscape).reshape(
        number_probe_points,
        number_probe_points
    )
    cmap = "magma"
    fig, ax = create_figure(width, height)
    cax = ax.imshow(
        Z,
        interpolation='bilinear',
        origin='lower',
        aspect='auto',
        cmap=cmap,
        extent=(limits[0], limits[1], limits[0], limits[1]),
    )
    ax.set_xlim(limits)
    ax.set_ylim(limits)
    label_figure(ax, title, xlabel, ylabel, xlim, ylim)
    bar = fig.colorbar(cax)
    bar.ax.set_ylabel('Log joint')
    bar.ax.set_yticklabels([])

def __venture_start__(ripl):
    ripl.execute_program('''
        define set_value_at_scope_block = (scope, block, value) -> {
            set_value_at2(scope, block, value)
        };
    ''')
    ripl.bind_foreign_inference_sp(
        'sort',
        deterministic_typed(
            np.sort,
            [
                vt.ArrayUnboxedType(vt.NumberType()),
            ],
            vt.ArrayUnboxedType(vt.NumberType()),
            min_req_args=1
        )
    )
    ripl.bind_foreign_inference_sp(
        'get_mean',
        deterministic_typed(
            np.mean,
            [
                vt.ArrayUnboxedType(vt.NumberType()),
            ],
            vt.NumberType(),
            min_req_args=1
        )
    )
    ripl.bind_foreign_inference_sp(
        'get_predictive_mean',
        deterministic_typed(
            lambda x: np.mean(x, axis=0),
            [
                vt.ArrayUnboxedType(vt.ArrayUnboxedType(vt.NumberType())),
            ],
            vt.ArrayUnboxedType(vt.NumberType()),
            min_req_args=1
        )
    )
    ripl.bind_foreign_inference_sp(
        'load_csv',
        deterministic_typed(
            load_csv,
            [vt.StringType()],
            vt.ArrayUnboxedType(vt.NumberType()),
            min_req_args=1
        )
    )
    ripl.bind_foreign_inference_sp(
        'concatenate',
        deterministic_typed(
            concatenate,
            [
                vt.ArrayUnboxedType(vt.NumberType()),
                vt.ArrayUnboxedType(vt.NumberType()),
            ],
            vt.ArrayUnboxedType(vt.NumberType()),
            min_req_args=2
        )
    )
    ripl.bind_foreign_inference_sp(
        'scatter_plot',
        deterministic_typed(
            scatter_plot,
            [
                vt.ArrayUnboxedType(vt.NumberType()),
                vt.ArrayUnboxedType(vt.NumberType()),
                vt.HomogeneousDictType(vt.StringType(), vt.AnyType())
            ],
            vt.NilType(),
            min_req_args=2
        )
    )
    ripl.bind_foreign_inference_sp(
        'line_plot',
        deterministic_typed(
            line_plot,
            [
                vt.ArrayUnboxedType(vt.NumberType()),
                vt.ArrayUnboxedType(vt.NumberType()),
                vt.HomogeneousDictType(vt.StringType(), vt.AnyType())
                ],
            vt.NilType(),
            min_req_args=2
        )
    )
    ripl.bind_foreign_inference_sp(
        'legend',
        deterministic_typed(
            legend,
            [vt.StringType()],
            vt.NilType(),
            min_req_args=0
        )
    )
    ripl.bind_foreign_inference_sp(
        'square_heatmap',
        deterministic_typed(
            square_heatmap,
            [
                vt.ArrayUnboxedType(vt.NumberType()),
                vt.ArrayUnboxedType(vt.NumberType()),
                vt.HomogeneousDictType(vt.StringType(), vt.AnyType())
            ],
            vt.NilType(),
            min_req_args=2
        )
    )
    ripl.bind_foreign_sp(
        'gp_cov_cp',
        _cov_sp(
            change_point,
            [
                vt.NumberType(),
                vt.NumberType(),
                GPCovarianceType('K'),
                GPCovarianceType('H')
            ]
        )
    )
