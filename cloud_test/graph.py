import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.lines as mlines #for labels
import os
import argparse

def where(x, xs):
    return int(np.where(xs == x)[0])

def plot(subplot, xs, ys, profile, core_count):
    if (np.any(ys)): #check for any none NaN values
        subplot.plot(xs, ys, marker = '.',
            color=line_colour, linestyle=line_style, label = f"{profile}, {core_count} cores")

#add commandline arg to decide whether to use speedup or raw runtime
parser = argparse.ArgumentParser()
parser.add_argument("-l", "--log",
    help="Use a log axis for the x and/or y axis for the graph", action="store_true")
parser.add_argument("filename",
    help="The input file to be used to generate the graph")
parser.add_argument("-w", "--wallclock_time",
    help="Plot wallclock time on the y axis instead of cols/s", action="store_true")

new_line_style=False

args = parser.parse_args()


df = pd.read_csv(args.filename, sep=",")

#experiment setup i.e. ectrans version and compiler flags
#shouldn't be hardcoded but sure look
version = "1.4.2" #added manually from ecrad/CHANGELOG
#flags added manually from the relevant make profiles in ecrad/
flags = [("gfortran","-O3"), ("intel_heap", "-O3 -heap-arrays"), ("intel_opt", "-O3 -heap-arrays -g -march=core-avx2 -traceback -fp-model precise -fp-speculation=safe -fast-transcendentals")]

npromas = np.unique(df["nproma"])
profiles = np.unique(df["profile"])
input_sizes = np.unique(df["input_size"])
cores = np.unique(df["thread_count"])
programs = np.unique(df["program"])
df = df.groupby(["thread_count","input_size","nproma", "program","profile"]).median()

line_styles = ["-", "--", ":"]

fig, axis = plt.subplots(1, 2, sharex=True, sharey=True)
fig.suptitle(f"ecrad version {version}")
flag_text = f""
for (comp, flag) in flags:
    flag_text += f"  {comp} flags: {flag}\n"
fig.text(0, 0, flag_text, fontsize="small", fontstyle="italic")
for input_size in input_sizes:
    #for now do nothing, eventually put different programs on different subgraphs
    #subplot = axis[where(program, programs)]
    for profile in profiles:
        line_colour = f"C{where(profile, profiles)}"
        for core_count in cores:
            line_style = line_styles[where(core_count,cores)]
            #line_style = (0, (5, 5*where(core_count, cores)+1))
            subset = df.xs(profile, level="profile").xs(core_count, level="thread_count")
            _, nproma, _ = zip(*subset.axes[0]) #once again asking for nicer syntax here
            nproma = np.unique(list(nproma))

            ys = input_size / subset[f"ecrad_ifs_runtime"]
            if (args.wallclock_time):
                ys = subset[f"ecrad_ifs_runtime"] #/ core_count
            xs = nproma
            plot(axis[1], xs, ys, profile, core_count)
            ys = input_size / subset[f"ecrad_runtime"]
            if (args.wallclock_time):
                ys = subset[f"ecrad_runtime"]
            plot(axis[0], xs, ys, profile, core_count)

#add labels
if (new_line_style):
    labels = []
    for profile in profiles:
        profile_colour= mlines.Line2D([], [], color=f"C{where(profile, profiles)}",label=f"{profile}")
        labels.append(profile_colour)
    for core_count in cores:
        ls = mlines.Line2D([], [], linestyle=line_styles[where(core_count,cores)],label=f"{core_count} cores")
        labels.append(ls)

subplot_titles = ["ecrad", "ecrad_ifs"]
for ax in axis:
    ax.set_title(subplot_titles[where(ax, axis)])
    ax.set_ylabel("columns per second")
    if (args.wallclock_time):
        ax.set_ylabel("Wallclock time (s)")
    ax.grid()
    #ax.legend()
    #if (args.speedup):
    #    ax.set_ylabel("Speedup")
    #    ax.set_xlabel("NPROMA value")
    if (args.log):
        ax.set_xlabel("NPROMA value [log scale]")
        ax.set_xscale("log")
        #ax.xticks(xs, xs)
        #if (args.speedup):
        #    ax.set_ylabel("Speedup [log scale]")
        #    ax.set_yscale("log")
if (new_line_style):
    axis[0].legend(handles=labels)
else:
    axis[0].legend()
plt.show()
