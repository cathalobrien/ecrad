import xarray as xr
import click
import numpy as np

@click.command()
@click.argument("filename", type=str)
@click.argument("n", type=int)
def convert(filename, n):
    data = xr.open_dataset(filename)
    out = xr.Dataset()

    new_dims = {key: val for key, val in data.dims.items() if key != "column"}

    out = out.expand_dims(new_dims)
    out = out.expand_dims({"column": n})

    lon_col_name = "longitude"
    if (data.get(lon_col_name) == None):
        lon_col_name = "lon"
    lat_col_name = "latitude"
    if (data.get(lat_col_name) == None):
        lat_col_name = "lat"

    lon = data[lon_col_name][:]
    lat = data[lat_col_name][:]

    out[lon_col_name] = (("column",), np.linspace(np.min(lon), np.max(lon), n))
    out[lat_col_name] = (("column",), np.linspace(np.min(lat), np.max(lat), n))

    n_repeat = n // data.dims["column"] + 1

    for vn in data.data_vars:
        var = data[vn]
        if vn not in [lon_col_name, lat_col_name] and "column" in var.dims:
            colax = var.dims.index("column")
            out[vn] = (var.dims, np.repeat(var[:], n_repeat, axis=colax)[:n])

    out.to_netcdf(filename.replace(".nc", "_{}.nc".format(n)))

    return


if __name__ == "__main__":
    convert()
