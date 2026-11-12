# CLMU-LCZ container environment

This folder builds a Linux container with the source code and compiler/library environment for the CLMU-LCZ model. It follows the `ctsm5.1.dev166-LCZ` source branch and uses that branch's `Externals.cfg` files to fetch its pinned code dependencies.

## What the build does

1. Starts from the Miniforge Linux image and installs Python 3.10, GNU Fortran/C/C++, OpenMPI, NetCDF, ESMF, CMake and CIME's Python tools.
2. Builds PnetCDF against that MPI and NetCDF stack.
3. Clones `YuanSun-UoM/esm-dev_code` at `ctsm5.1.dev166-LCZ`.
4. Runs `manage_externals/checkout_externals` to fetch the source repositories listed in the model's external configuration files.
5. Sets CIME's CLM source path to the model repository root (`$SRCROOT/`), as required because this branch stores CLM at the root.

The versions are pinned in the Dockerfile to the GNU 12.4, OpenMPI 5.0.8, NetCDF-C 4.9.2, NetCDF-Fortran 4.6.1, ESMF 8.6.1, CMake 3.31.6 and PnetCDF 1.12.3 combination. The Conda base image tag is `latest`, so rebuilding later may receive a newer Miniforge package manager; the scientific/compiler packages remain version constrained.

## Build

Run from the root of the `clmulcz-image` repository:

```bash
docker build --platform linux/amd64 \
  -f dockerfile/dockerfile \
  -t clmulcz-image:ctsm5.1.dev166-lcz .
```

The recipe has been exercised in Docker Desktop's Linux/amd64 emulation. On Apple Silicon this emulation is slower than a native Linux/amd64 host. Native ARM64 builds have not been validated.

## Start a container

```bash
mkdir -p "$PWD/cesm-work"
docker run --rm -it --platform linux/amd64 \
  -v "$PWD/cesm-work:/p/scratch/CESMDATAROOT" \
  clmulcz-image:ctsm5.1.dev166-lcz
```

The model source is at `/p/project/ctsm5.1.dev166-LCZ`; CIME's scripts are at `/p/project/ctsm5.1.dev166-LCZ/cime/scripts`. The mounted `cesm-work` directory is where cases, outputs and other user files can persist after the container exits.

## Create a CIME case

Inside the container, create a case using a compset and grid supported by this model branch. For example, the following case-creation command was accepted in the validation container:

```bash
cd /p/project/ctsm5.1.dev166-LCZ
./cime/scripts/create_newcase \
  --case /p/scratch/CESMDATAROOT/cases/lcz-example \
  --compset I1850Clm50SpCru \
  --res f09_g17 \
  --machine clmu-app \
  --compiler gnu \
  --mpilib openmpi \
  --run-unsupported
```

Then initialize the case:

```bash
cd /p/scratch/CESMDATAROOT/cases/lcz-example
./case.setup
```

The image build, CIME case creation, `case.setup` and full `case.build` were validated with this source branch and toolchain in Docker Desktop Linux/amd64 emulation.
