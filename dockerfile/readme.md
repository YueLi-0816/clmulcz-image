# CLMU-LCZ container environment

This folder builds a Linux container with the source code and compiler/library environment for the CLMU-LCZ model. It follows the `ctsm5.1.dev166-LCZ` source branch and uses that branch's `Externals.cfg` files to fetch its pinned code dependencies.

## What the build does

1. Starts from the Miniforge Linux image and installs Python 3.10, GNU Fortran/C/C++, OpenMPI, NetCDF, ESMF, CMake and CIME's Python tools. BLAS and LAPACK are pinned to OpenBLAS on both amd64 and ARM64 to avoid the ARM64 BLIS DGEMM crash.
2. Builds PnetCDF against that MPI and NetCDF stack.
3. Clones `YuanSun-UoM/esm-dev_code` at `ctsm5.1.dev166-LCZ`.
4. Runs `manage_externals/checkout_externals` to fetch the source repositories listed in the model's external configuration files.
5. Sets CIME's CLM source path to the model repository root (`$SRCROOT/`), as required because this branch stores CLM at the root.
6. Builds and runs a 1×1 CBLAS DGEMM check; the image build fails if `libblas.so` does not resolve to OpenBLAS or the matrix multiplication fails.

The Dockerfile selects native Linux compilers for both `amd64` and `arm64`. Both use GNU 12.4, NetCDF-C 4.9.2, NetCDF-Fortran 4.6.1, CMake 3.31.6 and PnetCDF 1.12.3. `amd64` uses OpenMPI 5.0.8, ESMF 8.6.1 and a shared PnetCDF library. `arm64` uses OpenMPI 4.1.6 and ESMF 8.4.2 because the available Linux ARM64 ESMF 8.4.2 package requires OpenMPI 4.x; CIME requires ESMF 8.4.1 or newer. ARM64 uses a static PnetCDF library because its shared library's Fortran/MPI dependencies prevent the CMake checks in this CIME branch from linking correctly. The Conda base image tag is `latest`, so rebuilding later may receive a newer Miniforge package manager; the scientific/compiler packages remain version constrained.

This is a Linux container image. It can run on Linux, macOS, and Windows hosts that have Docker Engine or Docker Desktop with Linux containers enabled. Windows containers are not supported by this recipe.

## Build

Run from the root of the `clmulcz-image` repository. Build each architecture separately to load both variants into a local Docker image store without overwriting one tag:

```bash
docker buildx build --platform linux/amd64 \
  -f dockerfile/dockerfile \
  --load -t clmulcz-image:ctsm5.1.dev166-lcz-amd64 .

docker buildx build --platform linux/arm64 \
  -f dockerfile/dockerfile \
  --load -t clmulcz-image:ctsm5.1.dev166-lcz-arm64 .
```

Building for a different architecture uses emulation and can be much slower; building natively is preferred.

To publish one tag containing both architectures to a container registry, authenticate to that registry and run:

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -f dockerfile/dockerfile \
  -t DOCKERHUB_USERNAME/clmulcz-image:ctsm5.1.dev166-lcz \
  --push .
```

Replace `DOCKERHUB_USERNAME` with the account that owns the public Docker Hub repository. Docker will select the matching architecture when users pull that tag. A multi-platform image is published to a registry; `--load` is for loading a single platform into the local image store.

## Start a container

```bash
mkdir -p "$PWD/cesm-work"
docker run --rm -it \
  -v "$PWD/cesm-work:/p/scratch/CESMDATAROOT" \
  clmulcz-image:ctsm5.1.dev166-lcz-arm64
```

Use the `-amd64` tag on an amd64 host, the `-arm64` tag on an ARM64 host, or `DOCKERHUB_USERNAME/clmulcz-image:ctsm5.1.dev166-lcz` after publishing. With a multi-platform registry tag, Docker selects the matching variant automatically.

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

The image build, CIME case creation, `case.setup` and full `case.build` were validated on Linux/amd64 in Docker Desktop. The ARM64 image was built and checked on Docker Desktop; CIME case creation, `case.setup`, and full `case.build` also succeeded with its ARM-native toolchain. Host support depends on Docker being configured to run Linux containers.
