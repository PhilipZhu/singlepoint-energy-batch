# Single-point Energy Calculation Wrapper

Smart wrapper scripts to run single-point energy calculations and many-body decompositions painlessly

`./singlepoint` is the main code that calculates single-point energies.

`./mbd.sh` calls `./singlepoint` to calculate single-point energies for subsystems, and then calculates many-body decompositions.

# Setup

Energy calculator software can be customized. Default calculator is Orca 6.0.0, using DLPNO-CCSD(T)/aug-cc-pVTZ.

### Option 1: To use the default software, you need to set up Orca 6.0.0:

1. Install OpenMPI 4.1.6 in `${HOME}/software/orca/openmpi-4.1.6/` (requried by Orca 6.0.0).

2. Install Orca 6.0.0 in `${HOME}/software/orca/orca_6_0_0_shared_openmpi416/`. Orca executable `orca` should be located under this directory.

In ./singlepoint source code, you can find the following sections linking to your installs.

```
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${HOME}/software/orca/openmpi-4.1.6/lib"
export PATH="$PATH:${HOME}/software/orca/openmpi-4.1.6/bin"
export CALC_EXE="${HOME}/software/orca/orca_6_0_0_shared_openmpi416/orca"
```

### Option 2: Alternatively, set up other energy calculator softwares.

You can use any custom softwares to calculate energies. You need to implement a `<software.ini>` file for new softwares. Custom `<software.ini>` for several other softwares, including Molpro, Q-Chem, Gaussian 09, are provided in `./template_software_ini/by_software/`.

# Basic Usage

To use `./singlepoint` with the default software (Orca 6.0.0):

`./singlepoint <structure.xyz> [<charge> [<multiplicity>]]`

XYZ file can contain multiple structures and/or distinct systems (i.e. different atom composition in each frame). Same charge and multiplicity will be used for all frames.

To run calculations in parallel, simply launch multiple `./singlepoint <structure.xyz>` jobs.

# General Usage

Run `./singlepoint -h` or `./mbd.sh -h` to display usage messages. See `./examples/` for examples of running `./singlepoint` and `./mbd.sh` with custom softwares.
